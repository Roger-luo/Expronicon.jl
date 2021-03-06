
"""
    eval_interp(m::Module, ex)

evaluate the interpolation operator in `ex` inside given module `m`.
"""
function eval_interp(m::Module, ex)
    ex isa Expr || return ex
    if ex.head === :$
        x = ex.args[1]
        if x isa Symbol && isdefined(m, x)
            return Base.eval(m, x)
        else
            return ex
        end
    end
    return Expr(ex.head, map(x->eval_interp(m, x), ex.args)...)
end

"""
    eval_literal(m::Module, ex)

Evaluate the literal values and insert them back to the expression.
The literal value can be checked via [`is_literal`](@ref).
"""
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

"""
    subtitute(ex::Expr, old=>new)

Subtitute the old symbol `old` with `new`.
"""
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
    ex isa QuoteNode && return ex.value
    ex isa Expr || error("unsupported expression $ex")
    ex.head in [:call, :curly, :(<:), :(::), :where, :function, :kw, :(=), :(->)] && return name_only(ex.args[1])
    ex.head === :. && return name_only(ex.args[2])
    ex.head === :module && return name_only(ex.args[2])
    error("unsupported expression $ex")
end

"""
    rm_lineinfo(ex)

Remove `LineNumberNode` in a given expression.

!!! tips

    the `LineNumberNode` inside macro calls won't be removed since
    the `macrocall` expression requires a `LineNumberNode`. See also
    [issues/#9](https://github.com/Roger-luo/Expronicon.jl/issues/9).
"""
function rm_lineinfo(ex)
    @match ex begin
        Expr(:macrocall, name, line, args...) => Expr(:macrocall, name, line, map(rm_lineinfo, args)...)
        Expr(head, args...) => Expr(head, map(rm_lineinfo, filter(x->!(x isa LineNumberNode), args))...)
        _ => ex
    end
end

Base.@kwdef struct PrettifyOptions
    rm_lineinfo::Bool = true
    flatten_blocks::Bool = true
    rm_nothing::Bool = true
    rm_single_block::Bool = true
    alias_gensym::Bool = true
end

"""
    prettify(ex; kw...)

Prettify given expression, remove all `LineNumberNode` and
extra code blocks.

# Options (Kwargs)

All the options are `true` by default.

- `rm_lineinfo`: remove `LineNumberNode`.
- `flatten_blocks`: flatten `begin ... end` code blocks.
- `rm_nothing`: remove `nothing` in the `begin ... end`.
- `rm_single_block`: remove single `begin ... end`.
- `alias_gensym`: replace `##<name>#<num>` with `<name>_<id>`.

!!! tips

    the `LineNumberNode` inside macro calls won't be removed since
    the `macrocall` expression requires a `LineNumberNode`. See also
    [issues/#9](https://github.com/Roger-luo/Expronicon.jl/issues/9).
"""
function prettify(ex; kw...)
    prettify(ex, PrettifyOptions(;kw...))
end

function prettify(ex, options::PrettifyOptions)
    ex isa Expr || return ex
    ex = options.alias_gensym ? alias_gensym(ex) : ex
    for _ in 1:10
        curr = prettify_pass(ex, options)
        ex == curr && break
        ex = curr
    end
    return ex
end

function prettify_pass(ex, options::PrettifyOptions)
    ex = options.rm_lineinfo ? rm_lineinfo(ex) : ex
    ex = options.flatten_blocks ? flatten_blocks(ex) : ex
    ex = options.rm_nothing ? rm_nothing(ex) : ex
    ex = options.rm_single_block ? rm_single_block(ex) : ex
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
    rm_nothing(ex)

Remove the constant value `nothing` in given expression `ex`.
"""
function rm_nothing(ex)
    @match ex begin
        Expr(:block, args...) => Expr(:block, filter(x->x!==nothing, args)...)
        Expr(head, args...) => Expr(head, map(rm_nothing, args)...)
        _ => ex
    end
end

function rm_single_block(ex)
    @match ex begin
        Expr(:(=), _...) ||
            Expr(:(->), _...) ||
            Expr(:quote, xs...) ||
            Expr(:block, Expr(:quote, xs...)) => ex
        Expr(:try, Expr(:block, try_stmts...), false, false, Expr(:block, finally_stmts...)) => Expr(:try,
                Expr(:block, rm_single_block.(try_stmts)...),
                false, false,
                Expr(:block, rm_single_block.(finally_stmts)...)
            )
        Expr(:try, Expr(:block, try_stmts...), catch_var, Expr(:block, catch_stmts...)) => Expr(:try,
                Expr(:block, rm_single_block.(try_stmts)...),
                catch_var,
                Expr(:block, rm_single_block.(catch_stmts)...)
            )
        Expr(:try, Expr(:block, try_stmts...), catch_var,
            Expr(:block, catch_stmts...), Expr(:block, finally_stmts...)) => Expr(:try,
                Expr(:block, rm_single_block.(try_stmts)...),
                catch_var,
                Expr(:block, rm_single_block.(catch_stmts)...),
                Expr(:block, rm_single_block.(finally_stmts)...)
            )
        Expr(:block, stmt) => stmt
        Expr(head, args...) => Expr(head, map(rm_single_block, args)...)
        _ => ex
    end
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

"""
    alias_gensym(ex)

Replace gensym with `<name>_<id>`.

!!! note
    Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).
"""
alias_gensym(ex) = alias_gensym!(Dict{Symbol, Symbol}(), Dict{Symbol, Int}(), ex)

function alias_gensym!(d::Dict{Symbol, Symbol}, count::Dict{Symbol, Int}, ex)
    if is_gensym(ex)
        haskey(d, ex) && return d[ex]
        name = Symbol(gensym_name(ex))
        id = get(count, name, 0) + 1
        d[ex] = Symbol(name, :_, id)
        count[name] = id
        return d[ex]
    end

    ex isa Expr || return ex
    args = map(ex.args) do x
        alias_gensym!(d, count, x)
    end

    return Expr(ex.head, args...)
end