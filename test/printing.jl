using Test
using Expronicon
using MLStyle

@testset "one line expression" begin
    @test sprint_expr(:(name::type)) == "name::type"
    @test sprint_expr(:("abc $name")) == "\"abc \$name\""
    @test sprint_expr(:(compare_expr(lhs, rhs::Int))) == "compare_expr(lhs, rhs::Int)"
    @test sprint_expr(:(compare_expr(lhs, rhs::Int; a = "c"))) == "compare_expr(lhs, rhs::Int; a = \"c\")"
    @test sprint_expr(:(return a, b, c)) == "return a, b, c"
    @test sprint_expr(:(a = b)) == "a = b"
    @test sprint_expr(Expr(:kw, :a, :b)) == "a = b"
    @test sprint_expr(:(!x)) == "!x"
    @test sprint_expr(:(x + 1)) == "x + 1"
    @test sprint_expr(:(x * 1)) == "x * 1"
    str = sprint_expr(:(f(x) = x))
    @test occursin("f(x) = x", str)
    str = sprint_expr(:(x->2x))
    @test occursin("x -> 2 * x", str)
    @test sprint_expr(:(Type{T <: Real})) == "Type{T <: Real}"
end

print_expr(:(let x, y
    x + 1
    y + 1
end))

print_expr(:(if x > 0
    x + 1
end))

print_expr(quote
x < 0
end)

print_expr(:(if x > 0
    x + 1
elseif x > 1
    x + 2
elseif x < 0
    x + 3
else
    x + 4
end))

print_expr(:(function foo(x, y::T; z::Int = 1) where {N, T <: Real}
    x + 1
end))

ex = @expr struct Foo <: Super
    x::Int
    Foo(x::Int) = new(x)
    Foo(x::Int) = new(x)
end

print_expr(ex)

ex = @expr mutable struct Goo <: Super
    x::Int
    Foo(x::Int) = new(x)
    Foo(x::Int) = new(x)
end

print_expr(ex)

ex = :(function compare_expr(lhs, rhs)
@switch (lhs, rhs) begin
    @case (::Symbol, ::Symbol)
        lhs === rhs
    @case (Expr(:curly, name, lhs_vars...), Expr(:curly, &name, rhs_vars...))
        all(map(compare_vars, lhs_vars, rhs_vars))
    @case (Expr(:where, lbody, lparams...), Expr(:where, rbody, rparams...))
        compare_expr(lbody, rbody) &&
            all(map(compare_vars, lparams, rparams))
    @case (Expr(head, largs...), Expr(&head, rargs...))
            isempty(largs) && isempty(rargs) ||
        (length(largs) == length(rargs) && all(map(compare_expr, largs, rargs)))
    # ignore LineNumberNode
    @case (::LineNumberNode, ::LineNumberNode)
        true
    @case _
        lhs == rhs
end
end)

print_expr(ex)

ex = :(try
    1 + 1
catch e
    rethrow(ex)
end)

print_expr(ex)

ex = :(try
    1 + 1
finally
    rethrow(ex)
end)

print_expr(ex)

ex = :(try
    1 + 1
catch e
    rethrow(ex)
finally
    1 + 2
end)

print_expr(ex)

def = @expr JLFunction function foo(x, y)
    1 + 1
end

print_expr(def)

def = @expr JLKwStruct struct Moo
    x::Int = 1
end

print_expr(def)

ex = @expr for i in 1:10, j in 1:10
    M[i, j] += 1
end

print_expr(ex)

ex = @expr function foo(i, j)
    for i in 1:10
        M[i, j] += 1
    end
end
print_expr(ex)

ex = quote
    """
        foo(i, j)

    test function. test function.
    test function. test function.
    """
    function foo(i, j)
        for i in 1:10
            M[i, j] += 1
        end
    end
end

print_expr(ex)

ex = quote
    """
        foo(i, j)

    test function. test function.
    test function. test function.
    """
    function foo(i, j)
        function goo(x)
            return x
        end
    end
end

print_expr(ex)