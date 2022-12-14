# Checks

`Expronicon` provides a rich set of check functions. These functions are used to check the
semantics of an expression. For example, `is_function` checks if an expression is a function.

```julia
julia> is_function(:(f(x) = x + 1))
true

julia> is_function(:(x + 1))
false
```

Here is a list of all the check functions:

```julia
is_function
is_kw_function
is_struct
is_tuple
is_splat,
is_ifelse
is_for
is_field
is_field_default
is_datatype_expr
is_matrix_expr
has_symbol
is_literal
is_gensym
alias_gensym
has_kwfn_constructor
has_plain_constructor
compare_expr
```
