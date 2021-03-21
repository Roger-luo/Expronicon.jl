"""
collection of code generators.
"""
module CodeGen

using ..Types
using ..Transform
using ..Analysis
using MLStyle.MatchImpl
using MLStyle.AbstractPatterns
export codegen_ast,
    codegen_ast_kwfn,
    codegen_ast_struct,
    codegen_ast_struct_curly,
    codegen_ast_struct_head,
    codegen_ast_struct_body,
    codegen_match

function codegen_ast(def::JLIfElse)
    isempty(def.map) && return def.otherwise
    stmt = ex = Expr(:if)
    for (k, (cond, action)) in enumerate(def.map)
        push!(stmt.args, cond)
        push!(stmt.args, Expr(:block, action))

        if k !== length(def.map)
            push!(stmt.args, Expr(:elseif))
            stmt = stmt.args[end]
        end
    end
    def.otherwise === nothing || push!(stmt.args, def.otherwise)
    return ex
end

function codegen_ast(fn::JLFunction)
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
    push!(fn_def.args, fn.body)
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

function codegen_ast_kwfn(def::JLKwStruct, name = nothing)
    required_typevars = uninferrable_typevars(def)

    if name === nothing # constructor method
        name = isempty(required_typevars) ? def.name : Expr(:curly, def.name, required_typevars...)
        # do not generate kwfn if it's defined by the user
        if any(def.constructors) do fn
                isempty(fn.args) && fn.name == name
            end
            return
        end

        args = []
        whereparams = isempty(def.typevars) ? nothing : name_only.(def.typevars)
    else
        T = gensym(:T)
        ub = isempty(required_typevars) ? def.name : Expr(:curly, def.name, required_typevars...)
        args = [:(::Type{$T}), ]
        whereparams = [name_only.(def.typevars)..., :($T <: $ub)]
    end

    kwfn_def = JLFunction(;
        name = name,
        args = args,
        kwargs = map(def.fields) do field::JLKwField
            if field.default === no_default
                codegen_ast(field)
            else
                Expr(:kw, codegen_ast(field), field.default)
            end
        end,
        whereparams = whereparams
    )
    push!(kwfn_def.body.args, 
        Expr(:call, codegen_ast_struct_curly(def),
            [field.name for field in def.fields]...)
    )

    return codegen_ast(kwfn_def)
end

function codegen_ast_docstring(def, body)
    def.doc === nothing && return body
    Expr(:macrocall, GlobalRef(Core, Symbol("@doc")), def.line, def.doc, body)
end

"""
    codegen_ast_struct_curly(def)

Generate the struct name with curly if it is parameterized.

# Example

```julia
julia> using Expronicon.Types, Expronicon.CodeGen

julia> def = JLStruct(:(struct Foo{T} end))
struct Foo{T}
end

julia> codegen_ast_struct_curly(def)
:(Foo{T})
```
"""
function codegen_ast_struct_curly(def)
    name = def.name::Symbol
    if !isempty(def.typevars)
        name = Expr(:curly, name, def.typevars...)
    end
    return name
end

"""
    codegen_ast_struct_head(def)

Generate the struct head.

# Example

```julia
julia> using Expronicon.Types, Expronicon.CodeGen

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
    head = codegen_ast_struct_curly(def)

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

end
