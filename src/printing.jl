tab(n::Int) = " "^n

Base.@kwdef struct Color
    literal::Symbol = :light_blue
    type::Symbol = :light_green
    string::Symbol = :yellow
    comment::Symbol = :light_black
    kw::Symbol = :light_magenta
    fn::Symbol = :light_blue
end

Base.@kwdef mutable struct PrintState
    line_indent::Int = 0
    content_indent::Int = line_indent
    color::Symbol = :normal
end

"""
    sprint_expr(ex; context=nothing)

Print given expression to `String`, see also [`print_expr`](@ref).
"""
function sprint_expr(ex; context=nothing)
    buf = IOBuffer()
    if context === nothing
        print_expr(buf, ex)
    else
        print_expr(IOContext(buf, context), ex)
    end
    return String(take!(buf))
end

"""
    print_expr([io::IO], ex)

Print a given expression. `ex` can be a `Expr` or a syntax type `JLExpr`.
"""
print_expr(ex) = print_expr(stdout, ex)
print_expr(io::IO, ex) = print_expr(io, ex, PrintState())
print_expr(io::IO, ex, p::PrintState) = print_expr(io, ex, p, Color())

@deprecate print_ast(ex) print_expr(ex)
@deprecate print_ast(io, ex) print_expr(io, ex)

const uni_ops = Set{Symbol}([:(+), :(-), :(!), :(¬), :(~), :(<:), :(>:), :(√), :(∛), :(∜)])
const expr_infix_wide = Set{Symbol}([
    :(=), :(+=), :(-=), :(*=), :(/=), :(\=), :(^=), :(&=), :(|=), :(÷=), :(%=), :(>>>=), :(>>=), :(<<=),
    :(.=), :(.+=), :(.-=), :(.*=), :(./=), :(.\=), :(.^=), :(.&=), :(.|=), :(.÷=), :(.%=), :(.>>>=), :(.>>=), :(.<<=),
    :(&&), :(||), :(<:), :($=), :(⊻=), :(>:), :(-->)])

Base.show(io::IO, def::JLExpr) = print_expr(io, def)

function print_expr(io::IO, ex::JLExpr, ps::PrintState, theme::Color)
    print_expr(io, codegen_ast(ex), ps, theme)
end

function print_expr(io::IO, ex, ps::PrintState, theme::Color)
    @switch ex begin
        @case Expr(:block, line::LineNumberNode, stmt)
            # stmt #= line =#
            print_expr(io, stmt, ps, theme)
            print(io, tab(2))
            print_expr(io, line, ps, theme)
        @case Expr(:block, line1::LineNumberNode, line2::LineNumberNode, stmts...)
            print_kw(io, "begin", ps, theme)
            println(io, ps)
            print_stmts_list(io, ex.args, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:block, stmt1, line::LineNumberNode, stmt2)
            printstyled(io, "("; color=ps.color)
            print_expr(io, stmt1, ps, theme)
            printstyled(io, "; "; color=ps.color)
            print_expr(io, stmt2)
            printstyled(io, ")"; color=ps.color)
        @case Expr(:block, stmts...)
            print_kw(io, "begin", ps, theme)
            println(io, ps)
            print_stmts_list(io, stmts, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:let, vars, body)
            print_kw(io, "let", ps, theme)
            if !isempty(vars.args)
                print(io, tab(1))
                print_collection(io, vars.args, ps, theme)
            end
            println(io, ps)
            print_stmts(io, body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:if, cond, body, otherwise...) || Expr(:elseif, cond, body, otherwise...)
            within_line(io, ps) do
                print_kw(io, string(ex.head, tab(1)), ps, theme)
                print_expr(io, cond, ps, theme)
            end
            println(io, ps)
            print_stmts(io, body, ps, theme)
            if isempty(otherwise)
                print_end(io, ps, theme)
            else
                otherwise = otherwise[1]
                if Meta.isexpr(otherwise, :elseif)
                    print_expr(io, otherwise, ps, theme)
                else
                    print_kw(io, "else", ps, theme)
                    println(io, ps)
                    print_stmts(io, otherwise, ps, theme)
                    print_end(io, ps, theme)
                end
            end
        @case Expr(:for, head, body)
            within_line(io, ps) do
                print_kw(io, "for ", ps, theme)
                if Meta.isexpr(head, :block)
                    print_collection(io, head.args, ps, theme)
                else
                    print_expr(io, head, ps, theme)
                end
            end
            println(io, ps)
            print_stmts(io, body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:function, call, body)
            within_line(io, ps) do
                print_kw(io, "function ", ps, theme)
                print_expr(io, call, ps, theme)
            end
            println(io, ps)
            print_stmts(io, body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:macro, call, body)
            within_line(io, ps) do
                print_kw(io, "macro ", ps, theme)
                print_expr(io, call, ps, theme)
            end
            println(io, ps)
            print_stmts(io, body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:macrocall, &(GlobalRef(Core, Symbol("@doc"))), line, doc, code)
            print_expr(io, line, ps, theme)
            println(io, ps)
            print(io, tab(ps.line_indent))
            printstyled(io, "\"\"\""; color=theme.string)
            println(io, ps)
            lines = split(doc, '\n')
            for (i, line) in enumerate(lines)
                print(io, tab(ps.line_indent))
                printstyled(io, line; color=theme.string)
                if i != length(lines)
                    println(io, ps)
                end
            end
            print(io, tab(ps.line_indent))
            printstyled(io, "\"\"\""; color=theme.string)
            println(io, ps)
            print_expr(io, code, ps, theme)
        @case Expr(:macrocall, Symbol("@__MODULE__"), line)
            with_color(theme.fn, ps) do
                print_expr(io, Symbol("@__MODULE__"), ps, theme)
            end
        @case Expr(:macrocall, name::Symbol, line, s::String)
            if endswith(string(name), "_str")
                printstyled(io, string(name)[2:end-4]; color=theme.fn)
                print_expr(s)
            else
                print_macro(io, name, line, (s, ), ps, theme)
            end
        @case Expr(:macrocall, name, line, xs...)
            print_macro(io, name, line, xs, ps, theme)
        @case Expr(:struct, ismutable, head, body)
            within_line(io, ps) do
                if ismutable
                    printstyled(io, "mutable "; color=theme.kw)
                end
                printstyled(io, "struct "; color=theme.kw)
                print_expr(io, head, ps, theme)
            end
            println(io, ps)
            print_stmts(io, body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:try, try_body, catch_var, catch_body)
            print_try(io, try_body, ps, theme)
            print_catch(io, catch_var, catch_body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:try, try_body, false, false, finally_body)
            print_try(io, try_body, ps, theme)
            print_finally(io, finally_body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:try, try_body, catch_var, catch_body, finally_body)
            print_try(io, try_body, ps, theme)
            print_catch(io, catch_var, catch_body, ps, theme)
            print_finally(io, finally_body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:module, notbare, name, body)
            if notbare
                print_kw(io, "module", ps, theme)
            else
                print_kw(io, "baremodule", ps, theme)
            end
            println(io, ps)
            print_stmts(io, body, ps, theme)
            print_end(io, ps, theme)
        @case Expr(:const, body)
            within_line(io, ps) do
                print_kw(io, "const", ps, theme)
                print(io, tab(1))
                print_expr(io, body, ps, theme)
            end
        @case _
            print_within_line(io, ex, ps, theme)
    end
end

function print_kw(io::IO, x, ps, theme::Color)
    print(io, tab(ps.line_indent))
    printstyled(io, x; color=theme.kw)
end

function print_macro(io, name, line, xs, ps, theme)
    print_expr(io, line, ps, theme)
    println(io, ps)
    within_line(io, ps) do
        with_color(theme.fn, ps) do
            print_expr(io, name, ps, theme)
        end
        print(io, tab(1))
        print_collection(io, xs, ps, theme; delim=tab(1))
    end
end

print_end(io::IO, ps, theme) = print_kw(io, "end", ps, theme)

function Base.println(io::IO, ps::PrintState)
    ps.line_indent = ps.content_indent
    println(io)
end

function print_stmts(io, body, ps::PrintState, theme::Color)
    if body isa Expr && body.head === :block
        print_stmts_list(io, body.args, ps, theme)
    else
        within_indent(ps) do
            print_expr(io, body, ps, theme)
            println(io, ps)
        end
    end
end

function print_try(io, try_body, ps, theme)
    print_kw(io, "try", ps, theme)
    println(io, ps)
    print_stmts(io, try_body, ps, theme)
end

function print_catch(io, catch_var, catch_body, ps, theme)
    print_kw(io, "catch ", ps, theme)
    print_expr(io, catch_var, ps, theme)
    println(io, ps)
    print_stmts(io, catch_body, ps, theme)
end

function print_finally(io, finally_body, ps, theme)
    print_kw(io, "finally", ps, theme)
    println(io, ps)
    print_stmts(io, finally_body, ps, theme)
end

function print_stmts_list(io, stmts, ps::PrintState, theme::Color)
    within_indent(ps) do
        for stmt in stmts
            print_expr(io, stmt, ps, theme)
            println(io, ps)
        end
    end
    return
end

function print_collection(io, xs, ps::PrintState, theme=Color(); delim=", ")
    for i in 1:length(xs)
        print_expr(io, xs[i], ps, theme)
        if i !== length(xs)
            print(io, delim)
        end
    end
end

function with_color(f, name::Symbol, ps::PrintState)
    color = ps.color
    if color === :normal
        ps.color = name
    end
    ret = f()
    ps.color = color
    return ret
end

function within_line(f, io, ps)
    indent = ps.line_indent
    print(io, tab(indent))
    ps.line_indent = 0
    ret = f()
    ps.line_indent = indent
    return ret
end

function within_indent(f, ps)
    ps.line_indent += 4
    ps.content_indent = ps.line_indent
    ret = f()
    ps.line_indent -= 4
    ps.content_indent = ps.line_indent
    return ret
end

function print_within_line(io::IO, ex, ps::PrintState, theme::Color=Color())
    within_line(io, ps) do
        @switch ex begin
            @case ::Number
                printstyled(io, ex; color=theme.literal)
            @case ::String
                printstyled(io, "\"", ex, "\""; color=theme.string)
            @case ::Symbol
                printstyled(io, ex; color=ps.color)
            @case ::Nothing
                printstyled(io, "nothing"; color=:blue)
            @case ::QuoteNode
                if Base.isidentifier(ex.value)
                    print(io, ":", ex.value)
                else
                    print(io, ":(", ex.value, ")")
                end
            @case ::GlobalRef
                printstyled(io, ex.mod, "."; color=ps.color)
                print_expr(io, ex.name, ps, theme)
            @case ::LineNumberNode
                printstyled(io, ex; color=theme.comment)
            @case Expr(:export, xs...)
                print_kw(io, "export ", ps, theme)
                print_collection(io, xs, ps, theme)
            @case Expr(:tuple, Expr(:parameters, kwargs...), args...)
                printstyled(io, "("; color=ps.color)
                print_collection(io, args, ps, theme)
                if !isempty(kwargs)
                    printstyled(io, "; "; color=ps.color)
                    print_collection(io, kwargs, ps)
                end
                printstyled(io, ")"; color=ps.color)
            @case Expr(:tuple, xs...)
                printstyled(io, "("; color=ps.color)
                print_collection(io, xs, ps)
                printstyled(io, ")"; color=ps.color)
            @case Expr(:(::), type)
                printstyled(io, "::"; color=ps.color)
                with_color(theme.type, ps) do
                    print_expr(io, type, ps, theme)
                end
            @case Expr(:(::), name, type)
                print_expr(io, name, ps, theme)
                printstyled(io, "::"; color=ps.color)
                with_color(theme.type, ps) do
                    print_expr(io, type, ps, theme)
                end
            @case Expr(:., a, b::QuoteNode)
                print_expr(io, a, ps, theme)
                printstyled(io, "."; color=ps.color)
                print_expr(io, b.value, ps, theme)
            @case Expr(:., a, b)
                print_expr(io, a, ps, theme)
                printstyled(io, "."; color=ps.color)
                print_expr(io, b, ps, theme)
            @case Expr(:(<:), name, type)
                print_expr(io, name, ps, theme)
                printstyled(io, " <: "; color=ps.color)
                with_color(theme.type, ps) do
                    print_expr(io, type, ps, theme)
                end
            @case Expr(:kw, name, value) || Expr(:(=), name, value)
                print_expr(io, name, ps, theme)
                printstyled(io, tab(1), "=", tab(1); color=ps.color)
                print_expr(io, value, ps, theme)
            @case Expr(:..., name)
                print_expr(io, name, ps, theme)
                print(io, "...")
            @case Expr(:&, name)
                printstyled(io, "&"; color=theme.kw)
                print_expr(io, name, ps, theme)
            @case Expr(:$, name)
                printstyled(io, "\$"; color=theme.kw)
                print(io, "(")
                print_expr(io, name, ps, theme)
                print(io, ")")
            @case Expr(:curly, name, vars...)
                print_expr(io, name, ps, theme)
                print(io, "{")
                with_color(theme.type, ps) do
                    print_collection(io, vars, ps, theme)
                end
                print(io, "}")
            @case Expr(:ref, name, xs...)
                print_expr(io, name, ps, theme)
                print(io, "[")
                print_collection(io, xs, ps, theme)
                print(io, "]")
            @case Expr(:where, body, whereparams...)
                print_expr(io, body, ps, theme)
                printstyled(io, tab(1), "where", tab(1); color=theme.kw)
                print(io, "{")
                print_collection(io, whereparams, ps, theme)
                print(io, "}")
            @case Expr(:call, name, Expr(:parameters, kwargs...), args...)
                print_expr(io, name, ps, theme)
                printstyled(io, "("; color=ps.color)
                print_collection(io, args, ps)
                if !isempty(kwargs)
                    printstyled(io, "; "; color=ps.color)
                    print_collection(io, kwargs, ps)
                end
                printstyled(io, ")"; color=ps.color)
            @case Expr(:call, :(:), xs...)
                print_collection(io, xs, ps, theme; delim=":")
            @case Expr(:call, name::Symbol, x)
                if name in uni_ops
                    print_expr(io, name, ps, theme)
                    print_expr(io, x, ps, theme)
                else
                    print_call_expr(io, name, [x], ps, theme)
                end
            @case Expr(:call, :+, xs...)
                print_collection(io, xs, ps, theme; delim=" + ")
            @case Expr(:call, name, lhs, rhs)
                func_prec = Base.operator_precedence(name_only(name))
                if func_prec > 0
                    print_expr(io, lhs, ps, theme)
                    print(io, tab(1))
                    print_expr(io, name, ps, theme)
                    print(io, tab(1))
                    print_expr(io, rhs, ps, theme)
                else
                    print_call_expr(io, name, [lhs, rhs], ps, theme)
                end
            @case Expr(:call, name, args...)
                print_call_expr(io, name, args, ps, theme)
            @case Expr(:(->), call, body)
                print_expr(io, call, ps, theme)
                printstyled(io, tab(1), "->", tab(1); color=theme.kw)
                print_expr(io, body, ps, theme)
            @case Expr(:return, x)
                printstyled(io, "return", tab(1); color=theme.kw)
                @match x begin
                    Expr(:tuple, xs...) => print_collection(io, xs, ps)
                    _ => print_expr(io, x, ps, theme)
                end
            @case Expr(:string, xs...)
                printstyled(io, "\""; color=theme.string)
                for x in xs
                    if x isa String
                        printstyled(io, x, ; color=theme.string)
                    else
                        printstyled(io, "\$"; color=theme.literal)
                        with_color(theme.literal, ps) do
                            print_expr(io, x, ps, theme)
                        end
                    end
                end
                printstyled(io, "\""; color=theme.string)
            @case Expr(head, lhs, rhs)
                if head in expr_infix_wide
                    print_expr(io, lhs, ps, theme)
                    printstyled(io, tab(1), head, tab(1); color=theme.kw)
                    print_expr(io, rhs, ps, theme)
                else
                    Base.show_unquoted_quote_expr(IOContext(io, :unquote_fallback => true), ex, ps.line_indent, -1, 0)
                end
            @case ::Base.ExprNode
                Base.show_unquoted_quote_expr(IOContext(io, :unquote_fallback => true), ex, ps.line_indent, -1, 0)
            @case _
                print(io, ex)
        end
    end
    return
end

function print_call_expr(io::IO, name, args, ps, theme)
    print_expr(io, name, ps, theme)
    printstyled(io, "("; color=ps.color)
    print_collection(io, args, ps, theme)
    printstyled(io, ")"; color=ps.color)
end
