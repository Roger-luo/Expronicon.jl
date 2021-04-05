# do nothing for other types
"""
    codegen_ast(def)

Generate Julia AST object `Expr` from a given syntax type.

# Example

One can generate the Julia AST object from a `JLKwStruct` syntax
type.

```julia
julia> def = @expr JLKwStruct struct Foo{N, T}
                  x::T = 1
              end
#= kw =# struct Foo{N, T}
    #= REPL[19]:2 =#
    x::T = 1
end

julia> codegen_ast(def)|>rm_lineinfo
quote
    struct Foo{N, T}
        x::T
    end
    begin
        function Foo{N, T}(; x = 1) where {N, T}
            Foo{N, T}(x)
        end
        function Foo{N}(; x::T = 1) where {N, T}
            Foo{N, T}(x)
        end
    end
end
```
"""
codegen_ast(ex) = ex

function codegen_ast(def::JLFor)
    lhead = Expr(:block)
    for (var, itr) in zip(def.vars, def.iterators)
        push!(lhead.args, :($var = $itr))
    end
    return Expr(:for, lhead, codegen_ast(def.kernel))
end

function codegen_ast(def::JLMatch)
    isempty(def.map) && return def.fallthrough
    body = Expr(:block)
    for (pattern, code) in def.map
        push!(body.args, :($pattern => $code))
    end
    push!(body.args, :(_ => $(def.fallthrough)))
    return init_cfg(gen_match(def.item, body, def.line, def.mod))
end

function codegen_ast(def::JLIfElse)
    isempty(def.map) && return def.otherwise
    stmt = ex = Expr(:if)
    for (k, (cond, action)) in enumerate(def.map)
        push!(stmt.args, cond)
        push!(stmt.args, Expr(:block, codegen_ast(action)))

        if k !== length(def.map)
            push!(stmt.args, Expr(:elseif))
            stmt = stmt.args[end]
        end
    end
    def.otherwise === nothing || push!(stmt.args, codegen_ast(def.otherwise))
    return ex
end

function codegen_ast(fn::JLFunction)
    # handle anonymous syntax: function (x; kw=value) end
    if fn.head === :function && fn.name === nothing &&
            isone(length(fn.args)) && isone(length(fn.kwargs))

        kw = fn.kwargs[1].args[1]
        va = fn.kwargs[1].args[2]
            
        return Expr(:function,
            Expr(:block, fn.args[1], :($kw = $va)),
            maybe_wrap_block(fn.body),
        )
    end

    fn_def = Expr(fn.head)

    if fn.name === nothing
        call = Expr(:tuple)
    else
        call = Expr(:call, fn.name)
    end

    if fn.kwargs !== nothing
        push!(call.args, Expr(:parameters, fn.kwargs...))
    end

    append!(call.args, fn.args)
    if fn.whereparams !== nothing
        call = Expr(:where, call, fn.whereparams...)
    end

    push!(fn_def.args, call)
    push!(fn_def.args, maybe_wrap_block(codegen_ast(fn.body)))
    return codegen_ast_docstring(fn, fn_def)
end

function codegen_ast(def::JLStruct)
    return codegen_ast_struct(def)    
end

function codegen_ast(def::JLKwStruct)
    quote
        $(codegen_ast_struct(def))
        $(codegen_ast_kwfn(def))
    end
end

function maybe_wrap_block(ex::Expr)
    ex.head === :block && return ex
    return Expr(:block, ex)
end

"""
    codegen_ast_kwfn(def[, name = nothing])

Generate the keyword function from a Julia struct definition.

# Example

```julia
julia> def = @expr JLKwStruct struct Foo{N, T}
                  x::T = 1
              end
#= kw =# struct Foo{N, T}
    #= REPL[19]:2 =#
    x::T = 1
end

julia> codegen_ast_kwfn(def)|>prettify
quote
    function Foo{N, T}(; x = 1) where {N, T}
        Foo{N, T}(x)
    end
    function Foo{N}(; x::T = 1) where {N, T}
        Foo{N, T}(x)
    end
end

julia> def = @expr JLKwStruct struct Foo
                  x::Int = 1
              end
#= kw =# struct Foo
    #= REPL[23]:2 =#
    x::Int = 1
end

julia> codegen_ast_kwfn(def)|>prettify
quote
    function Foo(; x = 1)
        Foo(x)
    end
    nothing
end
```
"""
function codegen_ast_kwfn(def, name = nothing)
    quote
        $(codegen_ast_kwfn_plain(def, name))
        $(codegen_ast_kwfn_infer(def, name))
    end
end

"""
    codegen_ast_kwfn_plain(def[, name = nothing])

Generate the plain keyword function that does not infer type variables.
So that one can use the type conversions defined by constructors.
"""
function codegen_ast_kwfn_plain(def, name = nothing)
    struct_name = struct_name_plain(def)

    if name === nothing # constructor method
        name = struct_name
        args = []
        whereparams = isempty(def.typevars) ? nothing : name_only.(def.typevars)
    else
        @gensym T
        args = [:(::Type{$T}), ]
        whereparams = [name_only.(def.typevars)..., :($T <: $(def.name))]
    end

    # do not generate kwfn if it's defined by the user
    has_kwfn_constructor(def, name) && return

    kwfn_def = JLFunction(;
        name = name,
        args = args,
        # NOTE:
        # do not use type annotations so that
        # we can use type conversion defined
        # by the constructors.
        kwargs = codegen_ast_fields(def.fields; just_name=true),
        whereparams = whereparams,
        body = Expr(:call, struct_name, [field.name for field in def.fields]...)
    )

    return codegen_ast(kwfn_def)
end

"""
    codegen_ast_kwfn_infer(def, name = nothing)

Generate the keyword function that infers the type.
"""
function codegen_ast_kwfn_infer(def, name = nothing)
    # no typevars to infer, use the plain one
    isempty(def.typevars) && return
    struct_name = struct_name_inferable(def)
    requires = uninferrable_typevars(def)

    if name === nothing # constructor method
        name = struct_name
        args = []
        whereparams = isempty(requires) ? nothing : requires
    else
        @gensym T
        ub = isempty(requires) ? def.name : Expr(:curly, def.name, requires...)
        args = [:(::Type{$T}), ]
        whereparams = [requires..., :($T <: $ub)]
    end

    # do not generate kwfn if it's defined by the user
    has_kwfn_constructor(def, name) && return

    kwfn_def = JLFunction(;
        name = name,
        args = args,
        # NOTE:
        # enable type annotations to infer typevars
        kwargs = codegen_ast_fields(def.fields; just_name=true),
        whereparams = whereparams,
        body = Expr(:call, struct_name,
            [field.name for field in def.fields]...)
    )
    return codegen_ast(kwfn_def)
end

"""
    codegen_ast_fields(fields; just_name::Bool=true)

Generate a list of Julia AST object for each field, only generate
a list of field names by default, option `just_name` can be turned
off to call [`codegen_ast`](@ref) on each field object.
"""
function codegen_ast_fields(fields; just_name::Bool=true)
    map(fields) do field
        name = just_name ? field.name : codegen_ast(field)
        support_default(field) || return name

        if field.default === no_default
            name
        else
            Expr(:kw, name, field.default)
        end
    end
end

"""
    struct_name_plain(def)

Plain constructor name. See also [`struct_name_inferable`](@ref).

# Example

```julia
julia> def = @expr JLKwStruct struct Foo{N, Inferrable}
    x::Inferrable = 1
end

julia> struct_name_plain(def)
:(Foo{N, Inferrable})
```
"""
function struct_name_plain(def)
    isempty(def.typevars) && return def.name
    return Expr(:curly, def.name, name_only.(def.typevars)...)
end

"""
    struct_name_inferable(def)

Constructor name that assume some of the type variables is inferred.
See also [`struct_name_plain`](@ref).

# Example

```julia
julia> def = @expr JLKwStruct struct Foo{N, Inferrable}
    x::Inferrable = 1
end

julia> struct_name_inferable(def)
:(Foo{N})
```
"""
function struct_name_inferable(def)
    isempty(def.typevars) && return def.name
    required_typevars = uninferrable_typevars(def)
    return Expr(:curly, def.name, required_typevars...)
end

function codegen_ast_docstring(def, body)
    def.doc === nothing && return body
    Expr(:macrocall, GlobalRef(Core, Symbol("@doc")), def.line, def.doc, body)
end

"""
    codegen_ast_struct_head(def)

Generate the struct head.

# Example

```julia
julia> using Expronicon

julia> def = JLStruct(:(struct Foo{T} end))
struct Foo{T}
end

julia> codegen_ast_struct_head(def)
:(Foo{T})

julia> def = JLStruct(:(struct Foo{T} <: AbstractArray end))
struct Foo{T} <: AbstractArray
end

julia> codegen_ast_struct_head(def)
:(Foo{T} <: AbstractArray)
```
"""
function codegen_ast_struct_head(def)
    head = def.name::Symbol
    if !isempty(def.typevars)
        head = Expr(:curly, head, def.typevars...)
    end

    if def.supertype !== nothing
        head = Expr(:(<:), head, def.supertype)
    end
    return head
end

"""
    codegen_ast_struct_body(def)

Generate the struct body.

# Example

```julia
julia> def = JLStruct(:(struct Foo
           x::Int
           
           Foo(x::Int) = new(x)
       end))
struct Foo
    x::Int
end

julia> codegen_ast_struct_body(def)
quote
    #= REPL[15]:2 =#
    x::Int
    Foo(x::Int) = begin
            #= REPL[15]:4 =#
            new(x)
        end
end
```
"""
function codegen_ast_struct_body(def)
    body = Expr(:block)
    for field in def.fields
        field.line === nothing || push!(body.args, field.line)
        field.doc === nothing || push!(body.args, field.doc)
        push!(body.args, codegen_ast(field))
    end

    for constructor in def.constructors
        push!(body.args, codegen_ast(constructor))
    end

    body = flatten_blocks(body)
    append!(body.args, def.misc)
    return body
end

"""
    codegen_ast_struct(def)

Generate pure Julia struct `Expr` from struct definition. This is equivalent
to `codegen_ast` for `JLStruct`. See also [`codegen_ast`](@ref).

# Example

```julia-repl
julia> def = JLKwStruct(:(struct Foo
           x::Int=1
           
           Foo(x::Int) = new(x)
       end))
struct Foo
    x::Int = 1
end

julia> codegen_ast_struct(def)
:(struct Foo
      #= REPL[21]:2 =#
      x::Int
      Foo(x::Int) = begin
              #= REPL[21]:4 =#
              new(x)
          end
  end)
```
"""
function codegen_ast_struct(def)
    head = codegen_ast_struct_head(def)
    body = codegen_ast_struct_body(def)
    ex = Expr(:struct, def.ismutable, head, body)
    return codegen_ast_docstring(def, ex)
end

function codegen_ast(def::Union{JLField, JLKwField})
    return if def.type === Any
        def.name
    else
        :($(def.name)::$(def.type))
    end
end

"""
    codegen_match(f, x[, line::LineNumberNode=LineNumberNode(0), mod::Module=Main])

Generate a zero dependency match expression using MLStyle code generator,
the syntax is identical to MLStyle.

# Example

```julia
codegen_match(:x) do
    quote
        1 => true
        2 => false
        _ => nothing
    end
end
```

This code generates the following corresponding MLStyle expression

```julia
@match x begin
    1 => true
    2 => false
    _ => nothing
end
```
"""
function codegen_match(f, x, line::LineNumberNode=LineNumberNode(0), mod::Module=Main)
    return init_cfg(gen_match(x, f(), line, mod))
end
