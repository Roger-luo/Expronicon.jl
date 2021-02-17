module Analysis

using MLStyle
using ..Types
export is_kw_fn, split_function, split_call, split_struct, split_struct_name, annotations

"""
    is_kw_fn(def)

Check if a given function definition supports keyword arguments.
"""
is_kw_fn(def) = false
is_kw_fn(def::JLFunction) = isnothing(def.kwargs)

function is_kw_fn(def::Expr)
    _, call, _ = split_function(def)
    @match call begin
        Expr(:tuple, Expr(:parameters, _...), _...) => true
        Expr(:call, _, Expr(:parameters, _...), _...) => true
        Expr(:block, _, ::LineNumberNode, _) => true
        _ => false
    end
end

"""
    split_function(ex::Expr; nothrow::Bool=false) -> head, call, body

Split function head declaration with function body.
"""
function split_function(ex::Expr; nothrow::Bool=false)
    @match ex begin
        Expr(:function, call, body) => (:function, call, body)
        Expr(:(=), call, body) => (:(=), call, body)
        Expr(:(->), call, body) => (:(->), call, body)
        _ => nothrow ? nothing : error("expect a function define, got $ex")
    end
end

"""
    split_call(ex::Expr; nothrow::Bool=false) -> name, args, kw, whereparams

Split call name, arguments, keyword arguments and where parameters.
"""
function split_call(ex::Expr; nothrow::Bool=false)
    @match ex begin
        Expr(:tuple, Expr(:parameters, kw...), args...) => (nothing, args, kw, nothing)
        Expr(:tuple, args...) => (nothing, args, nothing, nothing)
        Expr(:call, Expr(:parameters, kw...), name, args...) => (name, args, kw, nothing)
        Expr(:call, name, args...) => (name, args, nothing, nothing)
        Expr(:block, x, ::LineNumberNode, Expr(:(=), kw, value)) => (nothing, Any[x], Any[Expr(:kw, kw, value)], nothing)
        Expr(:block, x, ::LineNumberNode, kw) => (nothing, Any[x], Any[kw], nothing)
        Expr(:where, call, whereparams...) => begin
            name, args, kw, _ = split_call(call)
            (name, args, kw, whereparams)
        end
        _ => nothrow ? nothing : error("expect a call expr, got $ex")
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
        _ => error("invalid @option: $ex")
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

function Types.JLFunction(ex::Expr)
    head, call, body = split_function(ex)
    name, args, kw, whereparams = split_call(call)
    JLFunction(head, name, args, kw, whereparams, body)
end

function Types.JLStruct(ex::Expr)
    ismutable, name, typevars, supertype, body = split_struct(ex)

    fields = []
    misc = []
    line = nothing
    for each in body.args
        @match each begin
            name::Symbol => push!(fields, JLField(name, Any, line))
            :($name::$type) => push!(fields, JLField(name, type, line))
            ::LineNumberNode => (line = each)
            _ => push!(misc, each)
        end
    end
    JLStruct(name, ismutable, typevars, fields, supertype, misc)
end

function JLKwStruct(ex::Expr)
    ismutable, name, typevars, supertype, body = split_struct(ex)

    fields = []
    misc = []
    line = nothing
    for each in body.args
        @match each begin
            :($name = $default) => push!(fields, JLKwField(name, Any, line, default))
            :($name::$type = $default) => push!(fields, JLKwField(name, type, line, default))
            name::Symbol => push!(fields, JLKwField(name, Any, line))
            :($name::$type) => push!(fields, JLKwField(name, type, line))
            ::LineNumberNode => (line = each)
            _ => push!(misc, each)
        end
    end
    JLStruct(name, ismutable, typevars, fields, supertype, misc)
end

end
