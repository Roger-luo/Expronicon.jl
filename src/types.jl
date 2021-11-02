const Maybe{T} = Union{Nothing, T}

const __DEFAULT_KWARG_DOC__ = """
All the following fields are valid as keyword arguments `kw` in the constructor, and can
be access via `<object>.<field>`.
"""

const __DEF_DOC__ = "`doc::String`: the docstring of this definition."
const __LINENO_DOC__ = "`line::LineNumberNode`: a `LineNumberNode` to indicate the line information."

"""
    NoDefault

Type describes a field should have no default value.
"""
struct NoDefault end

"""
    const no_default = NoDefault()

Constant instance for [`NoDefault`](@ref) that
describes a field should have no default value.
"""
const no_default = NoDefault()

"""
    abstract type JLExpr end

Abstract type for Julia syntax type.
"""
abstract type JLExpr end

"""
    mutable struct JLFunction <: JLExpr
    JLFunction(;kw...)

Type describes a Julia function declaration expression.

# Fields and Keyword Arguments

$__DEFAULT_KWARG_DOC__
The only required keyword argument for the constructor
is `name`, the rest are all optional.

- `head`: optional, function head, can be `:function`, `:(=)` or `:(->)`.
- `name`: optional, function name, can has type `Nothing`, `Symbol` or `Expr`, default is `nothing`.
- `args`: optional, function arguments, a list of `Expr` or `Symbol`.
- `kwargs`: optional, function keyword arguments, a list of `Expr(:kw, name, default)`.
- `rettype`: optional, the explicit return type of a function,
    can be a `Type`, `Symbol`, `Expr` or just `nothing`, default is `nothing`.
- `whereparams`: optional, type variables, can be a list of `Type`,
    `Expr` or `nothing`, default is `nothing`.
- `body`: optional, function body, an `Expr`, default is `Expr(:block)`.
- $__LINENO_DOC__
- $__DEF_DOC__

# Example

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
"""
mutable struct JLFunction <: JLExpr
    head::Symbol  # function def must have a head
    name::Any  # name can be nothing, Symbol, Expr
    args::Vector{Any}
    kwargs::Maybe{Vector{Any}}
    rettype::Any
    whereparams::Maybe{Vector{Any}} 
    body::Any
    line::Maybe{LineNumberNode}
    doc::Maybe{String}
end

function JLFunction(;
        head=:function, name=nothing,
        args=[], kwargs=nothing,
        rettype=nothing,
        whereparams=nothing, body=Expr(:block),
        line=nothing, doc=nothing
    )
    head in [:function, :(=), :(->)] ||
        throw(ArgumentError("function head can only take `:function`, `:(=)` or `:(->)`"))
    name isa Union{Nothing, Symbol, Expr} ||
        throw(ArgumentError("function name can only be a `Nothing`, `Symbol` or `Expr`, got a $(typeof(name))."))
    rettype isa Union{Nothing, Symbol, Expr, Type} ||
        throw(ArgumentError("function rettype can only be a `Type`, `Symbol`, `Expr` or just `nothing`, got a $(typeof(rettype))."))
    line isa Maybe{LineNumberNode} ||
        throw(ArgumentError("function line must be a `LineNumberNode` or just `nothing`, got a $(typeof(line))."))

    JLFunction(head, name, args, kwargs, rettype, whereparams, body, line, doc)
end

"""
    mutable struct JLField <: JLExpr
    JLField(;kw...)

Type describes a Julia field in a Julia struct.

# Fields and Keyword Arguments

$__DEFAULT_KWARG_DOC__
The only required keyword argument for the constructor
is `name`, the rest are all optional.

- `name::Symbol`: the name of the field.
- `type`: the type of the field.
- $__LINENO_DOC__
- $__DEF_DOC__
"""
mutable struct JLField <: JLExpr
    name::Symbol
    type::Any
    doc::Maybe{String}
    line::Maybe{LineNumberNode}
end

function JLField(;name, type=Any, doc=nothing, line=nothing)
    JLField(name, type, doc, line)
end

"""
    mutable struct JLKwField <: JLExpr

Type describes a Julia field that can have a default value in a Julia struct.

    JLKwField(;kw...)

Create a `JLKwField` instance.

# Fields and Keyword Arguments

$__DEFAULT_KWARG_DOC__
The only required keyword argument for the constructor
is `name`, the rest are all optional.

- `name::Symbol`: the name of the field.
- `type`: the type of the field.
- `default`: default value of the field, default is [`no_default`](@ref).
- $__LINENO_DOC__
- $__DEF_DOC__
"""
mutable struct JLKwField <: JLExpr
    name::Symbol
    type::Any
    doc::Maybe{String}
    line::Maybe{LineNumberNode}
    default::Any
end

function JLKwField(;name, type=Any, doc=nothing, line=nothing, default=no_default)
    JLKwField(name, type, doc, line, default)
end

"""
    mutable struct JLStruct <: JLExpr

Type describes a Julia struct.

    JLStruct(;kw...)

Create a `JLStruct` instance.

# Available Fields and Keyword Arguments

$__DEFAULT_KWARG_DOC__
The only required keyword argument for the constructor
is `name`, the rest are all optional.

- `name::Symbol`: name of the struct, this is the only required keyword argument.
- `ismutable::Bool`: if the struct definition is mutable.
- `typevars::Vector{Any}`: type variables of the struct, should be `Symbol` or `Expr`.
- `supertype`: supertype of the struct definition.
- `fields::Vector{JLField}`: field definitions of the struct, should be a [`JLField`](@ref).
- `constructors::Vector{JLFunction}`: constructors definitions of the struct, should be [`JLFunction`](@ref).
- `line::LineNumberNode`: a `LineNumberNode` to indicate the definition position for error report etc.
- `doc::String`: documentation string of the struct.
- `misc`: other things that happens inside the struct body, by definition this will
    just fall through and is equivalent to eval them outside the struct body.

# Example

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
"""
mutable struct JLStruct <: JLExpr
    name::Symbol
    ismutable::Bool
    typevars::Vector{Any}
    supertype::Any
    fields::Vector{JLField}
    constructors::Vector{JLFunction}
    line::Maybe{LineNumberNode}
    doc::Maybe{String}
    misc::Any
end

function JLStruct(;
    name::Symbol, ismutable::Bool=false,
    typevars=[], supertype=nothing,
    fields=JLField[], constructors=JLFunction[],
    line=nothing, doc=nothing, misc=nothing)
    JLStruct(name, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

"""
    mutable struct JLKwStruct <: JLExpr
    JLKwStruct(;kw...)

Type describes a Julia struct that allows keyword definition of defaults.
This syntax is similar to [`JLStruct`](@ref) except
the the fields are of type [`JLKwField`](@ref).

# Fields and Keyword Arguments

$__DEFAULT_KWARG_DOC__
The only required keyword argument for the constructor
is `name`, the rest are all optional.

- `name::Symbol`: name of the struct, this is the only required keyword argument.
- `typealias::String`: an alias of the [`JLKwStruct`](@ref),
    see also the `@option` macro in [Configurations.jl](https://github.com/Roger-luo/Configurations.jl).
- `ismutable::Bool`: if the struct definition is mutable.
- `typevars::Vector{Any}`: type variables of the struct, should be `Symbol` or `Expr`.
- `supertype`: supertype of the struct definition.
- `fields::Vector{JLField}`: field definitions of the struct, should be a [`JLField`](@ref).
- `constructors::Vector{JLFunction}`: constructors definitions of the struct, should be [`JLFunction`](@ref).
- `line::LineNumberNode`: a `LineNumberNode` to indicate the definition position for error report etc.
- `doc::String`: documentation string of the struct.
- `misc`: other things that happens inside the struct body, by definition this will
    just fall through and is equivalent to eval them outside the struct body.
"""
mutable struct JLKwStruct <: JLExpr
    name::Symbol
    typealias::Maybe{String}
    ismutable::Bool
    typevars::Vector{Any}
    supertype::Any
    fields::Vector{JLKwField}
    constructors::Vector{JLFunction}
    line::Maybe{LineNumberNode}
    doc::Maybe{String}
    misc::Any
end

function JLKwStruct(;name::Symbol, typealias::Maybe{String}=nothing,
    ismutable::Bool=false, typevars=[], supertype=nothing,
    fields=JLKwField[], constructors=JLFunction[],
    line=nothing, doc=nothing, misc=nothing)
    JLKwStruct(name, typealias, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

"""
    JLIfElse <: JLExpr
    JLIfElse(;kw...)

`JLIfElse` describes a Julia `if ... elseif ... else ... end` expression. It allows one to easily construct
such expression by inserting condition and code block via a map.

# Fields and Keyword Arguments

$__DEFAULT_KWARG_DOC__
The only required keyword argument for the constructor
is `name`, the rest are all optional.

- `conds::Vector{Any}`: expression for the conditions.
- `stmts::Vector{Any}`: expression for the statements for corresponding condition.
- `otherwise`: the `else` body.

# Example

### Construct JLIfElse object

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

### Generate the Julia `Expr` object

to generate the corresponding `Expr` object, one can call [`codegen_ast`](@ref).

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
"""
mutable struct JLIfElse <: JLExpr
    conds::Vector{Any}
    stmts::Vector{Any}
    otherwise::Any
end

JLIfElse(;conds=[], stmts=[], otherwise=nothing) = JLIfElse(conds, stmts, otherwise)

function Base.getindex(jl::JLIfElse, cond)
    idx = findfirst(jl.conds) do x
        cond == x
    end
    idx === nothing && error("cannot find condition: $cond")
    return jl.stmts[idx]
end

function Base.setindex!(jl::JLIfElse, stmt, cond)
    idx = findfirst(jl.conds) do x
        x == cond
    end
    if idx === nothing
        push!(jl.conds, cond)
        push!(jl.stmts, stmt)
    else
        jl.stmts[idx] = stmt
    end
    return stmt
end

Base.length(jl::JLIfElse) = length(jl.conds)
function Base.iterate(jl::JLIfElse, st=1)
    st > length(jl) && return
    jl.conds[st] => jl.stmts[st], st + 1
end

"""
    JLFor <: JLExpr

Syntax type for Julia for loop.
"""
struct JLFor <: JLExpr
    vars::Vector{Any}
    iterators::Vector{Any}
    kernel::Any
end

"""
    JLFor(;vars=[], iterators=[], kernel=nothing)

Generate a `JLFor` object.

# Kwargs

- `vars`: loop variables.
- `iterators`: loop iterators.
- `kernel`: loop kernel.
"""
JLFor(;vars=[], iterators=[], kernel=nothing) = JLFor(vars, iterators, kernel)
