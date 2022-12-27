Base.@kwdef mutable struct InlinePrinterState
    type::Bool = false
    symbol::Bool = false
    call::Bool = false
    macrocall::Bool = false
    quoted::Bool = false
    keyword::Bool = false
    block::Bool = true # show begin ... end by default
    precedence::Int = 0 # precedence of the parent expression
end

function with(f::Function, p::InlinePrinterState, name::Symbol, new)
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

    function string(s)
        printstyled('"'; color=c.string)
        for ch in s
            if ch == '"'
                printstyled("\\\""; color=c.quoted)
            else
                printstyled(ch, color=c.string)
            end
        end
        printstyled('"'; color=c.string)
    end
    keyword(s) = printstyled(s, color=c.keyword)

    function symbol(ex)
        color = if p.state.type
            c.type
        elseif p.state.quoted
            c.quoted
        elseif p.state.call
            c.call
        elseif p.state.macrocall
            c.macrocall
        else # normal symbol in expr
            :normal
        end
        is_gensym(ex) && printstyled("var\""; color=color)
        printstyled(ex, color=color)
        is_gensym(ex) && printstyled("\""; color=color)
    end

    quoted(ex) = with(() -> p(ex), p.state, :quoted, true)
    type(ex) = with(() -> p(ex), p.state, :type, true)
    call(ex) = with(() -> p(ex), p.state, :call, true)
    macrocall(ex) = with(() -> p(ex), p.state, :macrocall, true)
    noblock(ex) = with(() -> p(ex), p.state, :block, false)
    block(ex) = with(() -> p(ex), p.state, :block, true)

    function precedence(f, s)
        if s isa Int
            preced = s
        else
            preced = Base.operator_precedence(s)
        end

        preced > 0 && p.state.precedence >= preced && print('(')
        with(f, p.state, :precedence, preced)
        preced > 0 && p.state.precedence >= preced && print(')')
    end

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
                    keyword(":("); quoted(ex.value); keyword(")")
                end
            @case ::GlobalRef
                p(ex.mod); keyword("."); p(ex.name)
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
                precedence(:...) do
                    p(name);keyword("...")
                end
            @case Expr(:&, name)
                precedence(:&) do
                    keyword("&")
                    p(name)
                end
            @case Expr(:(::), t)
                precedence(:(::)) do
                    keyword("::");type(t)
                end
            @case Expr(:(::), name, t)
                precedence(:(::)) do
                    p(name);keyword("::");type(t)
                end
            @case Expr(:$, name)
                precedence(:$) do
                    keyword('$');print("("); p(name); print(")")
                end

            @case Expr(head, lhs, rhs) && if head in expr_infix_wide end
                precedence(head) do
                    p(lhs); keyword(" $head "); p(rhs)
                end

                @case Expr(:., name)
                print(name)
            @case Expr(:., object, QuoteNode(name)) || Expr(:., object, name)
                precedence(:.) do
                    p(object); keyword("."); p(name)
                end
            @case Expr(:(<:), type, supertype)
                precedence(:(<:)) do
                    p(type); keyword(" <: "); p(supertype)
                end

            # call expr
            @case Expr(:call, :(:), args...)
                precedence(:(:)) do
                    join(args, ":")
                end

            @case Expr(:call, f::Symbol, arg) && if Base.isunaryoperator(f) end
                precedence(typemax(Int)) do
                    keyword(f); p(arg)
                end
            @case Expr(:call, f::Symbol, args...) && if Base.isbinaryoperator(f) end
                precedence(f) do
                    join(args, " $f ")
                end
            @case Expr(:call, f, Expr(:parameters, kwargs...), args...)
                f isa Symbol || print("(")
                call(f);
                f isa Symbol || print(")")
                print("("); join(args); keyword("; "); join(kwargs); print(")")
            @case Expr(:call, f, args...)
                f isa Symbol || print("(")
                call(f);
                f isa Symbol || print(")")
                print_braces(args, "(", ")")
            @case Expr(:tuple, args...)
                print_braces(args, "(", ")")
            @case Expr(:curly, t, args...)
                with(p.state, :type, true) do
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

            @case Expr(:do, call, Expr(:->, Expr(:tuple, args...), body))
                p(call); keyword(" do");
                isempty(args) || (print(" "); p(args...);)
                keyword("; ");
                noblock(body);
                isempty(args) || print(" ")
                keyword("end")

            @case Expr(:quote, stmt)
                keyword(":("); noblock(stmt); keyword(")")
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
                    keyword('$')
                    x isa Symbol && return p(x)
                    print("("); p(x); print(")")
                end
                printstyled("\"", color=c.string)

            @case Expr(:block, args...) && if length(args) == 2 && is_line_no(args[1]) && is_line_no(args[2]) end
                p(args[1]); print(" "); p(args[2])
            @case Expr(:block, args...) && if length(args) == 2 && is_line_no(args[1]) end
                p(args[1]); print(" "); noblock(args[2])
            @case Expr(:block, args...) && if length(args) == 2 && is_line_no(args[2]) end
                noblock(args[1]); print(" "); p(args[2])
            @case Expr(:block, args...) && if length(args) == 2 end
                print("("); noblock(args[1]); keyword("; "); noblock(args[2]); print(")")
            @case Expr(:block, args...)
                p.state.block && keyword("begin ")
                with(p.state, :block, true) do # print inner begin .. end
                    join(args, "; ")
                end
                p.state.block && keyword(" end")
            @case Expr(:let, Expr(:block, args...), body)
                keyword("let "); join(args, ", "); keyword("; "); noblock(body);
                keyword("; end")
            @case Expr(:macrocall, f, line, args...)
                p.line && printstyled(line, color=c.comment)
                macrocall(f)
                print_braces(args, "(", ")")
            @case Expr(:return, Expr(:tuple, args...))
                keyword("return "); join(args)
            @case Expr(:return, args...)
                keyword("return "); join(args)
            @case Expr(:module, bare, name, body)
                bare ? keyword("module ") : keyword("baremodule ")
                p(name);print("; "); noblock(body); keyword(" end")
            @case Expr(:using, args...)
                keyword("using ");join(args)
            @case Expr(:import, args...)
                keyword("import ");join(args)
            @case Expr(:as, name, alias)
                p(name); keyword(" as "); p(alias)
            @case Expr(:export, args...)
                keyword("export ");join(args)
            @case Expr(:(:), head, args...)
                p(head); keyword(": "); join(args)
            @case Expr(:where, body, whereparams...)
                p(body); keyword(" where ")
                with(p.state, :type, true) do
                    join(whereparams, ", ")
                end

            @case Expr(:for, iteration, body)
                keyword("for "); noblock(iteration); keyword("; "); noblock(body);
                keyword("; end")
            @case Expr(:while, condition, body)
                keyword("while "); noblock(condition); keyword("; "); noblock(body);
                keyword("; end")
            
            @case Expr(:continue)
                keyword("continue")

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

            @case Expr(:struct, ismutable, name, body)
                ismutable ? keyword("mutable struct ") : keyword("struct ")
                p(name); keyword("; ");
                noblock(body); keyword("; end")

            @case Expr(:primitive, name, size)
                keyword("primitive "); p(name); print(" "); p(size); keyword(" end")

            @case Expr(:meta, :inline)
                macrocall(GlobalRef(Base, Symbol("@_inline_meta")));
                keyword(";")

            @case Expr(:symboliclabel, label)
                macrocall(GlobalRef(Base, Symbol("@label")));
                print(" "); p(label);
            @case Expr(:symbolicgoto, label)
                macrocall(GlobalRef(Base, Symbol("@goto")));
                print(" "); p(label);

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
