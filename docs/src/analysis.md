```@meta
CurrentModule = Expronicon
```

# Analysis

Functions for analysing a given Julia `Expr`, e.g splitting Julia function/struct definitions etc.

```@docs
AnalysisError
is_fn
is_kw_fn
is_literal
split_function
split_function_head
split_struct
split_struct_name
split_ifelse
annotations
uninferrable_typevars
has_symbol
```
