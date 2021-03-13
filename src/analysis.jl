"""
analysis functions for Julia Expr
"""
module Analysis

using MLStyle
using ..Types
using ..Transform
export AnalysisError, is_fn, is_kw_fn, split_function, split_function_head, split_struct,
    split_struct_name, annotations, uninferrable_typevars, has_symbol

struct AnalysisError <: Exception
    expect::String
    got
end

anlys_error(expect, got) = throw(AnalysisError(expect, got))

function Base.show(io::IO, e::AnalysisError)
    print(io, "expect ", e.expect, " expression, got ", e.got, ".")
end

function has_symbol(@nospecialize(ex), name::Symbol)
    ex isa Symbol && return ex === name
    ex isa Expr || return false
    return any(x->has_symbol(x, name), ex.args)
end

"""
    is_fn(def)

Check if given object is a function expression.
"""
function is_fn(@nospecialize(def))
    @match def begin
        ::JLFunction => true
        Expr(:function, _, _) => true
        Expr(:(=), _, _) => true
        Expr(:(->), _, _) => true
        _ => false
    end
end

"""
    is_kw_fn(def)

Check if a given function definition supports keyword arguments.
"""
function is_kw_fn(@nospecialize(def))
    is_fn(def) || return false

    if def isa JLFunction
        return def.kwargs !== nothing
    end

    _, call, _ = split_function(def)
    @match call begin
        Expr(:tuple, Expr(:parameters, _...), _...) => true
        Expr(:call, _, Expr(:parameters, _...), _...) => true
        Expr(:block, _, ::LineNumberNode, _) => true
        _ => false
    end
end

"""
    split_doc(ex::Expr) -> line, doc, expr

Split doc string from given expression.
"""
function split_doc(ex::Expr)
    @match ex begin
        Expr(:macrocall, GlobalRef(Core, Symbol("@doc")), line, doc, expr) => (line, doc, expr)
        _ => (nothing, nothing, ex)
    end
end

"""
    split_function(ex::Expr) -> head, call, body

Split function head declaration with function body.
"""
function split_function(ex::Expr)
    @match ex begin
        Expr(:function, call, body) => (:function, call, body)
        Expr(:(=), call, body) => (:(=), call, body)
        Expr(:(->), call, body) => (:(->), call, body)
        _ => anlys_error("function", ex)
    end
end

"""
    split_function_head(ex::Expr) -> name, args, kw, whereparams

Split function head to name, arguments, keyword arguments and where parameters.
"""
function split_function_head(ex::Expr)
    @match ex begin
        Expr(:tuple, Expr(:parameters, kw...), args...) => (nothing, args, kw, nothing)
        Expr(:tuple, args...) => (nothing, args, nothing, nothing)
        Expr(:call, Expr(:parameters, kw...), name, args...) => (name, args, kw, nothing)
        Expr(:call, name, args...) => (name, args, nothing, nothing)
        Expr(:block, x, ::LineNumberNode, Expr(:(=), kw, value)) => (nothing, Any[x], Any[Expr(:kw, kw, value)], nothing)
        Expr(:block, x, ::LineNumberNode, kw) => (nothing, Any[x], Any[kw], nothing)
        Expr(:where, call, whereparams...) => begin
            name, args, kw, _ = split_function_head(call)
            (name, args, kw, whereparams)
        end
        _ => anlys_error("function head expr", ex)
    end
end

"""
    split_struct_name(ex::Expr) -> name, typevars, supertype

Split the name, type parameters and supertype definition from `struct`
declaration head.
"""
function split_struct_name(@nospecialize(ex))
    return @match ex begin
        :($name{$(typevars...)}) => (name, typevars, nothing)
        :($name{$(typevars...)} <: $type) => (name, typevars, type)
        ::Symbol => (ex, [], nothing)
        :($name <: $type) => (name, [], type)
        _ => anlys_error("struct", ex)
    end
end

"""
    split_struct(ex::Expr) -> ismutable, name, typevars, supertype, body

Split struct definition head and body.
"""
function split_struct(ex::Expr)
    ex.head === :struct || error("expect a struct expr, got $ex")
    name, typevars, supertype = split_struct_name(ex.args[2])
    body = ex.args[3]
    return ex.args[1], name, typevars, supertype, body
end

function uninferrable_typevars(def::Union{JLStruct, JLKwStruct})
    typevars = name_only.(def.typevars)
    field_types = [field.type for field in def.fields]

    uninferrable = []
    for T in typevars
        T in field_types || push!(uninferrable, T)
    end
    return uninferrable
end

function Types.JLFunction(ex::Expr)
    line, doc, expr = split_doc(ex)
    head, call, body = split_function(expr)
    name, args, kw, whereparams = split_function_head(call)
    JLFunction(head, name, args, kw, whereparams, body, line, doc)
end

function Types.JLStruct(ex::Expr)
    line, doc, expr = split_doc(ex)
    ismutable, typename, typevars, supertype, body = split_struct(expr)

    fields, constructors, misc = JLField[], JLFunction[], []
    field_doc, field_line = nothing, nothing

    for each in body.args
        @switch each begin
            @case :($name::$type)
                push!(fields, JLField(name, type, field_doc, field_line))
            @case name::Symbol
                push!(fields, JLField(name, Any, field_doc, field_line))
            @case ::String
                field_doc = each
            @case ::LineNumberNode
                field_line = each
            @case GuardBy(is_fn)
                if name_only(each) === typename
                    push!(constructors, JLFunction(each))
                else
                    push!(misc, each)
                end
            @case _
                push!(misc, each)
        end
    end
    JLStruct(typename, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

function Types.JLKwStruct(ex::Expr, typealias=nothing)
    line, doc, expr = split_doc(ex)
    ismutable, typename, typevars, supertype, body = split_struct(expr)

    fields, constructors, misc = JLKwField[], JLFunction[], []
    field_doc, field_line = nothing, nothing

    for each in body.args
        @switch each begin
            @case :($name::$type = $default)
                push!(fields, JLKwField(name, type, field_doc, field_line, default))
            @case :($(name::Symbol) = $default)
                push!(fields, JLKwField(name, Any, field_doc, field_line, default))
            @case name::Symbol
                push!(fields, JLKwField(name, Any, field_doc, field_line, no_default))
            @case :($name::$type)
                push!(fields, JLKwField(name, type, field_doc, field_line, no_default))
            @case ::String
                field_doc = each
            @case ::LineNumberNode
                field_line = each
            @case GuardBy(is_fn)
                if name_only(each) === typename
                    push!(constructors, JLFunction(each))
                else
                    push!(misc, each)
                end
            @case _
                push!(misc, each)
        end
    end
    JLKwStruct(typename, typealias, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

end
