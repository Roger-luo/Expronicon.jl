
<a id='API-Reference'></a>

<a id='API-Reference-1'></a>

# API Reference


<a id='Syntax-Types'></a>

<a id='Syntax-Types-1'></a>

## Syntax Types


Convenient types for storing analysis results of a given Julia `Expr`, or for creating certain Julia objects easily. These types define some common syntax one would manipulate in Julia meta programming.

<a id='Expronicon.JLFunction' href='#Expronicon.JLFunction'>#</a>
**`Expronicon.JLFunction`** &mdash; *Type*.



```julia
mutable struct JLFunction <: JLExpr
JLFunction(;kw...)
```

Type describes a Julia function declaration expression.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.

  * `head`: optional, function head, can be `:function`, `:(=)` or `:(->)`.
  * `name`: optional, function name, can has type `Nothing`, `Symbol` or `Expr`, default is `nothing`.
  * `args`: optional, function arguments, a list of `Expr` or `Symbol`.
  * `kwargs`: optional, function keyword arguments, a list of `Expr(:kw, name, default)`.
  * `rettype`: optional, the explicit return type of a function,   can be a `Type`, `Symbol`, `Expr` or just `nothing`, default is `nothing`.
  * `whereparams`: optional, type variables, can be a list of `Type`,   `Expr` or `nothing`, default is `nothing`.
  * `body`: optional, function body, an `Expr`, default is `Expr(:block)`.
  * `line::LineNumberNode`: a `LineNumberNode` to indicate the line information.
  * `doc::String`: the docstring of this definition.

**Example**

Construct a function expression

```julia
julia> JLFunction(;name=:foo, args=[:(x::T)], body= quote 1+1 end, head=:function, whereparams=[:T])
function foo(x::T) where {T}
    #= REPL[25]:1 =#    
    1 + 1    
end
```

Decompose a function expression

```julia
julia> ex = :(function foo(x::T) where {T}
           #= REPL[25]:1 =#    
           1 + 1    
       end)
:(function foo(x::T) where T
      #= REPL[26]:1 =#
      #= REPL[26]:3 =#
      1 + 1
  end)

julia> jl = JLFunction(ex)
function foo(x::T) where {T}
    #= REPL[26]:1 =#    
    #= REPL[26]:3 =#    
    1 + 1    
end
```

Generate `Expr` from `JLFunction`

```julia
julia> codegen_ast(jl)
:(function foo(x::T) where T
      #= REPL[26]:1 =#
      #= REPL[26]:3 =#
      1 + 1
  end)
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L34-L101' class='documenter-source'>source</a><br>

<a id='Expronicon.JLStruct' href='#Expronicon.JLStruct'>#</a>
**`Expronicon.JLStruct`** &mdash; *Type*.



```julia
mutable struct JLStruct <: JLExpr
```

Type describes a Julia struct.

```
JLStruct(;kw...)
```

Create a `JLStruct` instance.

**Available Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.

  * `name::Symbol`: name of the struct, this is the only required keyword argument.
  * `ismutable::Bool`: if the struct definition is mutable.
  * `typevars::Vector{Any}`: type variables of the struct, should be `Symbol` or `Expr`.
  * `supertype`: supertype of the struct definition.
  * `fields::Vector{JLField}`: field definitions of the struct, should be a [`JLField`](api.md#Expronicon.JLField).
  * `constructors::Vector{JLFunction}`: constructors definitions of the struct, should be [`JLFunction`](api.md#Expronicon.JLFunction).
  * `line::LineNumberNode`: a `LineNumberNode` to indicate the definition position for error report etc.
  * `doc::String`: documentation string of the struct.
  * `misc`: other things that happens inside the struct body, by definition this will   just fall through and is equivalent to eval them outside the struct body.

**Example**

Construct a Julia struct.

```julia
julia> JLStruct(;name=:Foo, typevars=[:T], fields=[JLField(;name=:x, type=Int)])
struct Foo{T}
    x::Int64
end
```

Decompose a Julia struct expression

```julia
julia> ex = :(struct Foo{T}
           x::Int64
       end)
:(struct Foo{T}
      #= REPL[31]:2 =#
      x::Int64
  end)

julia> jl = JLStruct(ex)
struct Foo{T}
    #= REPL[31]:2 =#
    x::Int64
end
```

Generate a Julia struct expression

```julia
julia> codegen_ast(jl)
:(struct Foo{T}
      #= REPL[31]:2 =#
      x::Int64
  end)
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L206-L270' class='documenter-source'>source</a><br>

<a id='Expronicon.JLKwStruct' href='#Expronicon.JLKwStruct'>#</a>
**`Expronicon.JLKwStruct`** &mdash; *Type*.



```julia
mutable struct JLKwStruct <: JLExpr
JLKwStruct(;kw...)
```

Type describes a Julia struct that allows keyword definition of defaults. This syntax is similar to [`JLStruct`](api.md#Expronicon.JLStruct) except the the fields are of type [`JLKwField`](api.md#Expronicon.JLKwField).

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.

  * `name::Symbol`: name of the struct, this is the only required keyword argument.
  * `typealias::String`: an alias of the [`JLKwStruct`](api.md#Expronicon.JLKwStruct),   see also the `@option` macro in [Configurations.jl](https://github.com/Roger-luo/Configurations.jl).
  * `ismutable::Bool`: if the struct definition is mutable.
  * `typevars::Vector{Any}`: type variables of the struct, should be `Symbol` or `Expr`.
  * `supertype`: supertype of the struct definition.
  * `fields::Vector{JLField}`: field definitions of the struct, should be a [`JLField`](api.md#Expronicon.JLField).
  * `constructors::Vector{JLFunction}`: constructors definitions of the struct, should be [`JLFunction`](api.md#Expronicon.JLFunction).
  * `line::LineNumberNode`: a `LineNumberNode` to indicate the definition position for error report etc.
  * `doc::String`: documentation string of the struct.
  * `misc`: other things that happens inside the struct body, by definition this will   just fall through and is equivalent to eval them outside the struct body.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L291-L317' class='documenter-source'>source</a><br>

<a id='Expronicon.JLIfElse' href='#Expronicon.JLIfElse'>#</a>
**`Expronicon.JLIfElse`** &mdash; *Type*.



```julia
JLIfElse <: JLExpr
JLIfElse(;kw...)
```

`JLIfElse` describes a Julia `if ... elseif ... else ... end` expression. It allows one to easily construct such expression by inserting condition and code block via a map.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

  * `conds::Vector{Any}`: expression for the conditions.
  * `stmts::Vector{Any}`: expression for the statements for corresponding condition.
  * `otherwise`: the `else` body.

**Example**

**Construct JLIfElse object**

One can construct an `ifelse` as following

```julia
julia> jl = JLIfElse()
nothing

julia> jl[:(foo(x))] = :(x = 1 + 1)
:(x = 1 + 1)

julia> jl[:(goo(x))] = :(y = 1 + 2)
:(y = 1 + 2)

julia> jl.otherwise = :(error("abc"))
:(error("abc"))

julia> jl
if foo(x)
    x = 1 + 1
elseif goo(x)
    y = 1 + 2
else
    error("abc")
end
```

**Generate the Julia `Expr` object**

to generate the corresponding `Expr` object, one can call [`codegen_ast`](api.md#Expronicon.codegen_ast-Tuple{Any}).

```julia
julia> codegen_ast(jl)
:(if foo(x)
      x = 1 + 1
  elseif goo(x)
      y = 1 + 2
  else
      error("abc")
  end)
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L338-L396' class='documenter-source'>source</a><br>

<a id='Expronicon.JLMatch' href='#Expronicon.JLMatch'>#</a>
**`Expronicon.JLMatch`** &mdash; *Type*.



```julia
JLMatch <: JLExpr
```

`JLMatch` describes a Julia pattern match expression defined by [`MLStyle`](https://github.com/thautwarm/MLStyle.jl). It allows one to construct such expression by simply assign each code block to the corresponding pattern expression.

!!! tip
    `JLMatch` is not available in ExproniconLite since it depends on MLStyle's pattern matching functionality.


**Example**

One can construct a `MLStyle` pattern matching expression easily by assigning the corresponding pattern and its result to the `map` field.

```julia
julia> jl = JLMatch(:x)
#= line 0 =#
nothing

julia> jl = JLMatch(:x)
#= line 0 =#
nothing

julia> jl.map[1] = true
true

julia> jl.map[2] = :(sin(x))
:(sin(x))

julia> jl
#= line 0 =#
@match x begin
    1 => true
    2 => sin(x)
    _ =>     nothing
end
```

to generate the corresponding Julia `Expr` object, one can call [`codegen_ast`](api.md#Expronicon.codegen_ast-Tuple{Any}).

```julia
julia> codegen_ast(jl)
:(let
      true
      var"##return#263" = nothing
      var"##265" = x
      if var"##265" isa Int64
          #= line 0 =#
          if var"##265" === 1
              var"##return#263" = let
                      true
                  end
              #= unused:1 =# @goto var"####final#264#266"
          end
          #= line 0 =#
          if var"##265" === 2
              var"##return#263" = let
                      sin(x)
                  end
              #= unused:1 =# @goto var"####final#264#266"
          end
      end
      #= line 0 =#
      begin
          var"##return#263" = let
                  nothing
              end
          #= unused:1 =# @goto var"####final#264#266"
      end
      (error)("matching non-exhaustive, at #= line 0 =#")
      #= unused:1 =# @label var"####final#264#266"
      var"##return#263"
  end)
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/match.jl#L3-L81' class='documenter-source'>source</a><br>

<a id='Expronicon.JLFor' href='#Expronicon.JLFor'>#</a>
**`Expronicon.JLFor`** &mdash; *Type*.



```julia
JLFor <: JLExpr
```

Syntax type for Julia for loop.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L432-L436' class='documenter-source'>source</a><br>

<a id='Expronicon.JLField' href='#Expronicon.JLField'>#</a>
**`Expronicon.JLField`** &mdash; *Type*.



```julia
mutable struct JLField <: JLExpr
JLField(;kw...)
```

Type describes a Julia field in a Julia struct.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.

  * `name::Symbol`: the name of the field.
  * `type`: the type of the field.
  * `isconst`: if the field is annotated with `const`.
  * `line::LineNumberNode`: a `LineNumberNode` to indicate the line information.
  * `doc::String`: the docstring of this definition.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L139-L156' class='documenter-source'>source</a><br>

<a id='Expronicon.JLKwField' href='#Expronicon.JLKwField'>#</a>
**`Expronicon.JLKwField`** &mdash; *Type*.



```julia
mutable struct JLKwField <: JLExpr
```

Type describes a Julia field that can have a default value in a Julia struct.

```
JLKwField(;kw...)
```

Create a `JLKwField` instance.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.

  * `name::Symbol`: the name of the field.
  * `type`: the type of the field.
  * `isconst`: if the field is annotated with `const`.
  * `default`: default value of the field, default is [`no_default`](api.md#Expronicon.no_default).
  * `line::LineNumberNode`: a `LineNumberNode` to indicate the line information.
  * `doc::String`: the docstring of this definition.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L170-L191' class='documenter-source'>source</a><br>

<a id='Expronicon.NoDefault' href='#Expronicon.NoDefault'>#</a>
**`Expronicon.NoDefault`** &mdash; *Type*.



```julia
NoDefault
```

Type describes a field should have no default value.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L11-L15' class='documenter-source'>source</a><br>

<a id='Expronicon.no_default' href='#Expronicon.no_default'>#</a>
**`Expronicon.no_default`** &mdash; *Constant*.



```julia
const no_default = NoDefault()
```

Constant instance for [`NoDefault`](api.md#Expronicon.NoDefault) that describes a field should have no default value.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L18-L23' class='documenter-source'>source</a><br>

<a id='Expronicon.JLExpr' href='#Expronicon.JLExpr'>#</a>
**`Expronicon.JLExpr`** &mdash; *Type*.



```julia
abstract type JLExpr end
```

Abstract type for Julia syntax type.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/types.jl#L27-L31' class='documenter-source'>source</a><br>


<a id='Analysis'></a>

<a id='Analysis-1'></a>

## Analysis


Functions for analysing a given Julia `Expr`, e.g splitting Julia function/struct definitions etc.


<a id='Transform'></a>

<a id='Transform-1'></a>

## Transform


Some common transformations for Julia `Expr`, these functions takes an `Expr` and returns an `Expr`.

<a id='Expronicon.Substitute' href='#Expronicon.Substitute'>#</a>
**`Expronicon.Substitute`** &mdash; *Type*.



```julia
Substitute(condition) -> substitute(f(expr), expr)
```

Returns a function that substitutes `expr` with `f(expr)` if `condition(expr)` is true. Applied recursively to all sub-expressions.

**Example**

```julia
julia> sub = Substitute() do expr
           expr isa Symbol && expr in [:x] && return true
           return false
       end;

julia> sub(_->1, :(x + y))
:(1 + y)
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L398-L416' class='documenter-source'>source</a><br>

<a id='Expronicon.alias_gensym-Tuple{Any}' href='#Expronicon.alias_gensym-Tuple{Any}'>#</a>
**`Expronicon.alias_gensym`** &mdash; *Method*.



```julia
alias_gensym(ex)
```

Replace gensym with `<name>_<id>`.

!!! note
    Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).



<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L279-L286' class='documenter-source'>source</a><br>

<a id='Expronicon.annotations_only-Tuple{Any}' href='#Expronicon.annotations_only-Tuple{Any}'>#</a>
**`Expronicon.annotations_only`** &mdash; *Method*.



```julia
annotations_only(ex)
```

Return type annotations only. See also [`name_only`](api.md#Expronicon.name_only-Tuple{Any}).


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L82-L86' class='documenter-source'>source</a><br>

<a id='Expronicon.eval_interp-Tuple{Module, Any}' href='#Expronicon.eval_interp-Tuple{Module, Any}'>#</a>
**`Expronicon.eval_interp`** &mdash; *Method*.



```julia
eval_interp(m::Module, ex)
```

evaluate the interpolation operator in `ex` inside given module `m`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L2-L6' class='documenter-source'>source</a><br>

<a id='Expronicon.eval_literal-Tuple{Module, Any}' href='#Expronicon.eval_literal-Tuple{Module, Any}'>#</a>
**`Expronicon.eval_literal`** &mdash; *Method*.



```julia
eval_literal(m::Module, ex)
```

Evaluate the literal values and insert them back to the expression. The literal value can be checked via `is_literal`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L20-L25' class='documenter-source'>source</a><br>

<a id='Expronicon.expr_map-Tuple{Any, Vararg{Any}}' href='#Expronicon.expr_map-Tuple{Any, Vararg{Any}}'>#</a>
**`Expronicon.expr_map`** &mdash; *Method*.



```julia
expr_map(f, c...)
```

Similar to `Base.map`, but expects `f` to return an expression, and will concatenate these expression as a `Expr(:block, ...)` expression.

**Example**

```julia
julia> expr_map(1:10, 2:11) do i,j
           :(1 + $i + $j)
       end
quote
    1 + 1 + 2
    1 + 2 + 3
    1 + 3 + 4
    1 + 4 + 5
    1 + 5 + 6
    1 + 6 + 7
    1 + 7 + 8
    1 + 8 + 9
    1 + 9 + 10
    1 + 10 + 11
end
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L341-L367' class='documenter-source'>source</a><br>

<a id='Expronicon.flatten_blocks-Tuple{Any}' href='#Expronicon.flatten_blocks-Tuple{Any}'>#</a>
**`Expronicon.flatten_blocks`** &mdash; *Method*.



```julia
flatten_blocks(ex)
```

Remove hierarchical expression blocks.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L171-L175' class='documenter-source'>source</a><br>

<a id='Expronicon.name_only-Tuple{Any}' href='#Expronicon.name_only-Tuple{Any}'>#</a>
**`Expronicon.name_only`** &mdash; *Method*.



```julia
name_only(ex)
```

Remove everything else leaving just names, currently supports function calls, type with type variables, subtype operator `<:` and type annotation `::`.

**Example**

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


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L47-L71' class='documenter-source'>source</a><br>

<a id='Expronicon.nexprs-Tuple{Any, Int64}' href='#Expronicon.nexprs-Tuple{Any, Int64}'>#</a>
**`Expronicon.nexprs`** &mdash; *Method*.



```julia
nexprs(f, n::Int)
```

Create `n` similar expressions by evaluating `f`.

**Example**

```julia
julia> nexprs(5) do k
           :(1 + $k)
       end
quote
    1 + 1
    1 + 2
    1 + 3
    1 + 4
    1 + 5
end
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L376-L395' class='documenter-source'>source</a><br>

<a id='Expronicon.prettify-Tuple{Any}' href='#Expronicon.prettify-Tuple{Any}'>#</a>
**`Expronicon.prettify`** &mdash; *Method*.



```julia
prettify(ex; kw...)
```

Prettify given expression, remove all `LineNumberNode` and extra code blocks.

**Options (Kwargs)**

All the options are `true` by default.

  * `rm_lineinfo`: remove `LineNumberNode`.
  * `flatten_blocks`: flatten `begin ... end` code blocks.
  * `rm_nothing`: remove `nothing` in the `begin ... end`.
  * `preserve_last_nothing`: preserve the last `nothing` in the `begin ... end`.
  * `rm_single_block`: remove single `begin ... end`.
  * `alias_gensym`: replace `##<name>#<num>` with `<name>_<id>`.
  * `renumber_gensym`: renumber the gensym id.

!!! tips
    the `LineNumberNode` inside macro calls won't be removed since the `macrocall` expression requires a `LineNumberNode`. See also [issues/#9](https://github.com/Roger-luo/Expronicon.jl/issues/9).



<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L123-L146' class='documenter-source'>source</a><br>

<a id='Expronicon.renumber_gensym-Tuple{Any}' href='#Expronicon.renumber_gensym-Tuple{Any}'>#</a>
**`Expronicon.renumber_gensym`** &mdash; *Method*.



```julia
renumber_gensym(ex)
```

Re-number gensym with counter from this expression. Produce a deterministic gensym name for testing etc. See also: [`alias_gensym`](api.md#Expronicon.alias_gensym-Tuple{Any})


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L307-L313' class='documenter-source'>source</a><br>

<a id='Expronicon.rm_annotations-Tuple{Any}' href='#Expronicon.rm_annotations-Tuple{Any}'>#</a>
**`Expronicon.rm_annotations`** &mdash; *Method*.



```julia
rm_annotations(x)
```

Remove type annotation of given expression.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L259-L263' class='documenter-source'>source</a><br>

<a id='Expronicon.rm_lineinfo-Tuple{Any}' href='#Expronicon.rm_lineinfo-Tuple{Any}'>#</a>
**`Expronicon.rm_lineinfo`** &mdash; *Method*.



```julia
rm_lineinfo(ex)
```

Remove `LineNumberNode` in a given expression.

!!! tips
    the `LineNumberNode` inside macro calls won't be removed since the `macrocall` expression requires a `LineNumberNode`. See also [issues/#9](https://github.com/Roger-luo/Expronicon.jl/issues/9).



<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L94-L104' class='documenter-source'>source</a><br>

<a id='Expronicon.rm_nothing-Tuple{Any}' href='#Expronicon.rm_nothing-Tuple{Any}'>#</a>
**`Expronicon.rm_nothing`** &mdash; *Method*.



```julia
rm_nothing(ex)
```

Remove the constant value `nothing` in given expression `ex`.

**Keyword Arguments**

  * `preserve_last_nothing`: if `true`, the last `nothing`   will be preserved.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L206-L215' class='documenter-source'>source</a><br>

<a id='Expronicon.substitute-Tuple{Expr, Pair}' href='#Expronicon.substitute-Tuple{Expr, Pair}'>#</a>
**`Expronicon.substitute`** &mdash; *Method*.



```julia
substitute(ex::Expr, old=>new)
```

Substitute the old symbol `old` with `new`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/transform.jl#L34-L38' class='documenter-source'>source</a><br>


<a id='CodeGen'></a>

<a id='CodeGen-1'></a>

## CodeGen


Code generators, functions that generates Julia `Expr` from given arguments, `Expronicon` types. 

<a id='Expronicon.codegen_ast-Tuple{Any}' href='#Expronicon.codegen_ast-Tuple{Any}'>#</a>
**`Expronicon.codegen_ast`** &mdash; *Method*.



```julia
codegen_ast(def)
```

Generate Julia AST object `Expr` from a given syntax type.

**Example**

One can generate the Julia AST object from a `JLKwStruct` syntax type.

```julia
julia> def = @expr JLKwStruct struct Foo{N, T}
                  x::T = 1
              end
#= kw =# struct Foo{N, T}
    #= REPL[19]:2 =#
    x::T = 1
end

julia> codegen_ast(def)|>rm_lineinfo
quote
    struct Foo{N, T}
        x::T
    end
    begin
        function Foo{N, T}(; x = 1) where {N, T}
            Foo{N, T}(x)
        end
        function Foo{N}(; x::T = 1) where {N, T}
            Foo{N, T}(x)
        end
    end
end
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L2-L36' class='documenter-source'>source</a><br>

<a id='Expronicon.codegen_ast_fields-Tuple{Any}' href='#Expronicon.codegen_ast_fields-Tuple{Any}'>#</a>
**`Expronicon.codegen_ast_fields`** &mdash; *Method*.



```julia
codegen_ast_fields(fields; just_name::Bool=true)
```

Generate a list of Julia AST object for each field, only generate a list of field names by default, option `just_name` can be turned off to call [`codegen_ast`](api.md#Expronicon.codegen_ast-Tuple{Any}) on each field object.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L240-L246' class='documenter-source'>source</a><br>

<a id='Expronicon.codegen_ast_kwfn' href='#Expronicon.codegen_ast_kwfn'>#</a>
**`Expronicon.codegen_ast_kwfn`** &mdash; *Function*.



```julia
codegen_ast_kwfn(def[, name = nothing])
```

Generate the keyword function from a Julia struct definition.

**Example**

```julia
julia> def = @expr JLKwStruct struct Foo{N, T}
                  x::T = 1
              end
#= kw =# struct Foo{N, T}
    #= REPL[19]:2 =#
    x::T = 1
end

julia> codegen_ast_kwfn(def)|>prettify
quote
    function Foo{N, T}(; x = 1) where {N, T}
        Foo{N, T}(x)
    end
    function Foo{N}(; x::T = 1) where {N, T}
        Foo{N, T}(x)
    end
end

julia> def = @expr JLKwStruct struct Foo
                  x::Int = 1
              end
#= kw =# struct Foo
    #= REPL[23]:2 =#
    x::Int = 1
end

julia> codegen_ast_kwfn(def)|>prettify
quote
    function Foo(; x = 1)
        Foo(x)
    end
    nothing
end
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L112-L154' class='documenter-source'>source</a><br>

<a id='Expronicon.codegen_ast_kwfn_infer' href='#Expronicon.codegen_ast_kwfn_infer'>#</a>
**`Expronicon.codegen_ast_kwfn_infer`** &mdash; *Function*.



```julia
codegen_ast_kwfn_infer(def, name = nothing)
```

Generate the keyword function that infers the type.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L200-L204' class='documenter-source'>source</a><br>

<a id='Expronicon.codegen_ast_kwfn_plain' href='#Expronicon.codegen_ast_kwfn_plain'>#</a>
**`Expronicon.codegen_ast_kwfn_plain`** &mdash; *Function*.



```julia
codegen_ast_kwfn_plain(def[, name = nothing])
```

Generate the plain keyword function that does not infer type variables. So that one can use the type conversions defined by constructors.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L162-L167' class='documenter-source'>source</a><br>

<a id='Expronicon.codegen_ast_struct-Tuple{Any}' href='#Expronicon.codegen_ast_struct-Tuple{Any}'>#</a>
**`Expronicon.codegen_ast_struct`** &mdash; *Method*.



```julia
codegen_ast_struct(def)
```

Generate pure Julia struct `Expr` from struct definition. This is equivalent to `codegen_ast` for `JLStruct`. See also [`codegen_ast`](api.md#Expronicon.codegen_ast-Tuple{Any}).

**Example**

```julia
julia> def = JLKwStruct(:(struct Foo
           x::Int=1
           
           Foo(x::Int) = new(x)
       end))
struct Foo
    x::Int = 1
end

julia> codegen_ast_struct(def)
:(struct Foo
      #= REPL[21]:2 =#
      x::Int
      Foo(x::Int) = begin
              #= REPL[21]:4 =#
              new(x)
          end
  end)
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L405-L433' class='documenter-source'>source</a><br>

<a id='Expronicon.codegen_ast_struct_body-Tuple{Any}' href='#Expronicon.codegen_ast_struct_body-Tuple{Any}'>#</a>
**`Expronicon.codegen_ast_struct_body`** &mdash; *Method*.



```julia
codegen_ast_struct_body(def)
```

Generate the struct body.

**Example**

```julia
julia> def = JLStruct(:(struct Foo
           x::Int
           
           Foo(x::Int) = new(x)
       end))
struct Foo
    x::Int
end

julia> codegen_ast_struct_body(def)
quote
    #= REPL[15]:2 =#
    x::Int
    Foo(x::Int) = begin
            #= REPL[15]:4 =#
            new(x)
        end
end
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L360-L387' class='documenter-source'>source</a><br>

<a id='Expronicon.codegen_ast_struct_head-Tuple{Any}' href='#Expronicon.codegen_ast_struct_head-Tuple{Any}'>#</a>
**`Expronicon.codegen_ast_struct_head`** &mdash; *Method*.



```julia
codegen_ast_struct_head(def)
```

Generate the struct head.

**Example**

```julia
julia> using Expronicon

julia> def = JLStruct(:(struct Foo{T} end))
struct Foo{T}
end

julia> codegen_ast_struct_head(def)
:(Foo{T})

julia> def = JLStruct(:(struct Foo{T} <: AbstractArray end))
struct Foo{T} <: AbstractArray
end

julia> codegen_ast_struct_head(def)
:(Foo{T} <: AbstractArray)
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L323-L347' class='documenter-source'>source</a><br>

<a id='Expronicon.struct_name_plain-Tuple{Any}' href='#Expronicon.struct_name_plain-Tuple{Any}'>#</a>
**`Expronicon.struct_name_plain`** &mdash; *Method*.



```julia
struct_name_plain(def)
```

Plain constructor name. See also [`struct_name_without_inferable`](api.md#Expronicon.struct_name_without_inferable-Tuple{Any}).

**Example**

```julia
julia> def = @expr JLKwStruct struct Foo{N, Inferable}
    x::Inferable = 1
end

julia> struct_name_plain(def)
:(Foo{N, Inferable})
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L260-L275' class='documenter-source'>source</a><br>

<a id='Expronicon.struct_name_without_inferable-Tuple{Any}' href='#Expronicon.struct_name_without_inferable-Tuple{Any}'>#</a>
**`Expronicon.struct_name_without_inferable`** &mdash; *Method*.



```julia
struct_name_without_inferable(def; leading_inferable::Bool=true)
```

Constructor name that assume some of the type variables is inferred. See also [`struct_name_plain`](api.md#Expronicon.struct_name_plain-Tuple{Any}). The kwarg `leading_inferable` can be used to configure whether to preserve the leading inferable type variables, the default is `true` to be consistent with the default julia constructors.

**Example**

```julia
julia> def = @expr JLKwStruct struct Foo{N, Inferable}
    x::Inferable = 1
end

julia> struct_name_without_inferable(def)
:(Foo{N})

julia> def = @expr JLKwStruct struct Foo{Inferable, NotInferable}
    x::Inferable
end

julia> struct_name_without_inferable(def; leading_inferable=true)
:(Foo{Inferable, NotInferable})

julia> struct_name_without_inferable(def; leading_inferable=false)
:(Foo{NotInferable})
```


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L281-L310' class='documenter-source'>source</a><br>

<a id='Expronicon.xcall-Tuple{Any, Vararg{Any}}' href='#Expronicon.xcall-Tuple{Any, Vararg{Any}}'>#</a>
**`Expronicon.xcall`** &mdash; *Method*.



```julia
xcall(name, args...; kw...)
```

Create a function call to `name`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L476-L480' class='documenter-source'>source</a><br>

<a id='Expronicon.xcall-Tuple{Module, Symbol, Vararg{Any}}' href='#Expronicon.xcall-Tuple{Module, Symbol, Vararg{Any}}'>#</a>
**`Expronicon.xcall`** &mdash; *Method*.



```julia
xcall(m::Module, name::Symbol, args...; kw...)
```

Create a function call to `GlobalRef(m, name)`.

!!! tip
    due to [Revise/#616](https://github.com/timholy/Revise.jl/issues/616), to make your macro work with Revise, we use the dot expression `Expr(:., <module>, QuoteNode(<name>))` instead of `GlobalRef` here.



<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L490-L500' class='documenter-source'>source</a><br>

<a id='Expronicon.xfirst-Tuple{Any}' href='#Expronicon.xfirst-Tuple{Any}'>#</a>
**`Expronicon.xfirst`** &mdash; *Method*.



```julia
xfirst(collection)
```

Create a function call expression to `Base.first`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L522-L526' class='documenter-source'>source</a><br>

<a id='Expronicon.xgetindex-Tuple{Any, Vararg{Any}}' href='#Expronicon.xgetindex-Tuple{Any, Vararg{Any}}'>#</a>
**`Expronicon.xgetindex`** &mdash; *Method*.



```julia
xgetindex(collection, key...)
```

Create a function call expression to `Base.getindex`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L506-L510' class='documenter-source'>source</a><br>

<a id='Expronicon.xiterate-Tuple{Any, Any}' href='#Expronicon.xiterate-Tuple{Any, Any}'>#</a>
**`Expronicon.xiterate`** &mdash; *Method*.



```julia
xiterate(it, st)
```

Create a function call expression to `Base.iterate`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L571-L575' class='documenter-source'>source</a><br>

<a id='Expronicon.xiterate-Tuple{Any}' href='#Expronicon.xiterate-Tuple{Any}'>#</a>
**`Expronicon.xiterate`** &mdash; *Method*.



```julia
xiterate(it)
```

Create a function call expression to `Base.iterate`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L564-L568' class='documenter-source'>source</a><br>

<a id='Expronicon.xlast-Tuple{Any}' href='#Expronicon.xlast-Tuple{Any}'>#</a>
**`Expronicon.xlast`** &mdash; *Method*.



```julia
xlast(collection)
```

Create a function call expression to `Base.last`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L529-L533' class='documenter-source'>source</a><br>

<a id='Expronicon.xmap-Tuple{Any, Vararg{Any}}' href='#Expronicon.xmap-Tuple{Any, Vararg{Any}}'>#</a>
**`Expronicon.xmap`** &mdash; *Method*.



```julia
xmap(f, xs...)
```

Create a function call expression to `Base.map`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L550-L554' class='documenter-source'>source</a><br>

<a id='Expronicon.xmapreduce-Tuple{Any, Any, Vararg{Any}}' href='#Expronicon.xmapreduce-Tuple{Any, Any, Vararg{Any}}'>#</a>
**`Expronicon.xmapreduce`** &mdash; *Method*.



```julia
xmapreduce(f, op, xs...)
```

Create a function call expression to `Base.mapreduce`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L557-L561' class='documenter-source'>source</a><br>

<a id='Expronicon.xnamedtuple-Tuple{}' href='#Expronicon.xnamedtuple-Tuple{}'>#</a>
**`Expronicon.xnamedtuple`** &mdash; *Method*.



```julia
xnamedtuple(;kw...)
```

Create a `NamedTuple` expression.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L463-L467' class='documenter-source'>source</a><br>

<a id='Expronicon.xprint-Tuple' href='#Expronicon.xprint-Tuple'>#</a>
**`Expronicon.xprint`** &mdash; *Method*.



```julia
xprint(xs...)
```

Create a function call expression to `Base.print`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L536-L540' class='documenter-source'>source</a><br>

<a id='Expronicon.xprintln-Tuple' href='#Expronicon.xprintln-Tuple'>#</a>
**`Expronicon.xprintln`** &mdash; *Method*.



```julia
xprintln(xs...)
```

Create a function call expression to `Base.println`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L543-L547' class='documenter-source'>source</a><br>

<a id='Expronicon.xpush-Tuple{Any, Vararg{Any}}' href='#Expronicon.xpush-Tuple{Any, Vararg{Any}}'>#</a>
**`Expronicon.xpush`** &mdash; *Method*.



```julia
xpush(collection, items...)
```

Create a function call expression to `Base.push!`.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L513-L517' class='documenter-source'>source</a><br>

<a id='Expronicon.xtuple-Tuple' href='#Expronicon.xtuple-Tuple'>#</a>
**`Expronicon.xtuple`** &mdash; *Method*.



```julia
xtuple(xs...)
```

Create a `Tuple` expression.


<a target='_blank' href='https://github.com/Roger-luo/Expronicon.jl/blob/a5382945571811e3fab9f4bf7a7bdf09c2101602/src/codegen.jl#L456-L460' class='documenter-source'>source</a><br>


<a id='Printings'></a>

<a id='Printings-1'></a>

## Printings


Pretty printing functions.


<a id='Algebra-Data-Type'></a>

<a id='Algebra-Data-Type-1'></a>

## Algebra Data Type


Algebra data type

