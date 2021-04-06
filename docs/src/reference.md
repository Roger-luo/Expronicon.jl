# API Reference

## Syntax Types

Convenient types for storing analysis results of a given Julia `Expr`, or for creating
certain Julia objects easily. These types define some common syntax one would manipulate
in Julia meta programming.

```@docs
JLFunction
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
Pages = ["analysis.jl"]
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

## Printings

Pretty printing functions.

```@autodocs
Modules = [Expronicon]
Pages = ["printing.jl"]
```

```@docs
Expronicon.Color
```
