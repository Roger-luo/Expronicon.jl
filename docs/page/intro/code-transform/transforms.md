# Transformations

The code transformation is the key process of meta programming.
`Expronicon` also provides a set of functions to help you make
your own transformations.

## Substitution

We provide a `Substitute` type to help you make substitution,
first you can create a `Substitute` object with a function that
describes what should be substituted

```julia
julia> sub = Substitute() do expr
           expr isa Symbol && expr in [:x] && return true
           return false
       end;
```

then you can call this object with another function describes
what to substitute with if matched.

```julia
julia> sub(_->1, :(x + y))
:(1 + y)
```

## Create similar expressions using `nexprs`

It is common that one wants to create a block of similar expressions,
for example you want to unroll a loop program manually, `nexprs` can
help you here

```julia
julia> nexprs(5) do k
           :(1 + \$k)
       end
quote
    1 + 1
    1 + 2
    1 + 3
    1 + 4
    1 + 5
end
```

## Create large code blocks using `expr_map`

It is common that one wants to create a `Expr(:block)` with a large
number of expressions and each expression is created based on different
conditions, instead of writing

```julia
ret = Expr(:block)
for i in 1:10
    push!(ret.args, :(1 + $i))
end
return ret
```

you can use `expr_map` to do this to save you some typing

```julia
expr_map(1:10) do i
    :(1 + $i)
end
```

## Renumber gensyms

Renumber gensyms to have a more deterministic output is very useful
when writing expression related tests, `renumber_gensym` can help
you do this by renumber gensym by recounting the number of gensyms
in given expression (usually a function body)

```julia
julia> renumber_gensym(:(function f()
                  $(gensym(:x)) = 1
                  $(gensym(:x)) = 2
              end))
:(function f()
      #= REPL[3]:1 =#
      #= REPL[3]:2 =#
      var"##x#1" = 1
      #= REPL[3]:3 =#
      var"##x#2" = 2
  end)
```

## Aliasing gensyms

Sometimes you want to alias a gensym to a name for better readability,
this idea is borrowed originally from the `MacroTools` package, `alias_gensym`
will remove `#<name>#<id>` like gensym with `<name>_<id>`.

## Remove annotations

Sometimes you want to remove type annotations from an expression, `rm_annotations`
can help you do this. It will remove the type annotations from the expression.

## Only give me the names

It is quite often that you only want the names of the variables in an expression,
`name_only` will remove everything else but a `Symbol`.

```julia
julia> using Expronicon

julia> name_only(:(sin(2)))
:sin

julia> name_only(:(Foo{Int}))
:Foo

julia> name_only(:(Foo{Int} <: Real))
:Foo

julia> name_only(:(x::Int))
:x
```

## Remove single block expression

To get better readability, sometimes you want to remove the single block like

```julia
begin
    x = 1
end
```

and turn it into

```julia
x = 1
```

`rm_single_block` can help you do this.

## Flatten block expressions

It can be hard to read if you have a nested block expression like

```julia
begin
    begin
        x = 1
    end

    y = 2
end
```

or even more nested, `flatten_block` can help you flatten the block expression
to make it easier to read.
