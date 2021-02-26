module Types

export NoDefault, JLExpr, JLFunction, JLField, JLKwField, JLStruct, JLKwStruct,
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
    head::Symbol # function def must have a head
    name::Any # name can be nothing, Symbol, Expr
    args::Vector{Any}
    kwargs::Maybe{Vector{Any}}
    whereparams::Maybe{Vector{Any}}
    body::Any
end

function JLFunction(;head::Symbol=:function,
        name=nothing, args=[],
        kwargs=nothing, whereparams=nothing,
        body=Expr(:block))
    JLFunction(head, name, args, kwargs, whereparams, body)
end


"""
    JLField <: JLExpr
    JLField(name, type, line)

Type describes a Julia field in a Julia struct.
"""
mutable struct JLField <: JLExpr
    name::Symbol
    type::Any
    line::Maybe{LineNumberNode}
end

"""
    JLKwField <: JLExpr
    JLKwField(name, type, line, default=no_default)

Type describes a Julia field that can have a default value in a Julia struct.
"""
mutable struct JLKwField <: JLExpr
    name::Symbol
    type::Any
    line::Maybe{LineNumberNode}
    default::Any
end

JLKwField(name, type, line) = JLKwField(name, type, line, no_default)

"""
    JLStruct <: JLExpr

Type describes a Julia struct.
"""
mutable struct JLStruct <: JLExpr
    name::Symbol
    ismutable::Bool
    typevars::Vector{Any}
    fields::Vector{JLField}
    supertype::Any
    misc::Any
end

"""
    JLKwStruct <: JLExpr

Type describes a Julia struct that allows keyword definition of defaults.
"""
mutable struct JLKwStruct <: JLExpr
    name::Symbol
    ismutable::Bool
    typevars::Vector{Any}
    fields::Vector{JLKwField}
    supertype::Any
    misc::Any
end

end
