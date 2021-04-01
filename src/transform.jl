
"""
    eval_interp(m::Module, ex)

evaluate the interpolation operator in `ex` inside given module `m`.
"""
function eval_interp(m::Module, ex)
    ex isa Expr || return ex
    ex.head === :$ && return Base.eval(m, ex.args[1])
    return Expr(ex.head, map(x->eval_interp(m, x), ex.args)...)
end

function eval_literal(m::Module, ex)
    ex isa Expr || return ex
    if ex.head === :call && all(is_literal, ex.args[2:end])
        return Base.eval(m, ex)
    end
    return Expr(ex.head, map(x->eval_literal(m, x), ex.args)...)
end

replace_symbol(x::Symbol, name::Symbol, value) = x === name ? value : x
replace_symbol(x, ::Symbol, value) = x # other expressions

function replace_symbol(ex::Expr, name::Symbol, value)
    Expr(ex.head, map(x->replace_symbol(x, name, value), ex.args)...)
end

function subtitute(ex::Expr, replace::Pair)
    name, value = replace
    return replace_symbol(ex, name, value)
end

"""
    name_only(ex)

Remove everything else leaving just names, currently supports
function calls, type with type variables, subtype operator `<:`
and type annotation `::`.

# Example

```julia
julia> using Expronicon

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
    ex isa Symbol && return ex
    ex isa Expr || error("unsupported expression $ex")
    ex.head in [:call, :curly, :(<:), :(::), :where, :function, :(=), :(->)] && return name_only(ex.args[1])
    error("unsupported expression $ex")
end

"""
    rm_lineinfo(ex)

Remove `LineNumberNode` in a given expression.
"""
function rm_lineinfo(ex)
    @match ex begin
        Expr(:macrocall, name, line, args...) => Expr(:macrocall, name, line, map(rm_lineinfo, args)...)
        Expr(head, args...) => Expr(head, map(rm_lineinfo, filter(x->!(x isa LineNumberNode), args))...)
        _ => ex
    end
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
function flatten_blocks(ex)
    ex isa Expr || return ex
    ex.head === :block || return Expr(ex.head, map(_flatten_blocks, ex.args)...)
    has_block = any(ex.args) do x
        x isa Expr && x.head === :block
    end

    if has_block
        return flatten_blocks(_flatten_blocks(ex))
    end
    return Expr(ex.head, map(flatten_blocks, ex.args)...)
end

function _flatten_blocks(ex)
    ex isa Expr || return ex
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
            return gensym("::$(x.args[1])")
        else
            return x.args[1]
        end
    elseif x.head in [:(=), :kw] # default values
        return rm_annotations(x.args[1])
    else
        return Expr(x.head, map(rm_annotations, x.args)...)
    end
end
