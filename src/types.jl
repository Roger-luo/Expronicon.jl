const Maybe{T} = Union{Nothing, T}

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
    JLFunction <: JLExpr

Type describes a Julia function declaration expression.

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
    JLFunction(head, name, args, kwargs, rettype, whereparams, body, line, doc)
end

"""
    JLField <: JLExpr

Type describes a Julia field in a Julia struct.
"""
mutable struct JLField <: JLExpr
    name::Symbol
    type::Any
    doc::Maybe{String}
    line::Maybe{LineNumberNode}
end

"""
    JLField(;name, type=Any, doc=nothing, line=nothing)

Create a `JLField` instance.
"""
function JLField(;name, type=Any, doc=nothing, line=nothing)
    JLField(name, type, doc, line)
end

"""
    JLKwField <: JLExpr

Type describes a Julia field that can have a default value in a Julia struct.
"""
mutable struct JLKwField <: JLExpr
    name::Symbol
    type::Any
    doc::Maybe{String}
    line::Maybe{LineNumberNode}
    default::Any
end

"""
    JLKwField(;kw...)

Create a `JLKwField` instance.
"""
function JLKwField(;name, type=Any, doc=nothing, line=nothing, default=no_default)
    JLKwField(name, type, doc, line, default)
end

"""
    JLStruct <: JLExpr

Type describes a Julia struct.

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

"""
    JLStruct(;kw...)

Create a `JLStruct` instance.
"""
function JLStruct(;
    name, ismutable=false,
    typevars=[], supertype=nothing,
    fields=JLField[], constructors=JLFunction[],
    line=nothing, doc=nothing, misc=nothing)
    JLStruct(name, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

"""
    JLKwStruct <: JLExpr

Type describes a Julia struct that allows keyword definition of defaults.
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

"""
    JLKwStruct(;kw...)

Create a `JLKwStruct` instance.
"""
function JLKwStruct(;name, typealias=nothing,
    ismutable=false, typevars=[], supertype=nothing,
    fields=JLField[], constructors=JLFunction[],
    line=nothing, doc=nothing, misc=nothing)
    JLKwStruct(name, typealias, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

"""
    JLIfElse <: JLExpr

`JLIfElse` describes a Julia `if ... elseif ... else ... end` expression. It allows one to easily construct
such expression by inserting condition and code block via a map.

# Example

### Construct JLIfElse object

One can construct an `ifelse` as following

```julia
julia> jl = JLIfElse()
nothing

julia> jl.map[:(foo(x))] = :(x = 1 + 1)
:(x = 1 + 1)

julia> jl.map[:(goo(x))] = :(y = 1 + 2)
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
    map::OrderedDict{Any, Any}
    otherwise::Any
end

"""
    JLIfElse()

Create an emptry `ifelse` syntax type instance.
"""
JLIfElse() = JLIfElse(OrderedDict(), nothing)

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
