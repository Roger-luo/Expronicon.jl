"""
    @expr <expression>

Return the original expression object.

# Example

```julia
julia> ex = @expr x + 1
:(x + 1)
```
"""
macro expr(ex)
    return QuoteNode(ex)
end

"""
    @expr <type> <expression>

Return the expression in given type.

# Example

```julia
julia> ex = @expr JLKwStruct struct Foo{N, T}
           x::T = 1
       end
#= kw =# struct Foo{N, T}
    #= /home/roger/code/julia/Expronicon/test/analysis.jl:5 =#
    x::T = 1
end
```
"""
macro expr(type, ex)
    quote
        $type($(Expr(:quote, ex)))
    end |> esc
end

"""
    gensym_name(x::Symbol)

Return the gensym name.

!!! note
    Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).
"""
function gensym_name(x::Symbol)
    m = Base.match(r"##(.+)#\d+", String(x))
    m === nothing || return m.captures[1]
    m = Base.match(r"#\d+#(.+)", String(x))
    m === nothing || return m.captures[1]
    return "x"
end
