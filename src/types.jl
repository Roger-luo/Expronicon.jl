"""
intermediate types for Julia expression objects.
"""
module Types

export NoDefault, JLExpr, JLIfElse, JLFunction, JLField, JLKwField, JLStruct, JLKwStruct,
    no_default

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

abstract type JLExpr end

"""
    JLFunction <: JLExpr

Type describes a Julia function declaration expression.
"""
mutable struct JLFunction <: JLExpr
    head::Symbol  # function def must have a head
    name::Any  # name can be nothing, Symbol, Expr
    args::Vector{Any} 
    kwargs::Maybe{Vector{Any}} 
    whereparams::Maybe{Vector{Any}} 
    body::Any
    line::Maybe{LineNumberNode} 
    doc::Maybe{String} 
end

function JLFunction(;
        head=:function, name=nothing,
        args=[], kwargs=nothing,
        whereparams=nothing, body=Expr(:block),
        line=nothing, doc=nothing
    )
    JLFunction(head, name, args, kwargs, whereparams, body, line, doc)
end

"""
    JLField <: JLExpr
    JLField(name, type, line)

Type describes a Julia field in a Julia struct.
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
    JLKwField <: JLExpr
    JLKwField(name, type, line, default=no_default)

Type describes a Julia field that can have a default value in a Julia struct.
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
    JLStruct <: JLExpr

Type describes a Julia struct.
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

function JLKwStruct(;name, typealias=nothing,
    ismutable=false, typevars=[], supertype=nothing,
    fields=JLField[], constructors=JLFunction[],
    line=nothing, doc=nothing, misc=nothing)
    JLKwStruct(name, typealias, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

mutable struct JLIfElse <: JLExpr
    map::Dict{Any, Any}
    otherwise::Any
end

JLIfElse() = JLIfElse(Dict(), nothing)

end
