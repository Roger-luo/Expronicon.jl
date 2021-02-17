module Transform

export prettify, rm_lineinfo, flatten_blocks, name_only

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
    ex.head === :where && return name_only(ex.args[1])
    error("unsupported expression $ex")
end

"""
    rm_lineinfo(ex)

Remove `LineNumberNode` in a given expression.
"""
rm_lineinfo(ex) = ex

function rm_lineinfo(ex::Expr)
    args = []
    for each in ex.args
        if !(each isa LineNumberNode)
            push!(args, rm_lineinfo(each))
        end
    end
    return Expr(ex.head, args...)
end

"""
    prettify(ex)

Prettify given expression, remove all `LineNumberNode` and
extra code blocks.
"""
function prettify(ex)
    ex isa Expr || return ex
    ex = rm_lineinfo(ex)
    ex = flatten_blocks(ex)
    return ex
end

"""
    flatten_blocks(ex)

Remove hierachical expression blocks.
"""
function flatten_blocks(ex::Expr)
    ex.head === :block || return Expr(ex.head, map(_flatten_blocks, ex.args)...)
    has_block = any(ex.args) do x
        x isa Expr && x.head === :block
    end

    if has_block
        return flatten_blocks(_flatten_blocks(ex))
    end
    return Expr(ex.head, map(flatten_blocks, ex.args)...)
end

function _flatten_blocks(ex::Expr)
    ex.head === :block || return Expr(ex.head, map(flatten_blocks, ex.args)...)

    args = []
    for stmt in ex.args
        if stmt isa Expr && stmt.head === :block
            for each in stmt.args
                push!(args, flatten_blocks(each))
            end
        else
            push!(args, flatten_blocks(stmt))
        end
    end
    return Expr(:block, args...)
end

"""
    rm_annotations(x)

Remove type annotation of given expression.
"""
function rm_annotations(x)
    x isa Expr || return x
    if x.head == :(::)
        if length(x.args) == 1 # anonymous
            return
        else
            return x.args[1]
        end
    elseif x.head in [:(=), :kw] # default values
        return rm_annotations(x.args[1])
    else
        return x
    end
end

end
