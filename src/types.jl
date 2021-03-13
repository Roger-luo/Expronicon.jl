"""
intermediate types for Julia expression objects.
"""
module Types

export NoDefault, JLExpr, JLFunction, JLField, JLKwField, JLStruct, JLKwStruct,
    no_default

using Markdown
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
Base.@kwdef mutable struct JLFunction <: JLExpr
    head::Symbol = :function # function def must have a head
    name::Any = nothing # name can be nothing, Symbol, Expr
    args::Vector{Any} = []
    kwargs::Maybe{Vector{Any}} = nothing
    whereparams::Maybe{Vector{Any}} = nothing
    body::Any = Expr(:block)
    line::Maybe{LineNumberNode} = nothing
    doc::Maybe{String} = nothing
end

"""
    JLField <: JLExpr
    JLField(name, type, line)

Type describes a Julia field in a Julia struct.
"""
Base.@kwdef mutable struct JLField <: JLExpr
    name::Symbol
    type::Any = Any
    doc::Maybe{String} = nothing
    line::Maybe{LineNumberNode} = nothing
end

"""
    JLKwField <: JLExpr
    JLKwField(name, type, line, default=no_default)

Type describes a Julia field that can have a default value in a Julia struct.
"""
Base.@kwdef mutable struct JLKwField <: JLExpr
    name::Symbol
    type::Any = Any
    doc::Maybe{String} = nothing
    line::Maybe{LineNumberNode} = nothing
    default::Any = no_default
end

"""
    JLStruct <: JLExpr

Type describes a Julia struct.
"""
Base.@kwdef mutable struct JLStruct <: JLExpr
    name::Symbol
    ismutable::Bool = false
    typevars::Vector{Any} = []
    supertype::Any = nothing
    fields::Vector{JLField} = JLField[]
    constructors::Vector{JLFunction} = JLFunction[]
    line::Maybe{LineNumberNode} = nothing
    doc::Maybe{String} = nothing
    misc::Any = nothing
end

"""
    JLKwStruct <: JLExpr

Type describes a Julia struct that allows keyword definition of defaults.
"""
Base.@kwdef mutable struct JLKwStruct <: JLExpr
    name::Symbol
    typealias::Maybe{String} = nothing
    ismutable::Bool = false
    typevars::Vector{Any} = []
    supertype::Any = nothing
    fields::Vector{JLKwField} = JLKwField[]
    constructors::Vector{JLFunction} = JLFunction[]
    line::Maybe{LineNumberNode} = nothing
    doc::Maybe{String} = nothing
    misc::Any = nothing
end

end
