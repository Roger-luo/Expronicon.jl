# Heuristics

There are some analysis tools that are not based on official definitions, but on heuristics. These are not guaranteed to be correct/accurate, but they can be useful in some cases.

## Guess type

The `guess_type` function tries to guess the type of an type expression.

```julia
julia> guess_type(Main, :(Union{Float64, X}))
:(Union{Float64, X})

julia> guess_type(Main, :(Union{Float64, Int}))
Union{Float64, Int64}
```

## Guess module

The `guess_module` function tries to guess
the module of given expression `ex` (of a module)
in module `m`. If `ex` is not a module, or cannot be
determined return `nothing`.

```julia
julia> guess_module(Main, :(Base))
Base

julia> guess_module(Main, :(Base.Test))
:Test
```
