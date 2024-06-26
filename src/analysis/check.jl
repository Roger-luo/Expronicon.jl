"""
    is_valid_typevar(typevar)

Check if the given typevar is a valid typevar.

!!! note
    This function is based on [this discourse post](https://discourse.julialang.org/t/what-are-valid-type-parameters/471).
"""
function is_valid_typevar(typevar)
    @match typevar begin
        ::TypeVar => true
        ::QuoteNode => true # Symbol is QuoteNode inside Expr
        ::Type => true
        if isbitstype(typeof(typevar)) end => true
        ::Tuple => all(x->x isa Symbol || isbitstype(typeof(x)), typevar)
        _ => false
    end
end

"""
    is_literal(x)

Check if `x` is a literal value.
"""
function is_literal(x)
    !(x isa Expr || x isa Symbol || x isa GlobalRef)
end

"""
    is_tuple(ex)

Check if `ex` is a tuple expression, i.e. `:((a,b,c))`
"""
is_tuple(x) = Meta.isexpr(x, :tuple)

"""
    is_splat(ex)

Check if `ex` is a splat expression, i.e. `:(f(x)...)`
"""
is_splat(x) = Meta.isexpr(x, :(...))

"""
    is_gensym(s)

Check if `s` is generated by `gensym`.

!!! note
    Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).
"""
is_gensym(s::Symbol) = occursin("#", string(s))
is_gensym(s) = false

"""
    support_default(f)

Check if field type `f` supports default value.
"""
support_default(f) = false
support_default(f::JLKwField) = true

"""
    has_symbol(ex, name::Symbol)

Check if `ex` contains symbol `name`.
"""
function has_symbol(@nospecialize(ex), name::Symbol)
    ex isa Symbol && return ex === name
    ex isa Expr || return false
    return any(x->has_symbol(x, name), ex.args)
end

"""
    has_kwfn_constructor(def[, name = struct_name_plain(def)])

Check if the struct definition contains keyword function constructor of `name`.
The constructor name to check by default is the plain constructor which does
not infer any type variables and requires user to input all type variables.
See also [`struct_name_plain`](@ref).
"""
function has_kwfn_constructor(def, name = struct_name_plain(def))
    any(def.constructors) do fn::JLFunction
        isempty(fn.args) && fn.name == name
    end
end

"""
    has_plain_constructor(def, name = struct_name_plain(def))

Check if the struct definition contains the plain constructor of `name`.
By default the name is the inferable name [`struct_name_plain`](@ref).

# Example

```julia
def = @expr JLKwStruct struct Foo{T, N}
    x::Int
    y::N

    Foo{T, N}(x, y) where {T, N} = new{T, N}(x, y)
end

has_plain_constructor(def) # true

def = @expr JLKwStruct struct Foo{T, N}
    x::T
    y::N

    Foo(x, y) = new{typeof(x), typeof(y)}(x, y)
end

has_plain_constructor(def) # false
```

the arguments must have no type annotations.

```julia
def = @expr JLKwStruct struct Foo{T, N}
    x::T
    y::N

    Foo{T, N}(x::T, y::N) where {T, N} = new{T, N}(x, y)
end

has_plain_constructor(def) # false
```
"""
function has_plain_constructor(def, name = struct_name_plain(def))
    any(def.constructors) do fn::JLFunction
        fn.name == name || return false
        fn.kwargs === nothing || return false
        length(def.fields) == length(fn.args) || return false
        for (f, x) in zip(def.fields, fn.args)
            f.name === x || return false
        end
        return true
    end
end

"""
    is_function(def)

Check if given object is a function expression.
"""
function is_function(@nospecialize(def))
    @match def begin
        ::JLFunction => true
        ::Expr => begin
            line, doc, expr = split_doc(def)
            if !isnothing(doc)
                source = line
            end
            # TODO: generated expressions 
            split_function_tuple =  split_function_nothrow(expr)
            isnothing(split_function_tuple) && return false
            head, call, body = split_function_tuple
            split_head_tuple = @match head begin
                :(->) => split_anonymous_function_head_nothrow(call)
                h => split_function_head_nothrow(call)
            end
            isnothing(split_head_tuple) && return false 
            name, args, kw, whereparams, rettype = split_head_tuple

            true 
        end
        _ => false
    end
end

"""
    is_kw_function(def)

Check if a given function definition supports keyword arguments.
"""
function is_kw_function(@nospecialize(def))
    is_function(def) || return false

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

@deprecate is_kw_fn(def) is_kw_function(def)
@deprecate is_fn(def) is_function(def)

"""
    is_struct(ex)

Check if `ex` is a struct expression.
"""
function is_struct(@nospecialize(ex))
    ex isa Expr || return false
    return ex.head === :struct
end

"""
    is_struct_not_kw_struct(ex)

Check if `ex` is a struct expression excluding keyword struct syntax.
"""
function is_struct_not_kw_struct(ex)
    is_struct(ex) || return false
    body = ex.args[3]
    body isa Expr && body.head === :block || return false
    any(is_field_default, body.args) && return false
    return true
end

"""
    is_ifelse(ex)

Check if `ex` is an `if ... elseif ... else ... end` expression.
"""
function is_ifelse(@nospecialize(ex))
    ex isa Expr || return false
    return ex.head === :if
end

"""
    is_for(ex)

Check if `ex` is a `for` loop expression.
"""
function is_for(@nospecialize(ex))
    ex isa Expr || return false
    return ex.head === :for
end

"""
    is_field(ex)

Check if `ex` is a valid field expression.
"""
function is_field(@nospecialize(ex))
    @match ex begin
        :($name::$type = $default) => false
        :($(name::Symbol) = $default) => false
        name::Symbol => true
        :($name::$type) => true
        _ => false
    end
end

"""
    is_field_default(ex)

Check if `ex` is a `<field expr> = <default expr>` expression.
"""
function is_field_default(@nospecialize(ex))
    @match ex begin
        :($name::$type = $default) => true
        :($(name::Symbol) = $default) => true
        _ => false
    end
end

"""
    is_datatype_expr(ex)

Check if `ex` is an expression for a concrete `DataType`, e.g
`where` is not allowed in the expression.
"""
function is_datatype_expr(@nospecialize(ex))
    @match ex begin
        ::Symbol => true
        ::GlobalRef => true
        :($_{$_...}) => true
        :($_.$b) => is_datatype_expr(b)
        Expr(:curly, args...) => all(is_datatype_expr, args)
        _ => false
    end
end

"""
    is_matrix_expr(ex)

Check if `ex` is an expression for a `Matrix`.
"""
function is_matrix_expr(@nospecialize(ex))
    # row vector is also a Matrix
    Meta.isexpr(ex, :hcat) && return true

    # or it's a typed_vcat
    if Meta.isexpr(ex, :typed_vcat)
        args = ex.args[2:end]
    elseif Meta.isexpr(ex, :vcat)
        args = ex.args
    else
        return false
    end

    for row in args
        Meta.isexpr(row, :row) || return false
    end
    return true
end
