using MLStyle
using Yuan
using Yuan.Types

ex = :(function foo(x::Int, y::Type{T}) where {T <: Real}
    return x
end)

ex = :(function (x, y)
    return 2
end)

ex = :(function (x, y; kw=2)
    return "aaa"
end)

ex = :((x, y)->sin(x))

JLFunction(ex)

ex.args[1].args
split_call(ex.args[1])

ex = :(struct Foo
    x::Int
end)

ex = :(mutable struct Foo{T, S <: Real} <: AbstractArray
    a::Float64

    function foo(x, y, z)
        new(1)
    end
end)

JLStruct(ex)