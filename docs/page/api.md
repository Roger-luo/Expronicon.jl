---
---

# API Reference {#API-Reference}

## Syntax Types {#Syntax-Types}

Convenient types for storing analysis results of a given Julia `Expr`, or for creating certain Julia objects easily. These types define some common syntax one would manipulate in Julia meta programming.
<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLFunction' href='#Expronicon.JLFunction'><span class="jlbinding">Expronicon.JLFunction</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
mutable struct JLFunction <: JLExpr
JLFunction(;kw...)
```


Type describes a Julia function declaration expression.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.
- `head`: optional, function head, can be `:function`, `:(=)` or `:(->)`.
    
- `name`: optional, function name, can has type `Nothing`, `Symbol` or `Expr`, default is `nothing`.
    
- `args`: optional, function arguments, a list of `Expr` or `Symbol`.
    
- `kwargs`: optional, function keyword arguments, a list of `Expr(:kw, name, default)`.
    
- `rettype`: optional, the explicit return type of a function,   can be a `Type`, `Symbol`, `Expr` or just `nothing`, default is `nothing`.
    
- `generated`: optional, if this is a generated function.
    
- `whereparams`: optional, type variables, can be a list of `Type`,   `Expr` or `nothing`, default is `nothing`.
    
- `body`: optional, function body, an `Expr`, default is `Expr(:block)`.
    
- `line::LineNumberNode`: a `LineNumberNode` to indicate the line information.
    
- `doc::String`: the docstring of this definition.
    

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L58-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLCall' href='#Expronicon.JLCall'><span class="jlbinding">Expronicon.JLCall</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
JLCall(func, args::Vector, kwargs::Maybe{Vector})
JLCall(; func, args=[], kwargs=nothing)
```


Represents a Julia function call expression.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.
- `func`: the function being called
    
- `args`: optional, function arguments, a list of `Expr` or `Symbol`.
    
- `kwargs`: optional, function keyword arguments, a list of `Expr(:kw, name, default)`.
    


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L34-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLStruct' href='#Expronicon.JLStruct'><span class="jlbinding">Expronicon.JLStruct</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
mutable struct JLStruct <: JLExpr
```


Type describes a Julia struct.

```julia
JLStruct(;kw...)
```


Create a `JLStruct` instance.

**Available Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.
- `name::Symbol`: name of the struct, this is the only required keyword argument.
    
- `ismutable::Bool`: if the struct definition is mutable.
    
- `typevars::Vector{Any}`: type variables of the struct, should be `Symbol` or `Expr`.
    
- `supertype`: supertype of the struct definition.
    
- `fields::Vector{JLField}`: field definitions of the struct, should be a [`JLField`](/api#Expronicon.JLField).
    
- `constructors::Vector{JLFunction}`: constructors definitions of the struct, should be [`JLFunction`](/api#Expronicon.JLFunction).
    
- `line::LineNumberNode`: a `LineNumberNode` to indicate the definition position for error report etc.
    
- `doc::String`: documentation string of the struct.
    
- `misc`: other things that happens inside the struct body, by definition this will   just fall through and is equivalent to eval them outside the struct body.
    

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L235-L299" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLKwStruct' href='#Expronicon.JLKwStruct'><span class="jlbinding">Expronicon.JLKwStruct</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
mutable struct JLKwStruct <: JLExpr
JLKwStruct(;kw...)
```


Type describes a Julia struct that allows keyword definition of defaults. This syntax is similar to [`JLStruct`](/api#Expronicon.JLStruct) except the the fields are of type [`JLKwField`](/api#Expronicon.JLKwField).

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.
- `name::Symbol`: name of the struct, this is the only required keyword argument.
    
- `typealias::String`: an alias of the [`JLKwStruct`](/api#Expronicon.JLKwStruct),   see also the `@option` macro in [Configurations.jl](https://github.com/Roger-luo/Configurations.jl).
    
- `ismutable::Bool`: if the struct definition is mutable.
    
- `typevars::Vector{Any}`: type variables of the struct, should be `Symbol` or `Expr`.
    
- `supertype`: supertype of the struct definition.
    
- `fields::Vector{JLField}`: field definitions of the struct, should be a [`JLField`](/api#Expronicon.JLField).
    
- `constructors::Vector{JLFunction}`: constructors definitions of the struct, should be [`JLFunction`](/api#Expronicon.JLFunction).
    
- `line::LineNumberNode`: a `LineNumberNode` to indicate the definition position for error report etc.
    
- `doc::String`: documentation string of the struct.
    
- `misc`: other things that happens inside the struct body, by definition this will   just fall through and is equivalent to eval them outside the struct body.
    


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L320-L346" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLIfElse' href='#Expronicon.JLIfElse'><span class="jlbinding">Expronicon.JLIfElse</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
JLIfElse <: JLExpr
JLIfElse(;kw...)
```


`JLIfElse` describes a Julia `if ... elseif ... else ... end` expression. It allows one to easily construct such expression by inserting condition and code block via a map.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.
- `conds::Vector{Any}`: expression for the conditions.
    
- `stmts::Vector{Any}`: expression for the statements for corresponding condition.
    
- `otherwise`: the `else` body.
    

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

to generate the corresponding `Expr` object, one can call [`codegen_ast`](/api#Expronicon.codegen_ast-Tuple{Any}).

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L367-L425" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLMatch' href='#Expronicon.JLMatch'><span class="jlbinding">Expronicon.JLMatch</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
JLMatch <: JLExpr
```


`JLMatch` describes a Julia pattern match expression defined by [`MLStyle`](https://github.com/thautwarm/MLStyle.jl). It allows one to construct such expression by simply assign each code block to the corresponding pattern expression.

::: tip Tip

`JLMatch` is not available in ExproniconLite since it depends on MLStyle's pattern matching functionality.

:::

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


to generate the corresponding Julia `Expr` object, one can call [`codegen_ast`](/api#Expronicon.codegen_ast-Tuple{Any}).

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/match.jl#L3-L81" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLFor' href='#Expronicon.JLFor'><span class="jlbinding">Expronicon.JLFor</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
JLFor <: JLExpr
```


Syntax type for Julia for loop.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L461-L465" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLField' href='#Expronicon.JLField'><span class="jlbinding">Expronicon.JLField</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
mutable struct JLField <: JLExpr
JLField(;kw...)
```


Type describes a Julia field in a Julia struct.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.
- `name::Symbol`: the name of the field.
    
- `type`: the type of the field.
    
- `isconst`: if the field is annotated with `const`.
    
- `line::LineNumberNode`: a `LineNumberNode` to indicate the line information.
    
- `doc::String`: the docstring of this definition.
    


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L168-L185" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLKwField' href='#Expronicon.JLKwField'><span class="jlbinding">Expronicon.JLKwField</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
mutable struct JLKwField <: JLExpr
```


Type describes a Julia field that can have a default value in a Julia struct.

```julia
JLKwField(;kw...)
```


Create a `JLKwField` instance.

**Fields and Keyword Arguments**

All the following fields are valid as keyword arguments `kw` in the constructor, and can be access via `<object>.<field>`.

The only required keyword argument for the constructor is `name`, the rest are all optional.
- `name::Symbol`: the name of the field.
    
- `type`: the type of the field.
    
- `isconst`: if the field is annotated with `const`.
    
- `default`: default value of the field, default is [`no_default`](/api#Expronicon.no_default).
    
- `line::LineNumberNode`: a `LineNumberNode` to indicate the line information.
    
- `doc::String`: the docstring of this definition.
    


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L199-L220" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.NoDefault' href='#Expronicon.NoDefault'><span class="jlbinding">Expronicon.NoDefault</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
NoDefault
```


Type describes a field should have no default value.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L11-L15" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.no_default' href='#Expronicon.no_default'><span class="jlbinding">Expronicon.no_default</span></a> <Badge type="info" class="jlObjectType jlConstant" text="Constant" /></summary>



```julia
const no_default = NoDefault()
```


Constant instance for [`NoDefault`](/api#Expronicon.NoDefault) that describes a field should have no default value.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L18-L23" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLExpr' href='#Expronicon.JLExpr'><span class="jlbinding">Expronicon.JLExpr</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
abstract type JLExpr end
```


Abstract type for Julia syntax type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/types.jl#L27-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Analysis {#Analysis}

Functions for analysing a given Julia `Expr`, e.g splitting Julia function/struct definitions etc.
<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.has_kwfn_constructor' href='#Expronicon.has_kwfn_constructor'><span class="jlbinding">Expronicon.has_kwfn_constructor</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
has_kwfn_constructor(def[, name = struct_name_plain(def)])
```


Check if the struct definition contains keyword function constructor of `name`. The constructor name to check by default is the plain constructor which does not infer any type variables and requires user to input all type variables. See also [`struct_name_plain`](/api#Expronicon.struct_name_plain-Tuple{Any}).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L73-L80" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.has_plain_constructor' href='#Expronicon.has_plain_constructor'><span class="jlbinding">Expronicon.has_plain_constructor</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
has_plain_constructor(def, name = struct_name_plain(def))
```


Check if the struct definition contains the plain constructor of `name`. By default the name is the inferable name [`struct_name_plain`](/api#Expronicon.struct_name_plain-Tuple{Any}).

**Example**

```julia
def = @expr JLKwStruct struct Foo{T, N}
    x::Int
    y::N

    Foo{T, N}(x, y) where {T, N} = new{T, N}(x, y)
end

has_plain_constructor(def) # true

def = @expr JLKwStruct struct Foo{T, N}
    x::T
    y::N

    Foo(x, y) = new{typeof(x), typeof(y)}(x, y)
end

has_plain_constructor(def) # false
```


the arguments must have no type annotations.

```julia
def = @expr JLKwStruct struct Foo{T, N}
    x::T
    y::N

    Foo{T, N}(x::T, y::N) where {T, N} = new{T, N}(x, y)
end

has_plain_constructor(def) # false
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L87-L127" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.has_symbol-Tuple{Any, Symbol}' href='#Expronicon.has_symbol-Tuple{Any, Symbol}'><span class="jlbinding">Expronicon.has_symbol</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
has_symbol(ex, name::Symbol)
```


Check if `ex` contains symbol `name`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L62-L66" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_datatype_expr-Tuple{Any}' href='#Expronicon.is_datatype_expr-Tuple{Any}'><span class="jlbinding">Expronicon.is_datatype_expr</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_datatype_expr(ex)
```


Check if `ex` is an expression for a concrete `DataType`, e.g `where` is not allowed in the expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L265-L270" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_field-Tuple{Any}' href='#Expronicon.is_field-Tuple{Any}'><span class="jlbinding">Expronicon.is_field</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_field(ex)
```


Check if `ex` is a valid field expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L237-L241" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_field_default-Tuple{Any}' href='#Expronicon.is_field_default-Tuple{Any}'><span class="jlbinding">Expronicon.is_field_default</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_field_default(ex)
```


Check if `ex` is a `<field expr> = <default expr>` expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L252-L256" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_for-Tuple{Any}' href='#Expronicon.is_for-Tuple{Any}'><span class="jlbinding">Expronicon.is_for</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_for(ex)
```


Check if `ex` is a `for` loop expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L227-L231" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_function-Tuple{Any}' href='#Expronicon.is_function-Tuple{Any}'><span class="jlbinding">Expronicon.is_function</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_function(def)
```


Check if given object is a function expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L140-L144" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_gensym-Tuple{Symbol}' href='#Expronicon.is_gensym-Tuple{Symbol}'><span class="jlbinding">Expronicon.is_gensym</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_gensym(s)
```


Check if `s` is generated by `gensym`.

::: tip Note

Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L43-L50" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_ifelse-Tuple{Any}' href='#Expronicon.is_ifelse-Tuple{Any}'><span class="jlbinding">Expronicon.is_ifelse</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_ifelse(ex)
```


Check if `ex` is an `if ... elseif ... else ... end` expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L217-L221" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_kw_function-Tuple{Any}' href='#Expronicon.is_kw_function-Tuple{Any}'><span class="jlbinding">Expronicon.is_kw_function</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_kw_function(def)
```


Check if a given function definition supports keyword arguments.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L170-L174" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_literal-Tuple{Any}' href='#Expronicon.is_literal-Tuple{Any}'><span class="jlbinding">Expronicon.is_literal</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_literal(x)
```


Check if `x` is a literal value.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L20-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_matrix_expr-Tuple{Any}' href='#Expronicon.is_matrix_expr-Tuple{Any}'><span class="jlbinding">Expronicon.is_matrix_expr</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_matrix_expr(ex)
```


Check if `ex` is an expression for a `Matrix`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L282-L286" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_splat-Tuple{Any}' href='#Expronicon.is_splat-Tuple{Any}'><span class="jlbinding">Expronicon.is_splat</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_splat(ex)
```


Check if `ex` is a splat expression, i.e. `:(f(x)...)`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L36-L40" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_struct-Tuple{Any}' href='#Expronicon.is_struct-Tuple{Any}'><span class="jlbinding">Expronicon.is_struct</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_struct(ex)
```


Check if `ex` is a struct expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L194-L198" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_struct_not_kw_struct-Tuple{Any}' href='#Expronicon.is_struct_not_kw_struct-Tuple{Any}'><span class="jlbinding">Expronicon.is_struct_not_kw_struct</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_struct_not_kw_struct(ex)
```


Check if `ex` is a struct expression excluding keyword struct syntax.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L204-L208" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_tuple-Tuple{Any}' href='#Expronicon.is_tuple-Tuple{Any}'><span class="jlbinding">Expronicon.is_tuple</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_tuple(ex)
```


Check if `ex` is a tuple expression, i.e. `:((a,b,c))`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L29-L33" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.is_valid_typevar-Tuple{Any}' href='#Expronicon.is_valid_typevar-Tuple{Any}'><span class="jlbinding">Expronicon.is_valid_typevar</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_valid_typevar(typevar)
```


Check if the given typevar is a valid typevar.

::: tip Note

This function is based on [this discourse post](https://discourse.julialang.org/t/what-are-valid-type-parameters/471).

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L1-L8" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.support_default-Tuple{Any}' href='#Expronicon.support_default-Tuple{Any}'><span class="jlbinding">Expronicon.support_default</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
support_default(f)
```


Check if field type `f` supports default value.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/check.jl#L54-L58" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.Variable' href='#Expronicon.Variable'><span class="jlbinding">Expronicon.Variable</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct Variable
```


Marks a `Symbol` as a variable. So that [`compare_expr`](/api#Expronicon.compare_expr-Tuple{Any,%20Any}) will always return `true`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/compare.jl#L5-L10" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.assert_equal_expr-Tuple{Module, Any, Any}' href='#Expronicon.assert_equal_expr-Tuple{Module, Any, Any}'><span class="jlbinding">Expronicon.assert_equal_expr</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
assert_equal_expr(m::Module, lhs, rhs)
```


Assert that `lhs` and `rhs` are equal in `m`. Throw an `ExprNotEqual` if they are not equal.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/compare.jl#L46-L51" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.compare_expr-Tuple{Any, Any}' href='#Expronicon.compare_expr-Tuple{Any, Any}'><span class="jlbinding">Expronicon.compare_expr</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
compare_expr([m=Main], lhs, rhs)
```


Compare two expression of type `Expr` or `Symbol` semantically, which:
1. ignore the detail value `LineNumberNode` in comparision;
    
2. ignore the detailed name of typevars declared by `where`;
    
3. recognize inserted objects and `Symbol`, e.g `:($Int)` is equal to `:(Int)`;
    
4. recognize `QuoteNode(:x)` and `Symbol("x")` as equal;
    
5. will guess module and type objects and compare their value directly  instead of their expression;
    

::: tip Tips

This function is usually combined with [`prettify`](/api#Expronicon.prettify-Tuple{Any}) with `preserve_last_nothing=true` and `alias_gensym=false`.

:::

This gives a way to compare two Julia expression semantically which means although some details of the expression is different but they should produce the same lowered code.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/compare.jl#L137-L157" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.@test_expr-Tuple{Any, Any}' href='#Expronicon.@test_expr-Tuple{Any, Any}'><span class="jlbinding">Expronicon.@test_expr</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@test_expr <type> <ex>
```


Test if the syntax type generates the same expression `ex`. Returns the corresponding syntax type instance. Requires `using Test` before using this macro.

**Example**

```julia
def = @test_expr JLFunction function (x, y)
    return 2
end
@test is_kw_fn(def) == false
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/compare.jl#L62-L77" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.@test_expr-Tuple{Expr}' href='#Expronicon.@test_expr-Tuple{Expr}'><span class="jlbinding">Expronicon.@test_expr</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@test_expr <expr> == <expr>
```


Test if two expression is equivalent semantically, this uses `compare_expr` to decide if they are equivalent, ignores things such as `LineNumberNode` generated `Symbol` in `Expr(:curly, ...)` or `Expr(:where, ...)`.

::: tip Note

This macro requires one `using Test` to import the `Test` module name.

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/compare.jl#L93-L104" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLCall-Tuple{Expr}' href='#Expronicon.JLCall-Tuple{Expr}'><span class="jlbinding">Expronicon.JLCall</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
JLCall(ex::Expr)
```


Convert a Julia call expression to `JLCall`.

**Examples**

```julia
ex = :(f(x, y; z=1))
jlcall = JLCall(ex)  # creates JLCall with func=:f, args=[:x, :y], kwargs=[:(z=1)]
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/cons.jl#L1-L11" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLFor-Tuple{Expr}' href='#Expronicon.JLFor-Tuple{Expr}'><span class="jlbinding">Expronicon.JLFor</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
JLFor(ex::Expr)
```


Create a `JLFor` from given Julia for loop expression.

**Example**

```julia
julia> ex = @expr for i in 1:10, j in 1:j
           M[i, j] += 1
       end
:(for i = 1:10, j = 1:j
      #= REPL[3]:2 =#
      M[i, j] += 1
  end)

julia> jl = JLFor(ex)
for i in 1 : 10,
    j in 1 : j
    #= loop body =#
    begin
        #= REPL[3]:2 =#        
        M[i, j] += 1        
    end
end

julia> jl.vars
2-element Vector{Any}:
 :i
 :j

julia> jl.iterators
2-element Vector{Any}:
 :(1:10)
 :(1:j)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/cons.jl#L206-L242" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLFunction-Tuple{Expr}' href='#Expronicon.JLFunction-Tuple{Expr}'><span class="jlbinding">Expronicon.JLFunction</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
JLFunction(ex::Expr)
```


Create a `JLFunction` object from a Julia function `Expr`.

**Example**

```julia
julia> JLFunction(:(f(x) = 2))
f(x) = begin
    #= REPL[37]:1 =#    
    2    
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/cons.jl#L20-L34" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLIfElse-Tuple{Expr}' href='#Expronicon.JLIfElse-Tuple{Expr}'><span class="jlbinding">Expronicon.JLIfElse</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
JLIfElse(ex::Expr)
```


Create a `JLIfElse` from given Julia ifelse `Expr`.

**Example**

```julia
julia> ex = :(if foo(x)
             x = 1 + 1
         elseif goo(x)
             y = 1 + 2
         else
             error("abc")
         end)
:(if foo(x)
      #= REPL[41]:2 =#
      x = 1 + 1
  elseif #= REPL[41]:3 =# goo(x)
      #= REPL[41]:4 =#
      y = 1 + 2
  else
      #= REPL[41]:6 =#
      error("abc")
  end)

julia> JLIfElse(ex)
if foo(x)
    begin
        #= REPL[41]:2 =#        
        x = 1 + 1        
    end
elseif begin
    #= REPL[41]:3 =#    
    goo(x)    
end
    begin
        #= REPL[41]:4 =#        
        y = 1 + 2        
    end
else
    begin
        #= REPL[41]:6 =#        
        error("abc")        
    end
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/cons.jl#L150-L197" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLKwStruct-2' href='#Expronicon.JLKwStruct-2'><span class="jlbinding">Expronicon.JLKwStruct</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
JLKwStruct(ex::Expr, typealias=nothing)
```


Create a `JLKwStruct` from given Julia struct `Expr`, with an option to attach an alias to this type name.

**Example**

```julia
julia> JLKwStruct(:(struct Foo
           x::Int = 1
       end))
#= kw =# struct Foo
    #= REPL[39]:2 =#
    x::Int = 1
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/cons.jl#L103-L120" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.JLStruct-Tuple{Expr}' href='#Expronicon.JLStruct-Tuple{Expr}'><span class="jlbinding">Expronicon.JLStruct</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
JLStruct(ex::Expr)
```


Create a `JLStruct` object from a Julia struct `Expr`.

**Example**

```julia
julia> JLStruct(:(struct Foo
           x::Int
       end))
struct Foo
    #= REPL[38]:2 =#
    x::Int
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/cons.jl#L56-L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.guess_module-Tuple{Module, Any}' href='#Expronicon.guess_module-Tuple{Module, Any}'><span class="jlbinding">Expronicon.guess_module</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
guess_module(m, ex)
```


Guess the module of given expression `ex` (of a module) in module `m`. If `ex` is not a module, or cannot be determined return `nothing`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/guess.jl#L1-L7" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.guess_type-Tuple{Module, Any}' href='#Expronicon.guess_type-Tuple{Module, Any}'><span class="jlbinding">Expronicon.guess_type</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
guess_type(m::Module, ex)
```


Guess the actual type of expression `ex` (of a type) in module `m`. Returns the type if it can be determined, otherwise returns the expression. This function is used in [`compare_expr`](/api#Expronicon.compare_expr-Tuple{Any,%20Any}).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/guess.jl#L28-L34" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.gensym_name-Tuple{Symbol}' href='#Expronicon.gensym_name-Tuple{Symbol}'><span class="jlbinding">Expronicon.gensym_name</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
gensym_name(x::Symbol)
```


Return the gensym name.

::: tip Note

Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/reflection.jl#L40-L47" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.@expr-Tuple{Any, Any}' href='#Expronicon.@expr-Tuple{Any, Any}'><span class="jlbinding">Expronicon.@expr</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@expr <type> <expression>
```


Return the expression in given type.

**Example**

```julia
julia> ex = @expr JLKwStruct struct Foo{N, T}
           x::T = 1
       end
#= kw =# struct Foo{N, T}
    #= /home/roger/code/julia/Expronicon/test/analysis.jl:5 =#
    x::T = 1
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/reflection.jl#L17-L33" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.@expr-Tuple{Any}' href='#Expronicon.@expr-Tuple{Any}'><span class="jlbinding">Expronicon.@expr</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@expr <expression>
```


Return the original expression object.

**Example**

```julia
julia> ex = @expr x + 1
:(x + 1)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/reflection.jl#L1-L12" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_anonymous_function_head-Tuple{Expr}' href='#Expronicon.split_anonymous_function_head-Tuple{Expr}'><span class="jlbinding">Expronicon.split_anonymous_function_head</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
split_anonymous_function_head(ex::Expr) -> nothing, args, kw, whereparams, rettype
```


Split anonymous function head to arguments, keyword arguments and where parameters.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L105-L109" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_doc-Tuple{Any}' href='#Expronicon.split_doc-Tuple{Any}'><span class="jlbinding">Expronicon.split_doc</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
split_doc(ex::Expr) -> line, doc, expr
```


Split doc string from given expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L1-L5" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_field_if_match' href='#Expronicon.split_field_if_match'><span class="jlbinding">Expronicon.split_field_if_match</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
split_field_if_match(typename::Symbol, expr, default::Bool=false)
```


Split the field definition if it matches the given type name. Returns `NamedTuple` with `name`, `type`, `default` and `isconst` fields if it matches, otherwise return `nothing`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L241-L247" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_function-Tuple{Any}' href='#Expronicon.split_function-Tuple{Any}'><span class="jlbinding">Expronicon.split_function</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
split_function(ex::Expr) -> head, call, body
```


Split function head declaration with function body.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L24-L28" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_function_head-Tuple{Expr}' href='#Expronicon.split_function_head-Tuple{Expr}'><span class="jlbinding">Expronicon.split_function_head</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
split_function_head(ex::Expr) -> name, args, kw, whereparams, rettype
```


Split function head to name, arguments, keyword arguments and where parameters.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L54-L58" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_kw_block_nothrow-Tuple{Expr}' href='#Expronicon.split_kw_block_nothrow-Tuple{Expr}'><span class="jlbinding">Expronicon.split_kw_block_nothrow</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
split_kw_block_nothrow(ex::Expr) -> nothing, args, kw, nothing, nothing
```


Split the argument list of `(x; kw) -> body`, which Julia parses as a block holding `x` and `kw`. The block also holds `LineNumberNode`s, which are ignored so that a block whose line numbers were removed is split too. Return `nothing` when `ex` is no such block.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L65-L71" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_struct-Tuple{Expr}' href='#Expronicon.split_struct-Tuple{Expr}'><span class="jlbinding">Expronicon.split_struct</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
split_struct(ex::Expr) -> ismutable, name, typevars, supertype, body
```


Split struct definition head and body.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L159-L163" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.split_struct_name-Tuple{Any}' href='#Expronicon.split_struct_name-Tuple{Any}'><span class="jlbinding">Expronicon.split_struct_name</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
split_struct_name(ex::Expr) -> name, typevars, supertype
```


Split the name, type parameters and supertype definition from `struct` declaration head.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L143-L148" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.uninferrable_typevars-Tuple{Union{JLKwStruct, JLStruct}}' href='#Expronicon.uninferrable_typevars-Tuple{Union{JLKwStruct, JLStruct}}'><span class="jlbinding">Expronicon.uninferrable_typevars</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
uninferrable_typevars(def::Union{JLStruct, JLKwStruct}; leading_inferable::Bool=true)
```


Return the type variables that are not inferrable in given struct definition.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/analysis/split.jl#L216-L220" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Transform {#Transform}

Some common transformations for Julia `Expr`, these functions takes an `Expr` and returns an `Expr`.
<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.Substitute' href='#Expronicon.Substitute'><span class="jlbinding">Expronicon.Substitute</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L430-L448" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.alias_gensym-Tuple{Any}' href='#Expronicon.alias_gensym-Tuple{Any}'><span class="jlbinding">Expronicon.alias_gensym</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
alias_gensym(ex)
```


Replace gensym with `<name>_<id>`.

::: tip Note

Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L307-L314" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.annotations_only-Tuple{Any}' href='#Expronicon.annotations_only-Tuple{Any}'><span class="jlbinding">Expronicon.annotations_only</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
annotations_only(ex)
```


Return type annotations only. See also [`name_only`](/api#Expronicon.name_only-Tuple{Any}).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L84-L88" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.canonicalize_lambda_head-Tuple{Any}' href='#Expronicon.canonicalize_lambda_head-Tuple{Any}'><span class="jlbinding">Expronicon.canonicalize_lambda_head</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
canonicalize_lambda_head(ex)
```


Canonicalize the `Expr(:function, Expr(:block, x, Expr(:(=), key, default)), body)` to

```julia
Expr(:function, Expr(:tuple, Expr(:parameters, Expr(:kw, key, default)), x), body)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L233-L241" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.eval_interp-Tuple{Module, Any}' href='#Expronicon.eval_interp-Tuple{Module, Any}'><span class="jlbinding">Expronicon.eval_interp</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
eval_interp(m::Module, ex)
```


evaluate the interpolation operator in `ex` inside given module `m`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L2-L6" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.eval_literal-Tuple{Module, Any}' href='#Expronicon.eval_literal-Tuple{Module, Any}'><span class="jlbinding">Expronicon.eval_literal</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
eval_literal(m::Module, ex)
```


Evaluate the literal values and insert them back to the expression. The literal value can be checked via [`is_literal`](/api#Expronicon.is_literal-Tuple{Any}).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L20-L25" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.expr_map-Tuple{Any, Vararg{Any}}' href='#Expronicon.expr_map-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Expronicon.expr_map</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
expr_map(f, c...; skip_nothing::Bool=false)
```


Similar to `Base.map`, but expects `f` to return an expression, and will concanate these expression as a `Expr(:block, ...)` expression.

Skip `nothing` if `skip_nothing` is `true`.

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L369-L397" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.flatten_blocks-Tuple{Any}' href='#Expronicon.flatten_blocks-Tuple{Any}'><span class="jlbinding">Expronicon.flatten_blocks</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
flatten_blocks(ex)
```


Remove hierachical expression blocks.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L174-L178" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.name_only-Tuple{Any}' href='#Expronicon.name_only-Tuple{Any}'><span class="jlbinding">Expronicon.name_only</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L47-L71" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.nexprs-Tuple{Any, Int64}' href='#Expronicon.nexprs-Tuple{Any, Int64}'><span class="jlbinding">Expronicon.nexprs</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L408-L427" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.prettify-Tuple{Any}' href='#Expronicon.prettify-Tuple{Any}'><span class="jlbinding">Expronicon.prettify</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
prettify(ex; kw...)
```


Prettify given expression, remove all `LineNumberNode` and extra code blocks.

**Options (Kwargs)**

All the options are `true` by default.
- `rm_lineinfo`: remove `LineNumberNode`.
    
- `flatten_blocks`: flatten `begin ... end` code blocks.
    
- `rm_nothing`: remove `nothing` in the `begin ... end`.
    
- `preserve_last_nothing`: preserve the last `nothing` in the `begin ... end`.
    
- `rm_single_block`: remove single `begin ... end`.
    
- `alias_gensym`: replace `##<name>#<num>` with `<name>_<id>`.
    
- `renumber_gensym`: renumber the gensym id.
    

::: tip Tips

the `LineNumberNode` inside macro calls won't be removed since the `macrocall` expression requires a `LineNumberNode`. See also [issues/#9](https://github.com/Roger-luo/Expronicon.jl/issues/9).

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L126-L149" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.renumber_gensym-Tuple{Any}' href='#Expronicon.renumber_gensym-Tuple{Any}'><span class="jlbinding">Expronicon.renumber_gensym</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
renumber_gensym(ex)
```


Re-number gensym with counter from this expression. Produce a deterministic gensym name for testing etc. See also: [`alias_gensym`](/api#Expronicon.alias_gensym-Tuple{Any})


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L335-L341" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.rm_annotations-Tuple{Any}' href='#Expronicon.rm_annotations-Tuple{Any}'><span class="jlbinding">Expronicon.rm_annotations</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rm_annotations(x)
```


Remove type annotation of given expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L287-L291" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.rm_lineinfo-Tuple{Any}' href='#Expronicon.rm_lineinfo-Tuple{Any}'><span class="jlbinding">Expronicon.rm_lineinfo</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rm_lineinfo(ex)
```


Remove `LineNumberNode` in a given expression.

::: tip Tips

the `LineNumberNode` inside macro calls won't be removed since the `macrocall` expression requires a `LineNumberNode`. See also [issues/#9](https://github.com/Roger-luo/Expronicon.jl/issues/9).

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L97-L107" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.rm_nothing-Tuple{Any}' href='#Expronicon.rm_nothing-Tuple{Any}'><span class="jlbinding">Expronicon.rm_nothing</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rm_nothing(ex)
```


Remove the constant value `nothing` in given expression `ex`.

**Keyword Arguments**
- `preserve_last_nothing`: if `true`, the last `nothing`   will be preserved.
    


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L209-L218" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.substitute-Tuple{Expr, Pair}' href='#Expronicon.substitute-Tuple{Expr, Pair}'><span class="jlbinding">Expronicon.substitute</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
substitute(ex::Expr, old=>new)
```


Substitute the old symbol `old` with `new`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/transform.jl#L34-L38" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## CodeGen {#CodeGen}

Code generators, functions that generates Julia `Expr` from given arguments, `Expronicon` types. 
<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast-Tuple{Any}' href='#Expronicon.codegen_ast-Tuple{Any}'><span class="jlbinding">Expronicon.codegen_ast</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L2-L36" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast_fields-Tuple{Any}' href='#Expronicon.codegen_ast_fields-Tuple{Any}'><span class="jlbinding">Expronicon.codegen_ast_fields</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
codegen_ast_fields(fields; just_name::Bool=true)
```


Generate a list of Julia AST object for each field, only generate a list of field names by default, option `just_name` can be turned off to call [`codegen_ast`](/api#Expronicon.codegen_ast-Tuple{Any}) on each field object.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L276-L282" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast_kwfn' href='#Expronicon.codegen_ast_kwfn'><span class="jlbinding">Expronicon.codegen_ast_kwfn</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L148-L190" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast_kwfn_infer' href='#Expronicon.codegen_ast_kwfn_infer'><span class="jlbinding">Expronicon.codegen_ast_kwfn_infer</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
codegen_ast_kwfn_infer(def, name = nothing)
```


Generate the keyword function that infers the type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L236-L240" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast_kwfn_plain' href='#Expronicon.codegen_ast_kwfn_plain'><span class="jlbinding">Expronicon.codegen_ast_kwfn_plain</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
codegen_ast_kwfn_plain(def[, name = nothing])
```


Generate the plain keyword function that does not infer type variables. So that one can use the type conversions defined by constructors.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L198-L203" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast_struct-Tuple{Any}' href='#Expronicon.codegen_ast_struct-Tuple{Any}'><span class="jlbinding">Expronicon.codegen_ast_struct</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
codegen_ast_struct(def)
```


Generate pure Julia struct `Expr` from struct definition. This is equivalent to `codegen_ast` for `JLStruct`. See also [`codegen_ast`](/api#Expronicon.codegen_ast-Tuple{Any}).

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L446-L474" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast_struct_body-Tuple{Any}' href='#Expronicon.codegen_ast_struct_body-Tuple{Any}'><span class="jlbinding">Expronicon.codegen_ast_struct_body</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L401-L428" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_ast_struct_head-Tuple{Any}' href='#Expronicon.codegen_ast_struct_head-Tuple{Any}'><span class="jlbinding">Expronicon.codegen_ast_struct_head</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L364-L388" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.struct_name_plain-Tuple{Any}' href='#Expronicon.struct_name_plain-Tuple{Any}'><span class="jlbinding">Expronicon.struct_name_plain</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
struct_name_plain(def)
```


Plain constructor name. See also [`struct_name_without_inferable`](/api#Expronicon.struct_name_without_inferable-Tuple{Any}).

**Example**

```julia
julia> def = @expr JLKwStruct struct Foo{N, Inferable}
    x::Inferable = 1
end

julia> struct_name_plain(def)
:(Foo{N, Inferable})
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L296-L311" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.struct_name_without_inferable-Tuple{Any}' href='#Expronicon.struct_name_without_inferable-Tuple{Any}'><span class="jlbinding">Expronicon.struct_name_without_inferable</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
struct_name_without_inferable(def; leading_inferable::Bool=true)
```


Constructor name that assume some of the type variables is inferred. See also [`struct_name_plain`](/api#Expronicon.struct_name_plain-Tuple{Any}). The kwarg `leading_inferable` can be used to configure whether to preserve the leading inferable type variables, the default is `true` to be consistent with the default julia constructors.

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L317-L346" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xcall-Tuple{Any, Vararg{Any}}' href='#Expronicon.xcall-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Expronicon.xcall</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xcall(name, args...; kw...)
```


Create a function call to `name`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L517-L521" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xcall-Tuple{Module, Symbol, Vararg{Any}}' href='#Expronicon.xcall-Tuple{Module, Symbol, Vararg{Any}}'><span class="jlbinding">Expronicon.xcall</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xcall(m::Module, name::Symbol, args...; kw...)
```


Create a function call to `GlobalRef(m, name)`.

::: tip Tip

due to [Revise/#616](https://github.com/timholy/Revise.jl/issues/616), to make your macro work with Revise, we use the dot expression `Expr(:., <module>, QuoteNode(<name>))` instead of `GlobalRef` here.

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L531-L541" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xfirst-Tuple{Any}' href='#Expronicon.xfirst-Tuple{Any}'><span class="jlbinding">Expronicon.xfirst</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xfirst(collection)
```


Create a function call expression to `Base.first`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L563-L567" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xgetindex-Tuple{Any, Vararg{Any}}' href='#Expronicon.xgetindex-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Expronicon.xgetindex</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xgetindex(collection, key...)
```


Create a function call expression to `Base.getindex`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L547-L551" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xiterate-Tuple{Any, Any}' href='#Expronicon.xiterate-Tuple{Any, Any}'><span class="jlbinding">Expronicon.xiterate</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xiterate(it, st)
```


Create a function call expression to `Base.iterate`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L612-L616" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xiterate-Tuple{Any}' href='#Expronicon.xiterate-Tuple{Any}'><span class="jlbinding">Expronicon.xiterate</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xiterate(it)
```


Create a function call expression to `Base.iterate`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L605-L609" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xlast-Tuple{Any}' href='#Expronicon.xlast-Tuple{Any}'><span class="jlbinding">Expronicon.xlast</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xlast(collection)
```


Create a function call expression to `Base.last`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L570-L574" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xmap-Tuple{Any, Vararg{Any}}' href='#Expronicon.xmap-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Expronicon.xmap</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xmap(f, xs...)
```


Create a function call expression to `Base.map`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L591-L595" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xmapreduce-Tuple{Any, Any, Vararg{Any}}' href='#Expronicon.xmapreduce-Tuple{Any, Any, Vararg{Any}}'><span class="jlbinding">Expronicon.xmapreduce</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xmapreduce(f, op, xs...)
```


Create a function call expression to `Base.mapreduce`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L598-L602" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xnamedtuple-Tuple{}' href='#Expronicon.xnamedtuple-Tuple{}'><span class="jlbinding">Expronicon.xnamedtuple</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xnamedtuple(;kw...)
```


Create a `NamedTuple` expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L504-L508" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xprint-Tuple' href='#Expronicon.xprint-Tuple'><span class="jlbinding">Expronicon.xprint</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xprint(xs...)
```


Create a function call expression to `Base.print`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L577-L581" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xprintln-Tuple' href='#Expronicon.xprintln-Tuple'><span class="jlbinding">Expronicon.xprintln</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xprintln(xs...)
```


Create a function call expression to `Base.println`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L584-L588" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xpush-Tuple{Any, Vararg{Any}}' href='#Expronicon.xpush-Tuple{Any, Vararg{Any}}'><span class="jlbinding">Expronicon.xpush</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xpush(collection, items...)
```


Create a function call expression to `Base.push!`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L554-L558" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.xtuple-Tuple' href='#Expronicon.xtuple-Tuple'><span class="jlbinding">Expronicon.xtuple</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xtuple(xs...)
```


Create a `Tuple` expression.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/codegen.jl#L497-L501" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.codegen_match' href='#Expronicon.codegen_match'><span class="jlbinding">Expronicon.codegen_match</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
codegen_match(f, x[, line::LineNumberNode=LineNumberNode(0), mod::Module=Main])
```


Generate a zero dependency match expression using MLStyle code generator, the syntax is identical to MLStyle.

::: tip Tip

`codegen_match` is not available in ExproniconLite since it depends on MLStyle's pattern matching functionality.

:::

**Example**

```julia
codegen_match(:x) do
    quote
        1 => true
        2 => false
        _ => nothing
    end
end
```


This code generates the following corresponding MLStyle expression

```julia
@match x begin
    1 => true
    2 => false
    _ => nothing
end
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/match.jl#L154-L185" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.@syntax_pattern' href='#Expronicon.@syntax_pattern'><span class="jlbinding">Expronicon.@syntax_pattern</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@syntax_pattern <syntax type> <syntax checker>
```


Bundle a syntax type as MLStyle pattern.

::: tip Tip

this is not available in ExproniconLite since it depends on MLStyle's pattern matching functionality.

:::

**Example**

```julia
struct MyFunction
    ex :: Expr
    test_field :: Any
end

is_xxx(ex::Expr) = Meta.isexpr(ex, :function)
is_xxx(_) = false

julia> MyFunction(ex::Expr) = MyFunction(ex, :aaa)
julia> @syntax_pattern(MyFunction, is_xxx)

julia> @match :(function f() end) begin
        MyFunction(;test_field) => test_field
    end
:aaa
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/match.jl#L191-L219" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Printings {#Printings}

Pretty printing functions.
<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.print_inline-Tuple{IO, Any}' href='#Expronicon.print_inline-Tuple{IO, Any}'><span class="jlbinding">Expronicon.print_inline</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
print_expr([io::IO], ex; kw...)
```


Print a given expression within one line. `ex` can be a `Expr` or a syntax type `JLExpr`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/print/inline.jl#L455-L460" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.print_expr-Tuple{IO, Any}' href='#Expronicon.print_expr-Tuple{IO, Any}'><span class="jlbinding">Expronicon.print_expr</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
print_expr([io::IO], ex; kw...)
```


Print a given expression. `ex` can be a `Expr` or a syntax type `JLExpr`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/print/multi.jl#L468-L472" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.sprint_expr-Tuple{Any}' href='#Expronicon.sprint_expr-Tuple{Any}'><span class="jlbinding">Expronicon.sprint_expr</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
sprint_expr(ex; context=nothing, kw...)
```


Print given expression to `String`, see also [`print_expr`](/api#Expronicon.print_expr-Tuple{IO,%20Any}).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/print/print.jl#L17-L21" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Algebra Data Type {#Algebra-Data-Type}

Algebra data type
<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.@adt-Tuple{Any, Any}' href='#Expronicon.ADT.@adt-Tuple{Any, Any}'><span class="jlbinding">Expronicon.ADT.@adt</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@adt name begin
    variant1
    variant2(field1, field2)

    <mutable> struct variant3
        field1
        field2 = <default>
    end
end
```


Create an algebra data type (ADT).

**Arguments**
- `<name>`: the name of the ADT, can be just a name or name with supertype.
    
- `<body>`: the body of the ADT, a list of variants in `begin ... end` block.
    

**Introduction**

The ADT is a type that can have multiple variants. Each variant can have different fields. The fields can be of different types. The ADT is immutable by default. To make it mutable, use `mutable struct` instead of `struct` in the definition.

The ADT is implemented as a tagged union. The tag is stored in the first field. The rest of the fields are the actual data. The data is stored in a compact way so that the size of the ADT is the size of the largest variant.

Use of multiple variants will not effect type stability, unlike `Union` types.

The variants must be used with the variant interface instead of the type interface from Julia `Base`, and the pattern match must be MLStyle's pattern match. It is recommended to use pattern match as much as possible.

**Pretty Printing**

A default inline pretty printing is generated for `Base.show(io::IO, x::<your ADT type>)`. If you want to customize inline text printing, overload `Expronicon.ADT.variant_show_inline(io::IO, x::<your ADT type>)` method. For other `MIME` types, you can overload the normal `Base.show(::IO, ::MIME, x::<your ADT type>)` method.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/emit.jl#L150-L191" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.adt_type-Tuple{Any}' href='#Expronicon.ADT.adt_type-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.adt_type</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
adt_type(variant_type)
```


Returns the algebra data type type of a variant type `variant_type`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L41-L45" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.is_adt-Tuple{Any}' href='#Expronicon.ADT.is_adt-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.is_adt</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_adt(variant)
```


Returns `true` if `variant` is an instance of an algebra data type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L8-L12" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.is_adt-Union{Tuple{Type{T}}, Tuple{T}} where T' href='#Expronicon.ADT.is_adt-Union{Tuple{Type{T}}, Tuple{T}} where T'><span class="jlbinding">Expronicon.ADT.is_adt</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_adt(::Type{T}) where T
```


Returns `true` if `T` is an algebra data type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L1-L5" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.is_variant-Tuple{Any}' href='#Expronicon.ADT.is_variant-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.is_variant</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
is_variant(variant)
is_variant(variant_type)
```


Returns `true` if `T` is a variant type or an instance of an algebra data type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L15-L20" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_field_default-Tuple{Any, Int64}' href='#Expronicon.ADT.variant_field_default-Tuple{Any, Int64}'><span class="jlbinding">Expronicon.ADT.variant_field_default</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_field_default(variant_type, idx)
```


Returns the `idx`-th field default of a variant type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L104-L108" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_field_defaults-Tuple{Any}' href='#Expronicon.ADT.variant_field_defaults-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.variant_field_defaults</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_field_defaults(variant_type)
```


Returns the field defaults of a variant type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L95-L99" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_fieldname-Tuple{Any, Int64}' href='#Expronicon.ADT.variant_fieldname-Tuple{Any, Int64}'><span class="jlbinding">Expronicon.ADT.variant_fieldname</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_fieldname(variant_type, idx)
```


Returns the `idx`-th field name of a variant type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L68-L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_fieldnames-Tuple{Any}' href='#Expronicon.ADT.variant_fieldnames-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.variant_fieldnames</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_fieldnames(variant_type)
```


Returns the field names of a variant type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L59-L63" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_fieldtype-Tuple{Any, Int64}' href='#Expronicon.ADT.variant_fieldtype-Tuple{Any, Int64}'><span class="jlbinding">Expronicon.ADT.variant_fieldtype</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_fieldtype(variant_type, idx)
```


Returns the `idx`-th field type of a variant type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L86-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_fieldtypes-Tuple{Any}' href='#Expronicon.ADT.variant_fieldtypes-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.variant_fieldtypes</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_fieldtypes(variant_type)
```


Returns the field types of a variant type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L77-L81" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_masks-Tuple{Any}' href='#Expronicon.ADT.variant_masks-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.variant_masks</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_masks(variant_type)
```


Returns the masks of a variant type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L50-L54" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variant_type-Tuple{Any}' href='#Expronicon.ADT.variant_type-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.variant_type</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variant_type(variant)
```


Returns the variant type of an algebra data type instance `variant`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L32-L36" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.variants-Union{Tuple{Type{T}}, Tuple{T}} where T' href='#Expronicon.ADT.variants-Union{Tuple{Type{T}}, Tuple{T}} where T'><span class="jlbinding">Expronicon.ADT.variants</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
variants(::Type{T}) where T
```


Returns the variant types of an algebra data type `T`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/traits.jl#L23-L27" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.@const_use-Tuple{Any}' href='#Expronicon.ADT.@const_use-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.@const_use</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@const_use <name>: <variant>
@const_use <name>: <variant>, <variant>, ...
@const_use <name>: *
```


Import the variant of a ADT into current namespace.

```julia
@const_use Message: Write
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/use.jl#L21-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.@export_use-Tuple{Any}' href='#Expronicon.ADT.@export_use-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.@export_use</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@export_use <name>: <variant>
```


Import the variant of a ADT into current namespace, and export it.

```julia
@export_use Message: Write
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/use.jl#L36-L45" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Expronicon.ADT.@use-Tuple{Any}' href='#Expronicon.ADT.@use-Tuple{Any}'><span class="jlbinding">Expronicon.ADT.@use</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@use <name>: <variant>
@use <name>: <variant>, <variant>, ...
@use <name>: *
```


Import the variant of a ADT into current namespace.

```julia
@use Message: Write
```


::: tip Tips

This macro does not create a constant binding so that you can use it inside a function, if you wish to use this macro in the global scope, use `@const_use` instead.

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/Roger-luo/Expronicon.jl/blob/de810e837b156b83f97a8da34dd04b413bd85377/src/adt/use.jl#L1-L16" target="_blank" rel="noreferrer">source</a></Badge>

</details>

