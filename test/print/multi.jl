using Expronicon: @expr, Printer, InlinePrinter, print_inline, print_expr

print_expr(:(1 + 2; 2+x))
print_expr(:(:(1 + 2; 2+x)))
print_expr(:(:(:(1 + 2; 2+x))))
print_expr(:(:(:(:(1 + 2; 2+x)))))

print_expr(:(1 + 2; 2+x); always_begin_end=true)

ex = quote
    quote
        quote
            1 + 2
            2 + x
        end
    end
end

print_expr(ex; always_begin_end=true)

ex = quote
    quote
        quote
            1 + 2
            2 + x
        end
    end

    begin
        quote
            1 + 2
            2 + x
        end
    end
end

print_expr(ex)
print_expr(ex; always_begin_end=true)

ex = :(let x = 1, y; x + 1; end)
print_expr(ex)
print_expr(ex; always_begin_end=true)

ex = @expr if a == 1
    1 + 1
    2 + 2
elseif a == 2
    3 + 3
    4 + 4
elseif a == 3
    5 + 5
else
    5 + 5
    6 + 6
end

print_expr(ex)

ex = @expr if a == 1
    1 + 1
    2 + 2
else
    5 + 5
    6 + 6
end

print_expr(ex)

ex = @expr if a == 1
    1 + 1
    2 + 2
end

print_expr(ex)

ex = @expr if a == 1
    if a == 1
        1 + 1
        2 + 2
    else
        1 + 1
    end
else
    5 + 5
    6 + 6
end

print_expr(ex)


ex = Expr(:if, :(a == 1), :(1 + 1), :(5 + 5))
print_expr(ex)

ex = Expr(:if, :(a == 1), :(1 + 1), Expr(:elseif, :(a == 2), :(3 + 3), Expr(:elseif, :(a == 3), :(5 + 5), :(7 + 7))))
print_expr(ex)

ex = Expr(:if, :(a == 1), :(1 + 1), Expr(:elseif, :(a == 2), :(3 + 3), Expr(:elseif, :(a == 3), :(5 + 5))))
print_expr(ex)

ex = @expr for i in 1:10
    1 + i
end

print_expr(ex)
print_expr(ex; line=true)

ex = @expr for (i,j) in zip(1:10, 1:5)
    1 + i
end

print_expr(ex; line=true)

ex = @expr while a < 10
    1 + a
end

print_expr(ex)
print_expr(ex; line=true)

ex = @expr function foo(a, b; c)
    1 + 1
end
print_expr(ex)
print_expr(ex; line=true)

ex = Expr(:function, :(foo(a, b; c)), :(1 + 1))
print_expr(ex)
print_expr(ex; line=true)

ex = @expr foo(a, b; c) = 1 + 1
print_expr(ex)

ex = @expr macro foo(x, y::Int)
    1 + 1
end

print_expr(ex)

ex = @expr @expr begin
    1 + 1
end begin
    1 + 1
end

print_expr(ex)

ex = @expr @__MODULE__
print_expr(ex)

ex = @expr begin
    quote
        """
        aaaa
        """
        sin(x) = x
    end
end

print_expr(ex)

ex = @expr begin
    quote
        """
        aaaa $aaa
        """
        sin(x) = x
    end
end

print_expr(ex)

ex = @expr @__MODULE__
print_expr(ex)
print_expr(ex; line=true)

ex = @expr struct Foo{T} <: Goo
    a
    b::Int
    c::T

    Foo(x) = new(x)
    Foo(x, y) = if x + 1 == y
        new(x, y)
    else
        new(x, y, 1)
    end
end

print_expr(ex)
print_expr(ex)

ex = @expr foo(x, y) = x + y
print_expr(ex)

ex = @expr try
    1 + 1
catch
    2 + 2
end

print_expr(ex)

ex = @expr try
    1 + 1
catch e
    2 + 2
end

print_expr(ex)

ex = @expr try
    1 + 1
finally
    2 + 2
end

print_expr(ex)

ex = @expr try
    1 + 1
catch e
    2 + 2
finally
    2 + 2
end

print_expr(ex)

ex = @expr module ABC
    1 + 1
    2 + 2
end

print_expr(ex)

ex = @expr const X = if a == 1
    1 + 1
    2 + 2
else
    3 + 3
    4 + 4
end

print_expr(ex)


ex = @expr if x > 100
    x + 1
elseif x > 90
    x + 2
elseif x > 80
    x + 3
else
    error("some error msg")
end

print_expr(ex)

print_expr(:(foo() do; end))
print_expr(:(foo() do x; end))
print_expr(:(foo() do x, y, z; end))
print_expr(:(foo() do x, y, z; 1+1;2+2; end))
print_expr(:(foo() do x, y, z...; 1+1;2+2; end))

ex = @expr function (p::InlinePrinter)(x, (xs...); delim = ", ")
    p(x)
    for x = xs
        printstyled(p.io, delim; color = (p.color).keyword)
        p(x)
    end
end

print_expr(ex)

ex = @expr function (InlinePrinter)(io::IO; color::ColorScheme = Monokai256(), line::Bool = false)
    InlinePrinter(io, color, line, InlinePrinterState())
end

print_expr(ex)

print_expr(:(@foo "aaaaa" a b c))
print_expr(:(@foo "aaaaa\naaaaa" a b c))

ex = quote
    function foo()
        msg = :("expect $($nargs) arguments, got $(length(args)) arguments")
    end
end

print_expr(ex)

ex = quote
    function foo()
        msg = :("expect $($nargs) arguments\n, got $(length(args)) arguments")
    end
end

print_expr(ex)

ex = quote
    function split_lines(ex)::Vector{Any}
        ex isa AbstractString && return Any[[line] for line in eachsplit(ex, '\n')]
    end
end

print_expr(ex)
