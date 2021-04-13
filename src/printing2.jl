tab(n::Int) = " "^n

Base.@kwdef struct Color
    literal::Symbol = :yellow
    type::Symbol = :light_green
    string::Symbol = :cyan
    comment::Symbol = :light_black
    kw::Symbol = :light_magenta
    fn::Symbol = :light_blue
end

const theme = Color()

Base.@kwdef mutable struct PrintState
    indent::Int = 0
    color::Symbol = :normal
end

print_expr(ex) = print_expr(stdout, ex)
print_expr(io::IO, ex) = print_expr(io, ex, PrintState())

function print_expr(io::IO, ex, ps::PrintState)
    @switch ex begin
        @case Expr(:block, stmts...)
        @case Expr(:let, vars, body)
        @case Expr(:if, xs...)
        @case _
            print_within_line(io, ex, ps)
    end
end

function print_collection(io, xs, ps::PrintState; delim=", ")
    for i in 1:length(xs)
        print_expr(io, xs[i], ps)
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

function print_within_line(io::IO, ex, ps::PrintState)
    print(io, tab(ps.indent))
    ps.indent = 0
    @switch ex begin
        @case ::Number
            printstyled(io, ex; color=theme.literal)
        @case ::String
            printstyled(io, ex; color=theme.string)
        @case ::Symbol
            printstyled(io, ex; color=ps.color)
        @case Expr(:tuple, xs...)
            printstyled(io, "("; color=ps.color)
            print_collection(io, xs, ps)
            printstyled(io, ")"; color=ps.color)
        @case Expr(:(::), name, type)
            print_expr(io, name, ps)
            printstyled(io, "::"; color=ps.color)
            with_color(theme.type, ps) do
                print_expr(io, type, ps)
            end
        @case Expr(:kw, name, value) || Expr(:(=), name, value)
            print_expr(io, name, ps)
            printstyled(io, "="; color=ps.color)
            print_expr(io, value, ps)
        @case Expr(:call, name, Expr(:parameters, kwargs...), args...)
            print_expr(io, name, ps)
            printstyled(io, "("; color=ps.color)
            print_collection(io, args, ps)
            if !isempty(kwargs)
                printstyled(io, ";"; color=ps.color)
                print_collection(io, kwargs, ps)
            end
            printstyled(io, ")"; color=ps.color)
        @case Expr(:call, name, args...)
            print_expr(io, name, ps)
            printstyled(io, "("; color=ps.color)
            print_collection(io, args, ps)
            printstyled(io, ")"; color=ps.color)
        @case Expr(:return, xs...)
            printstyled(io, "return", tab(1); color=theme.kw)
            print_expr(io, xs, ps)
        @case Expr(:string, xs...)
            print(io, "\"")
            for x in xs
                if x isa String
                    print_expr(io, x, ps)
                else
                    printstyled(io, "\$"; color=theme.literal)
                    with_color(theme.literal, ps) do
                        print_expr(io, x, ps)
                    end
                end
            end
            print(io, "\"")
        @case _
            error("unknown expression: $ex")
    end
end
