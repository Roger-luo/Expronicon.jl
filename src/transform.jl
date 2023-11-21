
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

"""
    substitute(ex::Expr, old=>new)

Substitute the old symbol `old` with `new`.
"""
function substitute(ex::Expr, replace::Pair)
    old, new = replace
    sub = Substitute() do x
        x == old
    end
    return sub(_->new, ex)
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
    ex.head === :... && return name_only(ex.args[1])
    ex.head === :module && return name_only(ex.args[2])
    error("unsupported expression $ex")
end

"""
    annotations_only(ex)

Return type annotations only. See also [`name_only`](@ref).
"""
function annotations_only(@nospecialize(ex))
    ex isa Symbol && return :()
    ex isa Expr || error("unsupported expression $ex")
    Meta.isexpr(ex, :...) && return annotations_only(ex.args[1])
    Meta.isexpr(ex, :(::)) && return ex.args[end]
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
    preserve_last_nothing::Bool = false
    rm_single_block::Bool = true
    alias_gensym::Bool = true
    renumber_gensym::Bool = true
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
- `preserve_last_nothing`: preserve the last `nothing` in the `begin ... end`.
- `rm_single_block`: remove single `begin ... end`.
- `alias_gensym`: replace `##<name>#<num>` with `<name>_<id>`.
- `renumber_gensym`: renumber the gensym id.

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
    ex = options.renumber_gensym ? renumber_gensym(ex) : ex
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
    ex = options.rm_nothing ? rm_nothing(ex; options.preserve_last_nothing) : ex
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

# Keyword Arguments

- `preserve_last_nothing`: if `true`, the last `nothing`
    will be preserved.
"""
function rm_nothing(ex; preserve_last_nothing::Bool=false)
    @match ex begin
        Expr(:block, args...) => begin
            if preserve_last_nothing && !isempty(args) && isnothing(last(args))
                Expr(:block, filter(x->x!==nothing, args)..., nothing)
            else
                Expr(:block, filter(x->x!==nothing, args)...)
            end
        end
        Expr(head, args...) => Expr(head, map(rm_nothing, args)...)
        _ => ex
    end
end

"""
    canonicalize_lambda_head(ex)

Canonicalize the `Expr(:function, Expr(:block, x, Expr(:(=), key, default)), body)` to

```julia
Expr(:function, Expr(:tuple, Expr(:parameters, Expr(:kw, key, default)), x), body)
```
"""
function canonicalize_lambda_head(ex)
    @match ex begin
        Expr(:function, Expr(:block, x, y), body) ||
                Expr(:function, Expr(:block, x, ::LineNumberNode, y), body) => begin
            Expr(:function, Expr(:tuple, Expr(:parameters, y), x), body)
        end

        Expr(:function, Expr(:block, x, Expr(:(=), key, default)), body) ||
            Expr(:function, Expr(:block, x, ::LineNumberNode, Expr(:(=), key, default)), body) => begin
            Expr(:function, Expr(:tuple, Expr(:parameters, Expr(:kw, key, default)), x), body) 
        end
        Expr(head, args...) => Expr(head, map(canonicalize_lambda_head, args)...)
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

"""
    renumber_gensym(ex)

Re-number gensym with counter from this expression.
Produce a deterministic gensym name for testing etc.
See also: [`alias_gensym`](@ref)
"""
renumber_gensym(ex) = renumber_gensym!(Dict{Symbol, Symbol}(), Dict{Symbol, Int}(), ex)

function renumber_gensym!(d::Dict{Symbol, Symbol}, count::Dict{Symbol, Int}, ex)
    function renumber(head, m)
        name = Symbol(m.captures[1])
        id = count[name] = get(count, name, 0) + 1
        return d[ex] = Symbol(head, name, "#", id)
    end

    if is_gensym(ex)
        haskey(d, ex) && return d[ex]
        gensym_str = String(ex)
        m = Base.match(r"##(.+)#\d+", gensym_str)
        m === nothing || return renumber("##", m)
        m = Base.match(r"#\d+#(.+)", gensym_str)
        m === nothing || return renumber("#", m)
        # might not be a gensym, ignore it
    end

    ex isa Expr || return ex
    args = map(ex.args) do x
        renumber_gensym!(d, count, x)
    end

    return Expr(ex.head, args...)
end

"""
    expr_map(f, c...)

Similar to `Base.map`, but expects `f` to return an expression,
and will concanate these expression as a `Expr(:block, ...)`
expression.

# Example

```jldoctest
julia> expr_map(1:10, 2:11) do i,j
           :(1 + \$i + \$j)
       end
quote
    1 + 1 + 2
    1 + 2 + 3
    1 + 3 + 4
    1 + 4 + 5
    1 + 5 + 6
    1 + 6 + 7
    1 + 7 + 8
    1 + 8 + 9
    1 + 9 + 10
    1 + 10 + 11
end
```
"""
function expr_map(f, c...)
    ex = Expr(:block)
    for args in zip(c...)
        push!(ex.args, f(args...))
    end
    return ex
end

"""
    nexprs(f, n::Int)

Create `n` similar expressions by evaluating `f`.

# Example

```jldoctest
julia> nexprs(5) do k
           :(1 + \$k)
       end
quote
    1 + 1
    1 + 2
    1 + 3
    1 + 4
    1 + 5
end
```
"""
nexprs(f, k::Int) = expr_map(f, 1:k)

"""
    Substitute(condition) -> substitute(f(expr), expr)

Returns a function that substitutes `expr` with
`f(expr)` if `condition(expr)` is true. Applied
recursively to all sub-expressions.

# Example

```jldoctest
julia> sub = Substitute() do expr
           expr isa Symbol && expr in [:x] && return true
           return false
       end;

julia> sub(_->1, :(x + y))
:(1 + y)
```
"""
struct Substitute
    condition
end

(sub::Substitute)(f) = Base.Fix1(sub, f)

function (sub::Substitute)(f, expr)
    if sub.condition(expr)
        return f(expr)
    elseif expr isa Expr
        return Expr(expr.head, map(sub(f), expr.args)...)
    else
        return expr
    end
end
