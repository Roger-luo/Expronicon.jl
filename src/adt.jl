module ADT

export @adt, @type

# ## Why not Unityper? But another version.
# The original goal of Unityper is to implement
# a type stable algebra expression in an extensible
# but still efficient way with memory aligned
# together.
#
# On the other hand, MLStyle provided something called
# algebra data type that supports native pattern matching
# from MLStyle. This gives very convenient syntatic pattern
# matching for manipulating a user defined expression type.
#
# This implementation unifies these two approaches: we want
# good performance via aligned storage and we also want elegant
# syntatic pattern match.
#
# We want this to eventually replace the algebra data type
# in MLStyle, so we built one from scratch using the meta-programming
# tools from MLStyle&Expronicon. Noteworthy, it takes only half of the
# lines of code comparing to Unityper but having more features. The
# codebase is organized in a pass fashion on a simple IR for ADT.
# So it's very simple to read and extend.

# TODO:
# support auto-conversion when constructing
# so we have similar behaviour as a Julia struct

using MLStyle
using MLStyle.MatchImpl: and, P_capture, guard
using Expronicon

adt_fieldnames(::Type) = error("adt_fieldnames: expect an algebra data type declared by @adt")
adt_parent_type(::Type) = error("adt_parent_type: expect an algebra data type declared by @adt")
adt_property_masks(::Type) = error("adt_property_masks: expect an algebra data type declared by @adt")

struct ADTTypeDef
    m::Module
    nshared_fields::Int
    def::JLKwStruct
    types::Vector{JLKwStruct}
    type_masks::Dict{Symbol, Vector{Int}}
end

function Base.show(io::IO, ::MIME"text/plain", def::ADTTypeDef)
    return print_expr(io, codegen_ast_struct(def.def))
end

function ADTTypeDef(m::Module, ex::Expr)
    ex.head === :block || throw(ArgumentError("expect begin ... end"))
    ex = rm_lineinfo(ex)
    @switch ex.args[1] begin
        @case Expr(:macrocall, Symbol("@type"), _, adt_type_ex)
        @case _
            throw(ArgumentError("expect @type"))
    end

    def = JLKwStruct(adt_type_ex)
    any(def.fields) do field
        field.name === :type
    end && error("shared field name `type` is a reserved name")
    nshared_fields = length(def.fields)
    def, types = parse_adt_expr!(m, def, ex.args[2:end])
    def, type_masks = scan_fields!(m, def, types)
    return ADTTypeDef(m, nshared_fields, def, types, type_masks)
end

"""
    @adt begin
        @type struct <ADT type name>
            <shared fields>
        end
        
        struct adt_type_a
            <fields>
        end

        struct adt_type_b
            <fields>
            <constructors>
        end
    end

Create an Algebra Data Type (ADT) with a compact memory
layout. This mimics the rust enum using Julia struct. The
idea is highly inspired by [Unityper](https://github.com/YingboMa/Unityper.jl/),
but this one supports MLStyle's pattern matching natively.

# Examples

the following code

```julia
@adt begin
    @type struct Term
        name::Symbol
    end

    struct pow
        base
        pow::Int
    end

    struct literal
    end
end
```

is equivalent to

```julia
struct Term
    type::Symbol
    name::Symbol # use when type is :literal
    base # use when type is :pow
    pow # use when type is :pow
end
```
"""
macro adt(ex::Expr)
    esc(adt_m(__module__, ex))
end

macro type(ex::Expr)
    error("@type is only available inside @adt")
end

function adt_m(m::Module, ex::Expr)
    def = ADTTypeDef(m, ex)
    return quote
        $(codegen_ast_struct(def.def))
        $(emit_type_trait(def))
        $(emit_getproperty(def))
        $(emit_propertynames(def))
        $(emit_adt_fieldnames(def))
        $(emit_setproperty(def))
        $(emit_constructors(def))
        $(emit_adt_property_masks(def))
        $(emit_adt_parent_type(def))
        $(emit_pattern_uncall(def))
        # $(emit_show(def))
        nothing
    end
end

function eval_type_expr!(m::Module, def::JLKwStruct)
    for f in def.fields
        f.type = expr_to_type(m, f.type, def.typevars)
    end
    return def
end

function parse_adt_expr!(m, def::JLKwStruct, type_ex::Vector)
    eval_type_expr!(m, def)
    types = JLKwStruct[]
    for each in type_ex
        is_struct(each) || error("expect struct definition only inside @adt")
        type_def = JLKwStruct(each)
        isempty(type_def.typevars) || error("data types cannot have type parameters")
        eval_type_expr!(m, type_def)
        all(type_def.fields) do field
            isbitstype(field.type) || return true
            return !(field.default === no_default)
        end || error("expect default value for non-shared bits-type fields")
        push!(types, type_def)
    end
    pushfirst!(def.fields, JLKwField(;name=:type, type=Symbol))
    return def, types
end

function scan_fields!(m::Module, def::JLKwStruct, types::Vector{JLKwStruct})
    type_masks = Dict{Symbol, Vector{Int}}()
    new_field_count = 1

    for each in types
        mask = type_masks[each.name] = Vector{Int}(undef, length(each.fields))
        wanted_field_types = []
        for each_field in each.fields
            type = expr_to_type(m, each_field.type, def.typevars)
            if each_field.default === no_default && isbitstype(type)
                type = Union{Nothing, type}
            elseif isbitstype(type)
            else
                type = Any
            end
            push!(wanted_field_types, type)
        end

        available_field_types = map(def.fields) do f
            expr_to_type(m, f.type, def.typevars)
        end

        available_field_flags = fill(true, length(available_field_types))

        for (field_idx, wanted_type) in enumerate(wanted_field_types)
            idx = findfirst_available_field(
                wanted_type,
                available_field_flags,
                available_field_types
            )
            if isnothing(idx)
                push!(def.fields, JLKwField(;
                        name=Symbol("##", :field, "#", new_field_count),
                        type=wanted_type,
                        # NOTE: only bitstype exists here otherwise it must be Any
                        default=wanted_type === Any ? nothing : each.fields[field_idx].default,
                    )
                )
                mask[field_idx] = length(def.fields)
                new_field_count += 1
            else
                available_field_flags[idx] = false
                mask[field_idx] = idx
            end
        end
    end
    return def, type_masks
end

function expr_to_type(m, type_ex, typevars)
    if any(typevar->has_symbol(type_ex, typevar), typevars)
        return type_ex
    else
        # NOTE: change this to expr-based?
        return Base.eval(m, type_ex)
    end
end

function findfirst_available_field(wanted_type, available_field_flags::Vector{Bool}, available_field_types::Vector)
    for (i, (available, t)) in enumerate(zip(available_field_flags, available_field_types))
        available || continue
        t isa Type || continue # cannot judge
        wanted_type isa Type || continue
        wanted_type <: t && return i
    end
    return
end

emit_adt_type(x) = xcall(Core, :getfield, x, QuoteNode(:type))

function emit_ifelse_field(f, def::ADTTypeDef, value::Symbol, name::Symbol)
    adt_type = emit_adt_type(value)
    body = JLIfElse()
    for each in def.types
        type_name = each.name
        mask = def.type_masks[each.name]
        type_body = JLIfElse()
        for (field, idx) in zip(each.fields, mask)
            type_body[:($name === $(QuoteNode(field.name)))] = f(idx, field.type)
        end

        msg = Expr(:string, "type $type_name has no field ", name)
        type_body.otherwise = :(error($msg))
        body[:($adt_type === $(QuoteNode(type_name)))] = codegen_ast(type_body)
    end
    body.otherwise = :(error(string("invalid ADT type ", $adt_type)))
    return body
end

function emit_getproperty(def::ADTTypeDef)
    body = emit_ifelse_field(def, :value, :name) do idx, type
        :(return $(xcall(Core, :getfield, :value, idx))::$(type))
    end

    adt_type = emit_adt_type(:value)
    getproperty_ex = JLFunction(;
        name=:($Base.getproperty),
        args=[:(value::$(def.def.name)), :(name::Symbol)],
        body=quote
            name === :type && return $adt_type
            return $(codegen_ast(body))
        end
    )
    return codegen_ast(getproperty_ex)
end

function emit_propertynames(def::ADTTypeDef)
    adt_type = emit_adt_type(:x)
    body = JLIfElse()
    for type in def.types
        body[:(x.type === $(QuoteNode(type.name)))] = quote
            return $(xtuple(QuoteNode(:type), map(x->QuoteNode(x.name), type.fields)...))
        end
    end
    body.otherwise = :(error(string("invalid ADT type ", $adt_type)))

    propertynames_ex = JLFunction(;
        name=:($Base.propertynames),
        args=[:(x::$(def.def.name)), Expr(:kw, :(private::Bool), false)],
        body=codegen_ast(body)
    )
    return codegen_ast(propertynames_ex)
end

function emit_adt_fieldnames(def::ADTTypeDef)
    return expr_map(def.types) do type
        quote
            function $ADT.adt_fieldnames(::Type{<:$(type.name)})
                return $(xtuple(QuoteNode(:type), map(x->QuoteNode(x.name), type.fields)...))
            end
        end
    end
end

function emit_setproperty(def::ADTTypeDef)
    if !def.def.ismutable
        msg = "setproperty!: immutable struct of type $(def.def.name) cannot be changed"
        return quote
            function $Base.setproperty!(value::$(def.def.name), name::Symbol, x)
                error($msg)
            end
        end
    end

    body = emit_ifelse_field(def, :value, :name) do idx, type
        quote
            x isa $type || throw(TypeError(:setproperty!, "", $type, typeof(x)))
            return $(xcall(Core, :setfield!, :value, idx, :x))
        end
    end

    setproperty_ex = JLFunction(;
        name=:($Base.setproperty!),
        args=[:(value::$(def.def.name)), :(name::Symbol), :x],
        body=codegen_ast(body),
    )
    return codegen_ast(setproperty_ex)
end

function emit_adt_parent_type(def::ADTTypeDef)
    return expr_map(def.types) do type
        :($ADT.adt_parent_type(::Type{<:$(type.name)}) = $(def.def.name))
    end
end

function emit_show(def::ADTTypeDef)
    adt_type = emit_adt_type(:x)
    annotation = "$(def.def.name)::"
    return quote
        function $Base.show(io::$IO, x::$(def.def.name))
            print(io, $(annotation), $adt_type, "(")
            names = propertynames(x)
            for idx in eachindex(names)
                name = names[idx]
                name === :type && continue
                show(io, getproperty(x, name))
                if idx != lastindex(names)
                    print(io, ", ")
                end
            end
            print(io, ")")
        end
    end
end

function emit_type_trait(adt::ADTTypeDef)
    return expr_map(adt.types) do type
        quote
            struct $(type.name)
                1 + 1 # get rid of the default constructor
            end
            $(codegen_ast_kwfn(type))
        end
    end
end

function emit_constructors(adt::ADTTypeDef)
    return expr_map(adt.types) do type
        if isempty(type.constructors)
            return emit_default_constructor(adt, type)
        else # merge custom constructor
            return expr_map(type.constructors) do cons
                cons.body = replace_new(adt, type, cons)
                codegen_ast(cons)
            end
        end
    end
end

function replace_new(adt::ADTTypeDef, typedef::JLKwStruct, cons::JLFunction, ex=cons.body)
    mask = adt.type_masks[typedef.name]
    @switch ex begin
        @case :(new($(args...)))
            ex = Expr(:call, adt.def.name, QuoteNode(typedef.name))
            args_ptr = 1
            for idx in 2:length(adt.def.fields) # skip type
                if idx in mask
                    push!(ex.args, args[args_ptr])
                    args_ptr += 1
                else
                    push!(ex.args, adt.def.fields[idx].default)
                end
            end
            return ex
        @case Expr(head, args...)
            args = map(args) do x
                replace_new(adt, typedef, cons, x)
            end
            return Expr(head, args...)
        @case _
            return ex
    end
end

function emit_default_constructor(adt::ADTTypeDef, typedef::JLKwStruct)
    ndef_fields = length(adt.def.fields)
    
    args = []
    term_args = Vector{Any}(undef, ndef_fields)
    term_args[1] = QuoteNode(typedef.name) # type

    for shared_field_ptr in 2:adt.nshared_fields+1
        field = adt.def.fields[shared_field_ptr]
        name = field.name
        type = field.type
        term_args[shared_field_ptr] = name
        push!(args, :($name::$type))
    end

    field_ptr = 1
    for storage_field_ptr in adt.nshared_fields+2:ndef_fields
        if storage_field_ptr in adt.type_masks[typedef.name]
            field = typedef.fields[field_ptr]
            name = field.name
            type = field.type
            term_args[storage_field_ptr] = name
            push!(args, :($name::$type))
            field_ptr += 1
        else
            term_args[storage_field_ptr] = adt.def.fields[storage_field_ptr].default
        end
    end

    jlfn = JLFunction(;
        typedef.name,
        args,
        body=quote
            $(adt.def.name)($(term_args...))
        end
    )
    return codegen_ast(jlfn)
end

function emit_adt_property_masks(def::ADTTypeDef)
    return expr_map(def.types) do type
        :($ADT.adt_property_masks(::Type{<:$(type.name)}) = $(xtuple(def.type_masks[type.name]...)))
    end
end

function emit_pattern_uncall(adt::ADTTypeDef)
    return expr_map(adt.types) do type
        return quote
            function $MLStyle.pattern_uncall(t::Type{<:$(type.name)}, self, type_params, type_args, args)
                return $ADT.compile_adt_pattern(t, self, type_params, type_args, args)
            end
        end
    end
end

function compile_adt_pattern(t::Type, self, type_params, type_args, args)
    isempty(type_params) || return begin
        call = Expr(:call, t, args...)
        ann = Expr(:curly, t, type_args...)
        self(Where(call, ann, type_params))
    end

    @switch args begin
        @case [Expr(:parameters, kwargs...), args...]
        @case let kwargs = []
        end
    end

    partial_field_names = Symbol[:type]
    patterns = Function[self(QuoteNode(nameof(t)))]
    all_field_names = adt_fieldnames(t)[2:end] # ignore type
    n_args = length(args)

    @switch args begin
        @case if all(Meta.isexpr(arg, :kw) for arg in args) end# kwargs
            for arg in args
                field_name = arg.args[1]
                field_name in all_field_names || error("$t has no field $field_name")
                push!(partial_field_names, field_name)
                push!(patterns, self(arg.args[2]))
            end
        @case if length(all_field_names) === n_args end # default constructor
            append!(patterns, map(self, args))
            append!(partial_field_names, all_field_names)
        @case [:(_...)]
            partial_field_names = Symbol[]
            patterns = Function[]
        @case if length(args) == 0 end # kwargs pattern
            # skip
        @case if length(args) !== length(all_field_names) end
            error("count of positional fields should be same as \
            the fields: $(join(all_field_names, ", "))")
        @case _
    end

    for e in kwargs
        @switch e begin
            @case ::Symbol
                e in all_field_names || error("unknown field name $e for $t when field punnning.")
                push!(partial_field_names, e)
                push!(patterns, P_capture(e))
                continue
            @case Expr(:kw, key::Symbol, value)
                key in all_field_names || error("unknown field name $key for $t when field punnning.")
                push!(partial_field_names, key)
                push!(patterns, and([P_capture(key), self(value)]))
                continue
            @case _
                error("unknown sub-pattern $e in $t")
        end
    end

    ret = struct_decons(adt_parent_type(t), partial_field_names, patterns)
    isempty(type_args) && return ret
    return and([self(Expr(:(::), Expr(:curly, t, type_args...))), ret])
end

function struct_decons(t, partial_fields, ps, prepr::AbstractString = repr(t))
    function tcons(_...)
        t
    end

    comp = MLStyle.Record.PComp(prepr, tcons;)
    function extract(sub::Any, i::Int, ::Any, ::Any)
        quote
            $(xcall(Base, :getproperty, sub, QuoteNode(partial_fields[i])))
        end
    end
    MLStyle.Record.decons(comp, extract, ps)
end

end # ADT
