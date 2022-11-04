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

struct ExprNotEqual <: Exception
    lhs
    rhs
end

function Base.showerror(io::IO, err::ExprNotEqual)
    printstyled(io, "expression not equal due to:"; color=:red)
    println(io)
    println(io, "  lhs: ", err.lhs)
    print(io, "  rhs: ", err.rhs)
end

struct EmptyLine end
const empty_line = EmptyLine()
Base.show(io::IO, ::EmptyLine) = print(io, "<empty line>")

function locate_non_equal_expr(m::Module, lhs, rhs)
    lhs isa Expr && rhs isa Expr || return lhs, rhs

    # always make sure the lhs is the one has less args
    if length(lhs.args) > length(rhs.args)
        lhs, rhs = rhs, lhs
    end

    not_equals = Tuple{Any, Any}[]
    for (l, r) in zip(lhs.args, rhs.args)
        if !compare_expr(m, l, r)
            push!(not_equals, (l, r))
        end
    end

    append!(not_equals, map(rhs.args[length(lhs.args)+1:end]) do r
        return empty_line, r
    end)

    @show not_equals
    # all args are not equal
    # cannot narrow down the location
    if length(not_equals) == length(rhs.args)
        return lhs, rhs
    else # some args are equal
        return locate_non_equal_expr(m, not_equals[1]...)
    end
end

function check_expr_equal(m::Module, lhs, rhs)
    lhs = prettify(lhs; preserve_last_nothing=true, alias_gensym=false)
    rhs = prettify(rhs; preserve_last_nothing=true, alias_gensym=false)
    compare_expr(m, lhs, rhs) && return true
    lhs, rhs = locate_non_equal_expr(m, lhs, rhs)
    throw(ExprNotEqual(lhs, rhs))
end

"""
    @test_expr <type> <ex>

Test if the syntax type generates the same expression `ex`. Returns the
corresponding syntax type instance. Requires `using Test` before using
this macro.

# Example

```julia
def = @test_expr JLFunction function (x, y)
    return 2
end
@test is_kw_fn(def) == false
```
"""
macro test_expr(type, ex)
    @gensym def generated_expr original_expr
    quote
        $def = Expronicon.@expr $type $ex
        $Base.show(stdout, MIME"text/plain"(), $def)
        $generated_expr = $codegen_ast($def)
        $original_expr = $(Expr(:quote, ex))
        @test $(Expr(
            :block, __source__,
            :($check_expr_equal($__module__, $generated_expr, $original_expr))
        ))
        $def
    end |> esc
end

"""
    @test_expr <expr> == <expr>

Test if two expression is equivalent semantically, this uses `compare_expr`
to decide if they are equivalent, ignores things such as `LineNumberNode`
generated `Symbol` in `Expr(:curly, ...)` or `Expr(:where, ...)`.
"""
macro test_expr(ex::Expr)
    ex.head === :call && ex.args[1] === :(==) || error("expect <expr> == <expr>, got $ex")
    lhs, rhs = ex.args[2], ex.args[3]
    quote
        $__source__
        @test $check_expr_equal($__module__, $lhs, $rhs)
    end |> esc
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

struct AnalysisError <: Exception
    expect::String
    got
end

anlys_error(expect, got) = throw(AnalysisError(expect, got))

function Base.show(io::IO, e::AnalysisError)
    print(io, "expect ", e.expect, " expression, got ", e.got, ".")
end

"""
    compare_expr([m=Main], lhs, rhs)

Compare two expression of type `Expr` or `Symbol` semantically, which:

1. ignore the detail value `LineNumberNode` in comparision
2. ignore the detailed name of typevars in `Expr(:curly, ...)` or `Expr(:where, ...)`

!!! tips

    This function is usually combined with [`prettify`](@ref)
    with `preserve_last_nothing=true` and `alias_gensym=false`.

This gives a way to compare two Julia expression semantically which means
although some details of the expression is different but they should
produce the same lowered code.
"""
compare_expr(lhs, rhs) = compare_expr(Main, lhs, rhs)

function compare_expr(m::Module, lhs, rhs)
    @switch (lhs, rhs) begin
        @case (::Symbol, ::Symbol)
            lhs === rhs
        @case (a::Module, b) || (b, a::Module)
            mod = guess_module(m, b)
            isnothing(mod) && return false
            return a === mod
        @case (a::QuoteNode, :(Symbol($b))) || (:(Symbol($b)), a::QuoteNode)
            # Symbol is not imported, e.g baremodule
            isdefined(m, :Symbol) || return false
            return a.value === Symbol(b)
        @case (Expr(:curly, name, lhs_vars...), Expr(:curly, &name, rhs_vars...))
            all(map(compare_vars, lhs_vars, rhs_vars))
        @case (Expr(:where, lbody, lparams...), Expr(:where, rbody, rparams...))
            compare_expr(m, lbody, rbody) &&
                all(map(compare_vars, lparams, rparams))
        @case (:($name_a::$type_a), :($name_b::$type_b))
            compare_expr(m, name_a, name_b) &&
                compare_expr(m, guess_type(m, type_a), guess_type(m, type_b))
        @case (:(::$(type_a)), :(::$(type_b)))
            compare_expr(m, guess_type(m, type_a), guess_type(m, type_b))
        @case (:($name_a{$(typevars_a...)}), :($name_b{$(typevars_b...)}))
            type_a = guess_type(m, lhs)
            type_b = guess_type(m, rhs)
            if type_a isa Type || type_b isa Type
                return type_a === type_b
            else
                compare_expr(m, guess_type(m, name_a),
                    guess_type(m, name_b)) || return false
                return all(map(typevars_a, typevars_b) do l, r
                    compare_expr(m, guess_type(m, l), guess_type(m, r))
                end)
            end
        @case (:($name_a.$sub_a), :($name_b.$sub_b))
            mod_a = guess_module(m, name_a)
            mod_b = guess_module(m, name_b)
            return mod_a === mod_b && compare_expr(mod_a, sub_a, sub_b)
        @case (Expr(head, largs...), Expr(&head, rargs...))
                isempty(largs) && isempty(rargs) ||
            (length(largs) == length(rargs) &&
                all(map((l,r)->compare_expr(m, l, r), largs, rargs)))
        # ignore LineNumberNode
        @case (::LineNumberNode, ::LineNumberNode)
            true
        @case (:nothing, nothing) || (nothing, :nothing) ||
            (:missing, missing) || (missing, :missing) ||
            (:true, true) || (true, :true) ||
            (:false, false) || (false, :false) # literals
            return true
        @case (::Expr, ::Expr) || (::Expr, ::Symbol) || (::Symbol, ::Expr)
            return false
        @case (a, b::Expr) || (b::Expr, a)
            return a == Base.eval(m, b)
        @case _
            return lhs == rhs
    end
end

function guess_module(m::Module, ex)
    @switch ex begin
        @case ::Module
            return ex
        @case ::Symbol && if isdefined(m, ex) end
            return getproperty(m, ex)
        @case :($name.$sub)
            mod = guess_module(m, name)
            if mod isa Module
                return guess_module(mod, sub)
            else
                return
            end
        @case _
            return
    end
end

function guess_type(m::Module, ex)
    @switch ex begin
        @case ::Type
            return ex
        @case ::Symbol
            isdefined(m, ex) || return ex
            return getproperty(m, ex)
        @case :($name{$(typevars...)})
            type = guess_type(m, name)
            typevars = map(typevars) do typevar
                guess_type(m, typevar)
            end

            if all(x->x isa Type, typevars)
                return type{typevars...}
            else
                return Expr(:curly, type, typevars...)
            end
        @case _
            return ex
    end
end

"""
    compare_vars(lhs, rhs)

Compare two expression by assuming all `Symbol`s are variables,
thus their value doesn't matter, only where they are matters under
this assumption. See also [`compare_expr`](@ref).
"""
function compare_vars(lhs, rhs)
    @switch (lhs, rhs) begin
        @case (::Symbol, ::Symbol)
            true
        @case (Expr(head, largs...), Expr(&head, rargs...))
            all(map(compare_vars, largs, rargs))
        # ignore LineNumberNode
        @case (::LineNumberNode, ::LineNumberNode)
            true
        @case _
            lhs == rhs
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
    is_gensym(s)

Check if `s` is generated by `gensym`.

!!! note
    Borrowed from [MacroTools](https://github.com/FluxML/MacroTools.jl).
"""
is_gensym(s::Symbol) = occursin("#", string(s))
is_gensym(s) = false

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

"""
    support_default(f)

Check if field type `f` supports default value.
"""
support_default(f) = false
support_default(f::JLKwField) = true

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
        Expr(:function, _, _) => true
        Expr(:(=), _, _) => true
        Expr(:(->), _, _) => true
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

"""
    split_doc(ex::Expr) -> line, doc, expr

Split doc string from given expression.
"""
function split_doc(ex::Expr)
    if ex.head === :macrocall && ex.args[1] == GlobalRef(Core, Symbol("@doc"))
        return ex.args[2], ex.args[3], ex.args[4]
    else
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
    JLFunction(ex::Expr)

Create a `JLFunction` object from a Julia function `Expr`.

# Example

```julia
julia> JLFunction(:(f(x) = 2))
f(x) = begin
    #= REPL[37]:1 =#    
    2    
end
```
"""
function JLFunction(ex::Expr)
    line, doc, expr = split_doc(ex)
    head, call, body = split_function(expr)
    name, args, kw, whereparams, rettype = split_function_head(call)
    JLFunction(head, name, args, kw, rettype, whereparams, body, line, doc)
end

"""
    JLStruct(ex::Expr)

Create a `JLStruct` object from a Julia struct `Expr`.

# Example

```julia
julia> JLStruct(:(struct Foo
           x::Int
       end))
struct Foo
    #= REPL[38]:2 =#
    x::Int
end
```
"""
function JLStruct(ex::Expr)
    line, doc, expr = split_doc(ex)
    ismutable, typename, typevars, supertype, body = split_struct(expr)

    fields, constructors, misc = JLField[], JLFunction[], []
    field_doc, field_line = nothing, nothing

    body = flatten_blocks(body)

    for each in body.args
        m = parse_field_if_match(typename, each)
        if m isa String
            field_doc = m
        elseif m isa LineNumberNode
            field_line = m
        elseif m isa NamedTuple
            push!(fields, JLField(;m..., doc=field_doc, line=field_line))
            field_doc, field_line = nothing, nothing
        elseif m isa JLFunction
            push!(constructors, m)
        else
            push!(misc, m)
        end
    end
    JLStruct(typename, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

"""
    JLKwStruct(ex::Expr, typealias=nothing)

Create a `JLKwStruct` from given Julia struct `Expr`, with an option to attach
an alias to this type name.

# Example

```julia
julia> JLKwStruct(:(struct Foo
           x::Int = 1
       end))
#= kw =# struct Foo
    #= REPL[39]:2 =#
    x::Int = 1
end
```
"""
function JLKwStruct(ex::Expr, typealias=nothing)
    line, doc, expr = split_doc(ex)
    ismutable, typename, typevars, supertype, body = split_struct(expr)

    fields, constructors, misc = JLKwField[], JLFunction[], []
    field_doc, field_line = nothing, nothing
    body = flatten_blocks(body)
    for each in body.args
        m = parse_field_if_match(typename, each, true)
        if m isa String
            field_doc = m
        elseif m isa LineNumberNode
            field_line = m
        elseif m isa NamedTuple
            field = JLKwField(;m..., doc=field_doc, line=field_line)
            push!(fields, field)
            field_doc, field_line = nothing, nothing
        elseif m isa JLFunction
            push!(constructors, m)
        else
            push!(misc, m)
        end
    end
    JLKwStruct(typename, typealias, ismutable, typevars, supertype, fields, constructors, line, doc, misc)
end

"""
    JLIfElse(ex::Expr)

Create a `JLIfElse` from given Julia ifelse `Expr`.

# Example

```julia
julia> ex = :(if foo(x)
             x = 1 + 1
         elseif goo(x)
             y = 1 + 2
         else
             error("abc")
         end)
:(if foo(x)
      #= REPL[41]:2 =#
      x = 1 + 1
  elseif #= REPL[41]:3 =# goo(x)
      #= REPL[41]:4 =#
      y = 1 + 2
  else
      #= REPL[41]:6 =#
      error("abc")
  end)

julia> JLIfElse(ex)
if foo(x)
    begin
        #= REPL[41]:2 =#        
        x = 1 + 1        
    end
elseif begin
    #= REPL[41]:3 =#    
    goo(x)    
end
    begin
        #= REPL[41]:4 =#        
        y = 1 + 2        
    end
else
    begin
        #= REPL[41]:6 =#        
        error("abc")        
    end
end
```
"""
function JLIfElse(ex::Expr)
    ex.head === :if || error("expect an if ... elseif ... else ... end expression")
    conds, stmts, otherwise = split_ifelse(ex)
    return JLIfElse(conds, stmts, otherwise)
end

"""
    JLFor(ex::Expr)

Create a `JLFor` from given Julia for loop expression.

# Example

```julia
julia> ex = @expr for i in 1:10, j in 1:j
           M[i, j] += 1
       end
:(for i = 1:10, j = 1:j
      #= REPL[3]:2 =#
      M[i, j] += 1
  end)

julia> jl = JLFor(ex)
for i in 1 : 10,
    j in 1 : j
    #= loop body =#
    begin
        #= REPL[3]:2 =#        
        M[i, j] += 1        
    end
end

julia> jl.vars
2-element Vector{Any}:
 :i
 :j

julia> jl.iterators
2-element Vector{Any}:
 :(1:10)
 :(1:j)
```
"""
function JLFor(ex::Expr)
    vars, itrs, body = split_forloop(ex)
    return JLFor(vars, itrs, body)
end

function Base.:(==)(lhs::JLKwField, rhs::JLKwField)
    lhs.name === rhs.name || return false
    compare_expr(lhs.type, rhs.type) || return false
    return compare_expr(lhs.default, rhs.default)
end

# function Base.:(==)(lhs::JLFunction, rhs::JLFunction)
#     lhs.name == rhs.name || return false
#     mapreduce(&, lhs.args, rhs.args) do x, y
#         return compare_expr(x, y)
#     end || return false
#     compare_maybe_list(lhs.kwargs, rhs.kwargs) || return false
#     compare_maybe_list(lhs.whereparams, rhs.whereparams) || return false
#     compare_expr(prettify(lhs.body), prettify(rhs.body)) || return false
#     return true
# end

# function compare_maybe_list(lhs, rhs)
#     @match (lhs, rhs) begin
#         (::Vector, nothing) || (nothing, ::Vector) => false
#         (::Vector, ::Vector) => mapreduce(&, lhs, rhs.kwargs) do x, y
#             return compare_expr(x, y)
#         end
#         (nothing, nothing) => true
#         _ => false
#     end
# end

function parse_field_if_match(typename::Symbol, expr, default::Bool=false)
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