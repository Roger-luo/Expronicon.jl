"""
    split_doc(ex::Expr) -> line, doc, expr

Split doc string from given expression.
"""
function split_doc(ex)
    @switch ex begin
        @case Expr(:macrocall, &(GlobalRef(Core, Symbol("@doc"))), line, doc, expr) ||
                Expr(:macrocall, &(Symbol("@doc")), line, doc, expr) ||
                Expr(:macrocall, Expr(:., :Core, &(QuoteNode(Symbol("@doc")))), line, doc, expr)
            return line, doc, expr

        # quote
        #     @doc "" struct <name> end
        # end
        @case Expr(:block, ::LineNumberNode, stmt)
            line, doc, expr = split_doc(stmt)
            return line, doc, expr
        @case _
            return nothing, nothing, ex
    end
end

"""
    split_function(ex::Expr) -> head, call, body

Split function head declaration with function body.
"""
function split_function(ex; source = nothing)
    ret = split_function_nothrow(ex)
    isnothing(ret) && throw(SyntaxError("expect a function expr, got $ex", source))
    ret
end

function split_function_nothrow(ex)
    @match ex begin
        Expr(:function, call, body) => (:function, call, body)
        Expr(:function, call, body) => (:function, call, body)
        Expr(:(=), call, body) => begin
            @match call begin
                Expr(:call, f, args...) || Expr(:(::), Expr(:call, f, args...), rettype) ||
                    Expr(:where, Expr(:call, f, args...), params...) ||
                    Expr(:where, Expr(:(::), Expr(:call, f, args...), rettype), params...) => true
                _ => return nothing
            end
            (:(=), call, body)
        end
        Expr(:(->), call, body) => (:(->), call, body)
        _ => nothing
    end
end


"""
    split_function_head(ex::Expr) -> name, args, kw, whereparams, rettype

Split function head to name, arguments, keyword arguments and where parameters.
"""
function split_function_head(ex::Expr; source=nothing)
    split_head_tuple = split_function_head_nothrow(ex)
    isnothing(split_head_tuple) && (throw(SyntaxError("expect a function head, got $ex", source)))
    split_head_tuple
end

function split_function_head_nothrow(ex::Expr)
    @match ex begin
        Expr(:tuple, Expr(:parameters, kw...), args...) => (nothing, args, kw, nothing, nothing)
        Expr(:tuple, args...) => (nothing, args, nothing, nothing, nothing)
        Expr(:call, name, Expr(:parameters, kw...), args...) => (name, args, kw, nothing, nothing)
        Expr(:call, name, args...) => (name, args, nothing, nothing, nothing)
        Expr(:block, x, ::LineNumberNode, Expr(:(=), kw, value)) => (nothing, Any[x], Any[Expr(:kw, kw, value)], nothing, nothing)
        Expr(:block, x, ::LineNumberNode, kw) => (nothing, Any[x], Any[kw], nothing, nothing)
        Expr(:(::), call::Expr, rettype) => begin
            sub_tuple = split_function_head_nothrow(call)
            isnothing(sub_tuple) && return nothing
            name, args, kw, whereparams, _ = split_function_head_nothrow(call)
            (name, args, kw, whereparams, rettype)
        end
        Expr(:where, call, whereparams...) => begin
            sub_tuple = split_function_head_nothrow(call)
            isnothing(sub_tuple) && return nothing
            name, args, kw, _, rettype = sub_tuple
            (name, args, kw, whereparams, rettype)
        end
        _ => nothing
    end
end
split_function_head_nothrow(s::Symbol) = (nothing, Any[s], nothing, nothing, nothing)

"""
    split_anonymous_function_head(ex::Expr) -> nothing, args, kw, whereparams, rettype

Split anonymous function head to arguments, keyword arguments and where parameters.
"""
function split_anonymous_function_head(ex::Expr; source=nothing)
    split_head_tuple = split_anonymous_function_head_nothrow(ex)
    isnothing(split_head_tuple) && throw(SyntaxError("expect an anonymous function head, got $ex", source))
    split_head_tuple
end

split_anonymous_function_head(ex::Symbol; source=nothing) = 
    split_anonymous_function_head_nothrow(ex)

function split_anonymous_function_head_nothrow(ex::Expr)
    @match ex begin
        Expr(:tuple, Expr(:parameters, kw...), args...) => (nothing, args, kw, nothing, nothing)
        Expr(:tuple, args...) => (nothing, args, nothing, nothing, nothing)
        Expr(:block, x, ::LineNumberNode, Expr(:(=), kw, value)) => (nothing, Any[x], Any[Expr(:kw, kw, value)], nothing, nothing)
        Expr(:block, x, ::LineNumberNode, kw) => (nothing, Any[x], Any[kw], nothing, nothing)
        Expr(:(::), fh::Expr, rettype) => begin
            sub_tuple = split_anonymous_function_head_nothrow(fh)
            isnothing(sub_tuple) && return nothing
            name, args, kw, whereparams, _ = sub_tuple
            (name, args, kw, whereparams, rettype)
        end
        Expr(:(::), arg::Symbol, argtype) || Expr(:(::), argtype) => (nothing, Any[ex], nothing, nothing, nothing)
        Expr(:where, call, whereparams...) => begin
            sub_tuple = split_anonymous_function_head_nothrow(call)
            isnothing(sub_tuple) && return nothing
            name, args, kw, _, rettype = sub_tuple
            (name, args, kw, whereparams, rettype)
        end
        _ => nothing
    end
end
split_anonymous_function_head_nothrow(s::Symbol) = (nothing, Any[s], nothing, nothing, nothing)


"""
    split_struct_name(ex::Expr) -> name, typevars, supertype

Split the name, type parameters and supertype definition from `struct`
declaration head.
"""
function split_struct_name(@nospecialize(ex); source = nothing)
    return @match ex begin
        :($name{$(typevars...)}) => (name, typevars, nothing)
        :($name{$(typevars...)} <: $type) => (name, typevars, type)
        ::Symbol => (ex, [], nothing)
        :($name <: $type) => (name, [], type)
        _ => throw(SyntaxError("expect struct got $ex", source))
    end
end

"""
    split_struct(ex::Expr) -> ismutable, name, typevars, supertype, body

Split struct definition head and body.
"""
function split_struct(ex::Expr; source = nothing)
    ex.head === :struct || throw(SyntaxError("expect a struct expr, got $ex", source))
    name, typevars, supertype = split_struct_name(ex.args[2]; source)
    body = ex.args[3]
    return ex.args[1], name, typevars, supertype, body
end

function split_ifelse(ex::Expr)
    conds, stmts = [], []
    otherwise = split_ifelse!((conds, stmts), ex)
    return conds, stmts, otherwise
end

function split_ifelse!((conds, stmts), ex::Expr)
    ex.head in [:if, :elseif] || return ex
    push!(conds, ex.args[1])
    push!(stmts, ex.args[2])

    if length(ex.args) == 3
        return split_ifelse!((conds, stmts), ex.args[3])
    end
    return
end

function split_forloop(ex::Expr)
    ex.head === :for || error("expect a for loop expr, got $ex")
    lhead = ex.args[1]
    lbody = ex.args[2]
    return split_for_head(lhead)..., lbody
end

function split_for_head(ex::Expr)
    if ex.head === :block
        vars, itrs = [], []
        for each in ex.args
            each isa Expr || continue # skip other things
            var, itr = split_single_for_head(each)
            push!(vars, var)
            push!(itrs, itr)
        end
        return vars, itrs
    else
        var, itr = split_single_for_head(ex)
        return Any[var], Any[itr]
    end
end

function split_single_for_head(ex::Expr)
    ex.head === :(=) || error("expect a single loop head, got $ex")
    return ex.args[1], ex.args[2]
end

"""
    uninferrable_typevars(def::Union{JLStruct, JLKwStruct}; leading_inferable::Bool=true)

Return the type variables that are not inferrable in given struct definition.
"""
function uninferrable_typevars(def::Union{JLStruct, JLKwStruct}; leading_inferable::Bool=true)
    typevars = name_only.(def.typevars)
    field_types = [field.type for field in def.fields]

    if leading_inferable
        idx = findfirst(typevars) do t
            !any(map(f->has_symbol(f, t), field_types))
        end
        idx === nothing && return []
    else
        idx = 0
    end
    uninferrable = typevars[1:idx]

    for T in typevars[idx+1:end]
        any(map(f->has_symbol(f, T), field_types)) || push!(uninferrable, T)
    end
    return uninferrable
end

"""
    split_field_if_match(typename::Symbol, expr, default::Bool=false)

Split the field definition if it matches the given type name.
Returns `NamedTuple` with `name`, `type`, `default` and `isconst` fields
if it matches, otherwise return `nothing`.
"""
function split_field_if_match(typename::Symbol, expr, default::Bool=false; source = nothing)
    @switch expr begin
        @case Expr(:const, :($(name::Symbol)::$type = $value))
            default && return (;name, type, isconst=true, default=value)
            throw(SyntaxError("default value syntax is not allowed", source))
        @case Expr(:const, :($(name::Symbol) = $value))
            default && return (;name, type=Any, isconst=true, default=value)
            throw(SyntaxError("default value syntax is not allowed", source))
        @case :($(name::Symbol)::$type = $value)
            default && return (;name, type, isconst=false, default=value)
            throw(SyntaxError("default value syntax is not allowed", source))
        @case :($(name::Symbol) = $value)
            default && return (;name, type=Any, isconst=false, default=value)
            throw(SyntaxError("default value syntax is not allowed", source))
        @case Expr(:const, :($(name::Symbol)::$type))
            default && return (;name, type, isconst=true, default=no_default)
            return (;name, type, isconst=true)
        @case Expr(:const, name::Symbol)
            default && return (;name, type=Any, isconst=true, default=no_default)
            return (;name, type=Any, isconst=true)
        @case :($(name::Symbol)::$type)
            default && return (;name, type, isconst=false, default=no_default)
            return (;name, type, isconst=false)
        @case name::Symbol
            default && return (;name, type=Any, isconst=false, default=no_default)
            return (;name, type=Any, isconst=false)
        @case ::String || ::LineNumberNode
            return expr
        @case if is_function(expr) end
            if name_only(expr) === typename
                return JLFunction(expr)
            else
                return expr
            end
        @case _
            return expr
    end
end

function split_signature(call::Expr)
    if Meta.isexpr(call, :where)
        Expr(:where, split_signature(call.args[1]), call.args[2:end]...)
    elseif Meta.isexpr(call, :call)
        :($Base.Tuple{$Base.typeof($(call.args[1])), $(arg2type.(call.args[2:end])...)})
    else
        error("invalid signature: $call")
    end
end

function arg2type(arg)
    @match arg begin
        ::Symbol => Any
        :(::$type) || :($_::$type) => type
        :($_::$type...) => :($Base.Vararg{$type})
        :($_...) => :($Base.Vararg{$Any})
        _ => error("invalid argument type: $arg")
    end
end
