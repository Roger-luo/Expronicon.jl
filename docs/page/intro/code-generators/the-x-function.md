# The X functions

`Expronicon` provides a set of functions that can be used to generate certain Julia expressions
to give you better readability and correctness. The functions are named with a `x` prefix with
similar name as `Base` functions or expression head.

For example, the `xprintln` function is similar to `println` but it returns an expression

```julia
julia> xprintln("Hello World")
:((Base).println("Hello World"))
```

This will allow you to use string interpolation instead of expression interpolation
easily

```julia
julia> xprintln("Hello $(1+2)")
:((Base).println("Hello 3"))
```

the following are the list of functions that are provided

```julia
xtuple
xnamedtuple
xcall
xpush
xgetindex
xfirst
xlast
xprint
xprintln
xmap
xmapreduce
xiterate
```
