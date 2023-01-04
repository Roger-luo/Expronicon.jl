"""
    split_doc(ex::Expr) -> line, doc, expr

Split doc string from given expression.
"""
function split_doc(ex::Expr)
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
function split_function(ex::Expr)
    @match ex begin
        Expr(:function, call, body) => (:function, call, body)
        Expr(:(=), call, body) => (:(=), call, body)
        Expr(:(->), call, body) => (:(->), call, body)
        _ => anlys_error("function", ex)
    end
end

"""
    split_function_head(ex::Expr) -> name, args, kw, whereparams, rettype

Split function head to name, arguments, keyword arguments and where parameters.
"""
function split_function_head(ex::Expr)
    @match ex begin
        Expr(:tuple, Expr(:parameters, kw...), args...) => (nothing, args, kw, nothing, nothing)
        Expr(:tuple, args...) => (nothing, args, nothing, nothing, nothing)
        Expr(:call, name, Expr(:parameters, kw...), args...) => (name, args, kw, nothing, nothing)
        Expr(:call, name, args...) => (name, args, nothing, nothing, nothing)
        Expr(:block, x, ::LineNumberNode, Expr(:(=), kw, value)) => (nothing, Any[x], Any[Expr(:kw, kw, value)], nothing, nothing)
        Expr(:block, x, ::LineNumberNode, kw) => (nothing, Any[x], Any[kw], nothing, nothing)
        Expr(:(::), call, rettype) => begin
            name, args, kw, whereparams, _ = split_function_head(call)
            (name, args, kw, whereparams, rettype)
        end
        Expr(:where, call, whereparams...) => begin
            name, args, kw, _, rettype = split_function_head(call)
            (name, args, kw, whereparams, rettype)
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
function split_field_if_match(typename::Symbol, expr, default::Bool=false)
    @switch expr begin
        @case Expr(:const, :($(name::Symbol)::$type = $value))
            default && return (;name, type, isconst=true, default=value)
            throw(ArgumentError("default value syntax is not allowed"))
        @case Expr(:const, :($(name::Symbol) = $value))
            default && return (;name, type=Any, isconst=true, default=value)
            throw(ArgumentError("default value syntax is not allowed"))
        @case :($(name::Symbol)::$type = $value)
            default && return (;name, type, isconst=false, default=value)
            throw(ArgumentError("default value syntax is not allowed"))
        @case :($(name::Symbol) = $value)
            default && return (;name, type=Any, isconst=false, default=value)
            throw(ArgumentError("default value syntax is not allowed"))
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
