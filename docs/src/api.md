# API Reference

## Syntax Types

Convenient types for storing analysis results of a given Julia `Expr`, or for creating
certain Julia objects easily. These types define some common syntax one would manipulate
in Julia meta programming.

```@docs
JLFunction
JLCall
JLStruct
JLKwStruct
JLIfElse
JLMatch
JLFor
JLField
JLKwField
NoDefault
no_default
JLExpr
```

## Analysis

Functions for analysing a given Julia `Expr`, e.g splitting Julia function/struct definitions etc.

```@autodocs
Modules = [Expronicon]
Pages = [
    "analysis/check.jl",
    "analysis/compare.jl",
    "analysis/cons.jl",
    "analysis/exception.jl",
    "analysis/guess.jl",
    "analysis/reflection.jl",
    "analysis/split.jl",
]
```

## Transform

Some common transformations for Julia `Expr`, these functions takes an `Expr` and returns an `Expr`.

```@autodocs
Modules = [Expronicon]
Pages = ["transform.jl"]
```

## CodeGen

Code generators, functions that generates Julia `Expr` from given arguments, `Expronicon` types. 

```@autodocs
Modules = [Expronicon]
Pages = ["codegen.jl"]
```

```@docs
codegen_match
@syntax_pattern
```

## Printings

Pretty printing functions.

```@autodocs
Modules = [Expronicon]
Pages = [
    "print/colors.jl",
    "print/inline.jl",
    "print/multi.jl",
    "print/print.jl",
    "print/utils.jl",
]
```

## Algebra Data Type

Algebra data type

```@autodocs
Modules = [Expronicon.ADT]
Pages = [
    "adt/adt.jl",
    "adt/derive.jl",
    "adt/emit.jl",
    "adt/match.jl",
    "adt/print.jl",
    "adt/reflection.jl",
    "adt/traits.jl",
    "adt/types.jl",
    "adt/use.jl",
    "adt/utils.jl",
]
```
