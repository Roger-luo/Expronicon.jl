# Development Tools

`Expronicon` provides some tools for macro development. We will go through them in this section.

## Inspecting expressions

You can use `@expr` to inspect an expression taken by a macro:

```julia
julia> @expr 1 + 2
:(1 + 2)
```

unlike the `quote ... end` or `:(...)` syntax, `@expr` returns whatever is received by the macro
without any modifications. This is useful when you want to check the input of an macro definition.
For instance, `quote ... end` will return a `Expr(:block, ...)` expression, but `@expr` will return
the expression as is.

```julia
julia> @expr begin
           a = 1
           b = 2
           a + b
       end
quote
    #= REPL[5]:2 =#
    a = 1
    #= REPL[5]:3 =#
    b = 2
    #= REPL[5]:4 =#
    a + b
end

julia> @expr a + 1
:(a + 1)
```

## Testing generated expressions

`Expronicon` provides a `@test_expr` macro for testing generated expressions. It is similar to
`@test` in `Test` package, but it takes `<lhs> = <rhs>` where `<lhs>` and `<rhs>` are two expression
to compare with each other.

This macro only compares the semantic of the expressions, e.g it will ignore line number
nodes, recursive code blocks, etc.

```julia
julia> lhs = quote
    a = 1
    b = 2
    a + b
end

julia> rhs = Expr(:block, :(a = 1), :(b = 2), :(a + b))
quote
    a = 1
    b = 2
    a + b
end

julia> lhs == rhs
false

julia> using Test

julia> @test_expr lhs == rhs
Test Passed
```

::: tip
`@test_expr` requires `Test` package to be loaded.
:::
