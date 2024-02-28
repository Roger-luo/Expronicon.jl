# Split functions

The `split_xxx` functions are used to split an expression into semantic parts. For example, 
`split_function_head` splits a function head expression into name, arguments, keyword
arguments and where parameters.

```julia
julia> split_function_head(:(call(a, b; c=2)))
(:call, Any[:a, :b], Any[:($(Expr(:kw, :c, 2)))], nothing, nothing)
```

The following are the list of all the split functions:

```julia
split_function
split_function_head
split_anonymous_function_head
split_struct
split_struct_name
split_ifelse
```