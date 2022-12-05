Base.@kwdef mutable struct InlinePrinterState
    type::Bool = false
    variable::Bool = false
    symbol::Bool = false
    call::Bool = false
    quoted::Bool = false
    keyword::Bool = false
    block::Bool = true # show begin ... end by default
end

function with(f::Function, p::InlinePrinterState, name::Symbol, new::Bool=true)
    old = getfield(p, name)
    setfield!(p, name, new)
    f()
    setfield!(p, name, old)
end

struct InlinePrinter{IO_t <: IO}
    io::IO_t
    color::ColorScheme
    line::Bool
    state::InlinePrinterState
end

function InlinePrinter(io::IO;
        color::ColorScheme=Monokai256(),
        line::Bool=false,
    )
    InlinePrinter(io, color, line, InlinePrinterState())
end

function (p::InlinePrinter)(x, xs...; delim=", ")
    p(x)
    for x in xs
        printstyled(p.io, delim; color=p.color.keyword)
        p(x)
    end
end

function (p::InlinePrinter)(expr)
    c = p.color
    print(xs...) = Base.print(p.io, xs...)
    printstyled(xs...;kw...) = Base.printstyled(p.io, xs...; kw...)
    function join(xs, delim=", ")
        if !p.line
            xs = filter(!is_line_no, xs)
        end

        for (i, x) in enumerate(xs)
            p(x)
            i < length(xs) && keyword(delim)
        end
    end

    function print_braces(xs, open, close, delim=", ")
        print(open); join(xs, delim); print(close)
    end

    string(s) = printstyled('"', s, '"', color=c.string)
    keyword(s) = printstyled(s, color=c.keyword)

    function symbol(ex)
        color = if p.state.type
            c.type
        elseif p.state.variable
            c.variable
        elseif p.state.quoted
            c.quoted
        elseif p.state.call
            c.call
        else # normal symbol in expr
            :normal
        end

        is_gensym(ex) && printstyled("var\""; color=color)
        printstyled(ex, color=color)
        is_gensym(ex) && printstyled("\""; color=color)
    end

    variable(ex) = with(() -> p(ex), p.state, :variable)
    quoted(ex) = with(() -> p(ex), p.state, :quoted)
    type(ex) = with(() -> p(ex), p.state, :type)
    call(ex) = with(() -> p(ex), p.state, :call)
    noblock(ex) = with(() -> p(ex), p.state, :block, false)
    block(ex) = with(() -> p(ex), p.state, :block)

    function print_expr(ex)
        @switch ex begin
            @case ::Number
                printstyled(ex, color=c.number)
            @case ::String
                string(ex)
            @case ::Nothing
                printstyled("nothing", color=c.number)
            @case ::Symbol
                symbol(ex)
            @case ::LineNumberNode
                p.line || return # don't print line numbers
                printstyled("#= $(ex.file):$(ex.line) =#", color=c.line)
            @case Expr(:line, file, line)
                p.line || return # don't print line numbers
                printstyled("#= $(file):$(line) =#", color=c.line)
            @case ::QuoteNode
                if Base.isidentifier(ex.value)
                    keyword(":"); quoted(ex.value)
                else
                    keyword('$'); print("(")
                    printstyled("QuoteNode", color=c.call)
                    print("(");quoted(ex.value);print("))")
                end
            @case ::GlobalRef
                p(ex.mod); keyword("."); print(ex.name)
            @case Expr(:kw, k, v)
                p(k);print(" = ");p(v)
            @case Expr(:(=), k, Expr(:block, stmts...))
                if length(stmts) == 2 && count(!is_line_no, stmts) == 1
                    p(k); keyword(" = ")
                    p.line && is_line_no(stmts[1]) && p(stmts[1])
                    p(stmts[end])
                else
                    p(k); keyword(" = "); p(ex.args[2])
                end
            @case Expr(:(=), k, v)
                p(k); print(" = "); p(v)
            @case Expr(:..., name)
                p(name);keyword("...")
            @case Expr(:&, name)
                keyword("&");p(name)
            @case Expr(:(::), t)
                keyword("::");type(t)
            @case Expr(:(::), name, t)
                p(name);keyword("::");type(t)
            @case Expr(:$, name)
                keyword('$');print("("); p(name); print(")")

            # call expr
            @case Expr(:call, :(:), args...)
                join(args, ":")
            @case Expr(:call, f, Expr(:parameters, kwargs...), args...)
                call(f); print("("); join(args); keyword(";"); join(kwargs); print(")")
            @case Expr(:call, f::Symbol, arg) && if Base.isunaryoperator(f) end
                keyword(f); p(arg)
            @case Expr(:call, f::Symbol, args...) && if Base.isbinaryoperator(f) end
                join(args, " $f ")
            @case Expr(:call, f, args...)
                call(f); print_braces(args, "(", ")")
            @case Expr(:tuple, args...)
                print_braces(args, "(", ")")
            @case Expr(:curly, t, args...)
                with(p.state, :type) do
                    p(t); print_braces(args, "{", "}")
                end
            @case Expr(:vect, args...)
                print_braces(args, "[", "]")
            @case Expr(:hcat, args...)
                print_braces(args, "[", "]", " ")
            @case Expr(:typed_hcat, t, args...)
                type(t); print_braces(args, "[", "]", " ")
            @case Expr(:vcat, args...)
                print_braces(args, "[", "]", "; ")
            @case Expr(:ncat, n, args...)
                print_braces(args, "[", "]", ";"^n * " ")
            @case Expr(:ref, object, args...)
                p(object)
                print_braces(args, "[", "]")
            @case Expr(:->, args, Expr(:block, line, code))
                p(args); keyword(" -> "); 
                p.line && (print("("); p(line); print(" "))
                p(code)
                p.line && print(")")
            @case Expr(:->, args, body)
                p(args); keyword(" -> "); print("("); noblock(body); print(")")
            @case Expr(:quote, args...)
                keyword("quote ");
                with(p.state, :block, false) do
                    join(args, "; ")
                end
                keyword(" end")
            @case Expr(:string, args...)
                printstyled("\"", color=c.string)
                foreach(args) do x
                    x isa AbstractString && return printstyled(x; color=c.string)
                    keyword('$'); print("("); p(x); print(")")
                end
                printstyled("\"", color=c.string)
            @case Expr(:block, args...)
                p.state.block && keyword("begin ")
                with(p.state, :block) do # print inner begin .. end
                    join(args, "; ")
                end
                p.state.block && keyword(" end")
            @case Expr(:let, Expr(:block, args...), body)
                keyword("let "); join(args, ", "); keyword("; "); noblock(body);
                keyword("; end")
            @case Expr(:macrocall, f, line, args...)
                p.line && printstyled(line, color=c.comment)
                printstyled(f, color=c.macrocall)
                print_braces(args, "(", ")")
            @case Expr(:return, args...)
                keyword("return ");join(args)
            @case Expr(:module, bare, name, body)
                bare ? keyword("module ") : keyword("baremodule ")
                p(name);print("; "); noblock(body); keyword(" end")
            @case Expr(:using, args...)
                keyword("using ");join(args)
            @case Expr(:import, args...)
                keyword("import ");join(args)
            @case Expr(:., name)
                print(name)
            @case Expr(:., object, QuoteNode(name))
                p(object); keyword("."); print(name)
            @case Expr(:(:), head, args...)
                p(head); keyword(": "); join(args)
            @case Expr(:(<:), type, supertype)
                p(type); keyword(" <: "); p(supertype)
            @case Expr(:as, name, alias)
                p(name); keyword(" as "); p(alias)
            @case Expr(:export, args...)
                keyword("export ");join(args)
            @case Expr(:where, body, whereparams...)
                p(body); keyword(" where ")
                with(p.state, :type) do
                    join(whereparams, ", ")
                end

            @case Expr(:for, iteration, body)
                keyword("for "); noblock(iteration); keyword("; "); noblock(body);
                keyword("; end")
            @case Expr(:while, condition, body)
                keyword("while "); noblock(condition); keyword("; "); noblock(body);
                keyword("; end")

            @case Expr(:if, condition, body)
                keyword("if "); noblock(condition); keyword("; "); noblock(body);
                keyword("; end")

            @case Expr(:if, condition, body, elsebody)
                keyword("if "); noblock(condition); keyword("; "); noblock(body);
                keyword("; ")
                Meta.isexpr(elsebody, :elseif) || keyword("else ")
                noblock(elsebody); keyword("; end")

            @case Expr(:elseif, condition, body)
                keyword("elseif "); noblock(condition); keyword("; "); noblock(body);
            
            @case Expr(:elseif, condition, body, elsebody)
                keyword("elseif "); noblock(condition); keyword("; "); noblock(body);
                keyword("; else "); noblock(elsebody)

            @case Expr(:try, try_body, catch_vars, catch_body)
                keyword("try "); noblock(try_body); keyword("; ")
                catch_vars == false || (keyword("catch "); noblock(catch_vars))
                catch_vars == false || (keyword("; "); noblock(catch_body))
                keyword("; end")

            @case Expr(:try, try_body, catch_vars, catch_body, finally_body)
                keyword("try "); noblock(try_body); keyword("; ")
                catch_vars == false || (keyword("catch "); noblock(catch_vars))
                catch_vars == false || (keyword("; "); noblock(catch_body))
                finally_body == false || (keyword("; finally "); noblock(finally_body))
                keyword("; end")

            @case Expr(:try, try_body, catch_vars, catch_body, finally_body, else_body)
                keyword("try "); noblock(try_body); keyword("; ")
                catch_vars == false || (keyword("catch "); noblock(catch_vars))
                catch_vars == false || (keyword("; "); noblock(catch_body))
                keyword("; else "); noblock(else_body)
                finally_body == false || (keyword("; finally "); noblock(finally_body))
                keyword("; end")

            @case Expr(head, args...)
                keyword('$'); print("(")
                printstyled(:Expr, color=c.call)
                print("("); keyword(":"); printstyled(head, color=c.symbol)
                print(", "); join(args); print("))")
            @case _
                print(ex)
        end
    end

    print_expr(expr)
    return
end

"""
    print_expr([io::IO], ex; kw...)

Print a given expression within one line.
`ex` can be a `Expr` or a syntax type `JLExpr`.
"""
print_inline(io::IO, expr; kw...) = InlinePrinter(io;kw...)(expr)
print_inline(expr;kw...) = InlinePrinter(stdout;kw...)(expr)
