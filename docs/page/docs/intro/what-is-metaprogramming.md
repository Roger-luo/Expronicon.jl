# What is meta-programming

This introduction is aimed for people who are new to Julia and meta-programming. If you are already familiar with Julia and meta-programming, you can skip this section. If you are new to Julia, you can read the [Julia documentation](https://docs.julialang.org/en/v1/manual/introduction/) to learn more about the language.

Meta-programming is a programming technique in which computer programs have the ability to treat programs as their data. In other words, a part of the program is able to read and manipulate other parts of itself while it is running.

Julia has a powerful meta-programming system that allows you to write Julia functions that generate other Julia program. This is a very powerful technique that can be used to implement many language features, such as reflection, and code generation. It is also a powerful tool for building domain-specific languages (DSLs).

## Why use Expronicon?

The `Expronicon` package provides a set of tools for working with Julia expressions. It gives you the ability to build, inspect, and manipulate Julia expressions. It also provides a set of macros that make it easy to work with expressions. It makes your code more readable and easier to maintain.

## Meta-programming in Julia

Julia's meta-programming system is based on the idea of *expressions*. An expression is a piece of code that can be evaluated to produce a value. For example, the expression `1 + 2` evaluates to the value `3`. Expressions can be nested, so `1 + 2 * 3` evaluates to `7`.

Expressions are represented in Julia by the `Expr` type. You can create an expression using the
quoting syntax:

```julia
julia> :(1 + 2)
    :(1 + 2)
```

The `:(...)` syntax is called a *quotation* and it creates an expression. The expression `:(1 + 2)` is equivalent to the expression `Expr(:call, :+, 1, 2)`. The `Expr` constructor takes a *head* and zero or more *arguments*. The head is a symbol that describes the type of expression. The arguments are the values that the expression operates on. For example, the expression `1 + 2` has the head `:call` and the arguments `:+` and `1` and `2`.

You can use the `dump` function to see the structure of an expression:

```julia
julia> dump(:(1 + 2))
Expr
  head: Symbol call
  args: Array{Any}((3,))
    1: Symbol +
    2: Int64 1
    3: Int64 2
```

The `dump` function prints the type of the expression, the head, and the arguments. The arguments are printed recursively, so you can see the structure of nested expressions.

## Evaluating expressions

Although, this is **usually not recommended inside a function definition**, you can use the `eval` function to evaluate an expression:

```julia
julia> eval(:(1 + 1))
2
```

or you can use the `@eval` macro:

```julia
julia> @eval 1 + 1
2
```

The `@eval` macro is equivalent to `eval(:(...))`. The `@eval` macro is useful when you want to evaluate an expression that contains variables:

```julia
julia> a = 1
1

julia> b = 2

julia> @eval a + b
3

```

The `@eval` macro is useful when you want to generate code during precompilation of a package. For example, the `@eval` macro is used in the [Yao.jl](https://yaoquantum.org) to generate the `mat` function for each gate type:

```julia
for T in [:(RotationGate{D,<:SymReal} where D), :(PhaseGate{<:SymReal}), :(ShiftGate{<:SymReal})]
    @eval YaoBlocks.mat(gate::$T) = mat(Basic, gate)
end
```

## Building expressions

You can use the `Expr` constructor to build expressions:

```julia
julia> Expr(:call, :+, 1, 2)
:(1 + 2)
```

The `Expr` constructor takes a head and zero or more arguments. The head is a symbol that describes the type of expression. The arguments are the values that the expression operates on. For example, the expression `1 + 2` has the head `:call` and the arguments `:+` and `1` and `2`.

Or you can use interpolation to build expressions:

```julia
julia> :(1 + $(2 * 3))
:(1 + 6)
```

The `$(...)` syntax is called an *interpolation*. It evaluates the expression inside the parentheses and inserts the result into the expression. The `$(2 * 3)` expression is evaluated to the value `6`, which is inserted into the expression `:(1 + 6)`.

## Defining macros

`macro` is a special Julia function that is executed at compile time. It takes an expression as an argument and returns an expression. For example, the following macro takes an expression and returns an expression that evaluates to the same value:

```julia
macro identity(ex)
    return ex
end
```

You can inspect the returned expression using the `@macroexpand` macro:

```julia
julia> @macroexpand @identity 1 + 2
:(1 + 2)
```

The `@macroexpand` macro is useful for debugging macros. It prints the expression that will be evaluated instead of the expression that was passed to the macro.

You can use the `@macroexpand` macro to see how the `@eval` macro is implemented:

```julia
julia> @macroexpand @eval 1 + 1
:(Core.eval(Main, $(Expr(:copyast, :($(QuoteNode(:(1 + 1))))))))
```

## Learn more about expressions

For more information about Julia expression itself, see the [Meta Programming](https://docs.julialang.org/en/v1/manual/metaprogramming/) section of the Julia manual.
