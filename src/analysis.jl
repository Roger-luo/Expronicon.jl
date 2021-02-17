module Analysis

using MLStyle
using ..Types
export is_kw_fn, name_only, split_function, split_call, split_struct, split_struct_name, annotations

"""
    is_kw_fn(def)

Check if a given function definition supports keyword arguments.
"""
is_kw_fn(def) = false
is_kw_fn(def::JLFunction) = isnothing(def.kwargs)

function is_kw_fn(def::Expr)
    _, call, _ = split_function(def)
    call.args[1] isa Expr && call.args[1].head === :parameters
end

"""
    name_only(ex)

Remove everything else leaving just names, currently supports
function calls, type with type variables, subtype operator `<:`
and type annotation `::`.

# Example

```jldoctest
julia> name_only(:(sin(2)))
:sin

julia> name_only(:(Foo{Int}))
:Foo

julia> name_only(:(Foo{Int} <: Real))
:Foo

julia> name_only(:(x::Int))
:x
```
"""
function name_only(@nospecialize(ex))
    ex isa Expr || return ex
    ex.head === :call && return name_only(ex.args[1])
    ex.head === :curly && return name_only(ex.args[1])
    ex.head === :(<:) && return name_only(ex.args[1])
    ex.head === :(::) && return name_only(ex.args[1])
    error("unsupported expression $ex")
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
