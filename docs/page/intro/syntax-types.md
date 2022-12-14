# Syntax Types

`Expronicon` exports a set of types that represent different syntaxes in Julia,
the following is a table of all the syntax types:

| Syntax Type  | Description                                          |
| ------------ | ---------------------------------------------------- |
| `JLFunction` | describes a Julia function declaration syntax.       |
| `JLStruct`   | describes a Julia struct declaration syntax.         |
| `JLKwStruct` | describes a Julia keyword struct declaration syntax. |
| `JLField`    | describes a Julia field declaration syntax.          |
| `JLKwField`  | describes a Julia keyword field declaration syntax.  |
| `JLFor`      | describes a Julia for loop syntax.                   |
| `JLIfElse`   | describes a Julia if-else syntax.                    |
| `JLMatch`    | describes a MLStyle match syntax.                    |

## Create from Julia expression

You can use any of the syntax type's constructor to create a syntax object
from the corresponding expression:

```julia
julia> using Expronicon

julia> expr = :(function foo(x)
           x + 1
       end)

julia> jlfn = JLFunction(expr)
function foo(x)
    x + 1
end
```

then if look what's inside the syntax object:

```julia
julia> jlfn.head
:function

julia> jlfn.args
1-element Vector{Any}:
 :x

julia> jlfn.body
quote
    #= REPL[11]:1 =#
    #= REPL[11]:2 =#
    x + 1
end
```

This is useful when you want to inspect the syntactic information of an expression.
A shorter way to create a syntax object from an expression is to use the `@expr` macro:

```julia
julia> jlfn = @expr JLFunction function foo(x)
           x + 1
       end
function foo(x)
    x + 1
end
```

## Create from scratch

you can also construct a syntax object from scratch via its
keyword-arugment constructor:

```julia
julia> jlfn = JLFunction(head=:function, name=:foo, args=[:x], body=:(x + 1))
function foo(x)
    x + 1
end
```

## Generate Julia expression

and convert it back to an expression:

```julia
julia> codegen_ast(jlfn)
:(function foo(x)
      x + 1
  end)
```

all the syntax types have a `codegen_ast` method that converts the syntax object back to an expression.

## Perform pattern match

You can also perform [pattern match](https://thautwarm.github.io/MLStyle.jl/latest/) on syntax types

```julia
julia> using MLStyle

julia> @match expr begin
           JLFunction(;head) => head
           _ => false
       end
:function
```

All the syntax type supports MLStyle's pattern match and can be composed with all
MLStyle's patterns.
