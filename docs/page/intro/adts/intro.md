# Algebra data type

Expronicon provides a way to define algebra data types. The syntax and semantic
is very similar to rust's enum type. The algebra data type is useful when you
want to define an intermediate representation (IR) for your own language,
or when you want to define a type that can be used in a pattern matching.

## Features

- support `MLStyle` pattern matching
- type stable - this enables fast pattern matching and code manipulation
- rust-like syntax

## A quick example

If you are already familiar with rust or other algebra data type
syntax, you will find the syntax very familiar.

```julia
using Expronicon.ADT: @adt

@adt Message begin
    Quit
    struct Move
        x::Int
        y::Int
    end

    Write(::String)
    ChangeColor(::Int, ::Int, ::Int)
end
```

## Limitations

**no support for generics**, because we want to guarantee the type stability.
For generic algebra data type, you can use the `@data` macro provided by
MLStyle.

## What's happening under the hood

The `@adt` macro will generate a new type and a set of constructors for the
type. It will wrap mulitple variants in the same Julia struct, and use a tag field
to distinguish the variants. This is why it is type stable.

The `@adt` macro will also generate a set of functions for pattern matching too, which
is why all `MLStyle` pattern matching works.

The `@adt` macro will also generate a set of reflection functions, so that you can
inspect the algebra data type easily.

## Comparision with other implementations

There has been a few implementations of algebra data type in Julia, we will
discuss the differences between them here.

### MLStyle's `@data`

the `@data` macro provided by MLStyle is very similar to
`@adt` in Expronicon, the main difference is that `@data` supports generic
ADT while `@adt` does not. The `@data` macro is also more idiomatic in Julia
because it lowers its variants to `struct` types. However, the `@data` macro
is not type stable, which means it is not suitable for tasks that requires type
stability.

An example of the difference can be found in the following code:

```julia
julia> module MLStyleADT

       using MLStyle: @data
       @data Message begin
           Request(::String, ::Int)
           Response(::String)
       end

       end # module

julia> MLStyleADT.Request|>typeof # it is a normal Julia type
DataType
```

and for `Expronicon` we have

```julia
julia> module ExproniconADT
       using Expronicon.ADT: @adt

       @adt Message begin
           Request(::String, ::Int)
           Response(::String)
       end

       end # module
Main.ExproniconADT

julia> ExproniconADT.Message.Request
Message.Request

julia> ExproniconADT.Message.Request|>typeof
Main.ExproniconADT.var"Message#Type"
```

### Unityper's `@compactify`

Unityper's `@compactify` is a very interesting implementation of algebra data type,
it inspires part of the design of `Expronicon`'s ADT. The main difference is that
the support of **pattern matching** and **reflection**. `@compactify` does not
support pattern matching, and it does not support reflection.

It is worth mentioning that `Unityper` supports a restricted form of pattern matching
using the `@compactified` macro, but it is not as powerful as `MLStyle`'s pattern
matching.

We write the example in Unityper's README in three styles as following

**Expronicon**

```julia
module ExproniconBench

using Expronicon.ADT: @adt
using MLStyle: @match

@adt AT begin
    struct A
        common_field::Int = 0
        a::Bool = true
        b::Int = 10
    end
    struct B
        common_field::Int = 0
        a::Int = 1
        b::Float64 = 1.0
        d::Complex = 1 + 1.0im # not isbits
    end
    struct C
        common_field::Int = 0
        b::Float64 = 2.0
        d::Bool = false
        e::Float64 = 3.0
        k::Complex{Real} = 1 + 2im # not isbits
    end
    struct D
        common_field::Int = 0
        b::Any = "hi" # not isbits
    end
end

foo!(xs) = for i in eachindex(xs)
    @inbounds x = xs[i]
    @inbounds xs[i] = @match x begin
        A(_...) => D()
        B(_...) => A()
        C(_...) => B()
        D(_...) => A()
        _ => error("aaa")
    end
end


end # ExproniconBench
```

**Unityper**

```julia
module UnityperBench

using Unityper

@compactify begin
    @abstract struct AT
        common_field::Int = 0
    end
    struct A <: AT
        a::Bool = true
        b::Int = 10
    end
    struct B <: AT
        a::Int = 1
        b::Float64 = 1.0
        d::Complex = 1 + 1.0im # not isbits
    end
    struct C <: AT
        b::Float64 = 2.0
        d::Bool = false
        e::Float64 = 3.0
        k::Complex{Real} = 1 + 2im # not isbits
    end
    struct D <: AT
        b::Any = "hi" # not isbits
    end
end

foo!(xs) = for i in eachindex(xs)
    @inbounds x = xs[i]
    @inbounds xs[i] = @compactified x::AT begin
        A => D()
        B => A()
        C => B()
        D => A()
    end
end

end # UnityperBench
```

**Naive**

```julia
module NaiveBench

abstract type AT end
Base.@kwdef struct A <: AT
    common_field::Int = 0
    a::Bool = true
    b::Int = 10
end
Base.@kwdef struct B <: AT
    common_field::Int = 0
    a::Int = 1
    b::Float64 = 1.0
    d::Complex = 1 + 1.0im # not isbits
end
Base.@kwdef struct C <: AT
    common_field::Int = 0
    b::Float64 = 2.0
    d::Bool = false
    e::Float64 = 3.0
    k::Complex{Real} = 1 + 2im # not isbits
end
Base.@kwdef struct D <: AT
    common_field::Int = 0
    b::Any = "hi" # not isbits
end

foo!(xs) = for i in eachindex(xs)
    @inbounds x = xs[i]
    @inbounds xs[i] = x isa A ? D() :
                      x isa B ? A() :
                      x isa C ? B() :
                      x isa D ? A() : error()
end

end # NaiveBench
```

then we can check the performance of `foo!` function

```julia
using Random
rng = Random.MersenneTwister(123)
gs = map(x->rand(rng, (NaiveBench.A(), NaiveBench.B(), NaiveBench.C(), NaiveBench.D())), 1:10000);
rng = Random.MersenneTwister(123)
xs = map(x->rand(rng, (UnityperBench.A(), UnityperBench.B(), UnityperBench.C(), UnityperBench.D())), 1:10000);
rng = Random.MersenneTwister(123)
ys = map(x->rand(rng, (ExproniconBench.A(), ExproniconBench.B(), ExproniconBench.C(), ExproniconBench.D())), 1:10000);
```

and the results are

```julia
julia> using BenchmarkTools

julia> @btime UnityperBench.foo!($xs)
  57.834 μs (0 allocations: 0 bytes)

julia> @btime ExproniconBench.foo!($ys)
  57.625 μs (0 allocations: 0 bytes)

julia> @btime NaiveBench.foo!($gs)
  93.375 μs (10000 allocations: 312.50 KiB)
```
