mutable struct VariantFieldTypes
    expr::Vector{Any}
    mask::Vector{Int}
    guess::Vector{Any}
    VariantFieldTypes() = new()
end

struct EmitInfo
    typename::Symbol
    ismutable::Bool
    fieldnames::Vector{Symbol}
    fieldtypes::Vector{Any}

    typeinfo::Dict{Variant, VariantFieldTypes}
    variant_names::Vector{Symbol}
    name_type_map::Dict{Symbol, UInt32}
    # contains_variant::Vector{Bool}
    # variant_masks::Dict{Variant, Vector{Int}} # variant masks
    # type_guess::Dict{Variant, Vector{Any}}
end

function EmitInfo(typename::Symbol, variant_names::Vector{Symbol}, ismutable::Bool=false)
    return EmitInfo(
        typename, ismutable,
        Symbol[], [], Dict{Variant, VariantFieldTypes}(),
        variant_names, Dict{Symbol, UInt}(),
    )
end

function assign_type!(info::EmitInfo, def::ADTTypeDef)
    for (idx, variant) in enumerate(def.variants)
        info.name_type_map[variant.name] = UInt32(idx)
    end
    return info
end

# NOTE: we don't support using variant in the type field
# because they cannot be checked efficiently/statically
# one should check them manually at runtime
function guess_type!(info::EmitInfo, def::ADTTypeDef)
    function check_type(expr)
        @switch expr begin
            @case ::Symbol
                type = guess_type(def.m, expr)
                type isa Type && return type
                expr in info.variant_names && error("cannot use variant in type field")
                return expr
            @case Expr(:curly, name, types...)
                map(check_type, types)
                return guess_type(def.m, expr)
            @case _
                return guess_type(def.m, expr)
        end
    end

    for variant in def.variants
        typeinfo = get!(VariantFieldTypes, info.typeinfo, variant)
        typeinfo.guess = map(variant.fieldtypes) do type
            guess_type(def.m, type)
        end
        typeinfo.expr = variant.fieldtypes
    end
    return info
end

function scan_fields!(info::EmitInfo, def::ADTTypeDef)
    typeset = Dict{Any, Int}()

    for variant in def.variants
        variant_type_set = Dict{Any, Int}()
        for type in info.typeinfo[variant].guess
            if type isa Type && isbitstype(type)
                variant_type_set[type] = get(variant_type_set, type, 0) + 1
            else
                variant_type_set[Any] = get(variant_type_set, Any, 0) + 1
            end
        end

        for (type, count) in variant_type_set
            if haskey(typeset, type)
                typeset[type] = max(typeset[type], count)
            else
                typeset[type] = count
            end
        end
    end

    sorted_types = []
    sizehint!(sorted_types, length(typeset))
    for type in keys(typeset)
        type === Any && continue
        push!(sorted_types, type)
    end
    sorted_types = sort!(sorted_types, by=string)

    type_start = Dict{Any, Int}()
    push!(info.fieldnames, Symbol("#type"))
    push!(info.fieldtypes, info.typename)

    field_ptr = 2
    for type in sorted_types
        count = typeset[type]
        type_start[type] = field_ptr
        for _ in 1:count
            push!(info.fieldnames, Symbol("#", string(type), "##", field_ptr))
            push!(info.fieldtypes, type)
            field_ptr += 1
        end
    end

    type_start[Any] = field_ptr
    haskey(typeset, Any) && for _ in 1:typeset[Any]
        push!(info.fieldnames, Symbol("#Any##", field_ptr))
        push!(info.fieldtypes, Any)
        field_ptr += 1
    end

    for variant in def.variants
        typeinfo = get!(VariantFieldTypes, info.typeinfo, variant)
        mask = typeinfo.mask = Vector{Int}(undef, length(variant.fieldtypes))
        variant_type_ptr = Dict{Any, Int}()
        for (idx, type) in enumerate(typeinfo.guess)
            if type isa Type && isbitstype(type)
                variant_type_ptr[type] = get(variant_type_ptr, type, 0) + 1
                mask[idx] = type_start[type] + variant_type_ptr[type] - 1
            else
                variant_type_ptr[Any] = get(variant_type_ptr, Any, 0) + 1
                mask[idx] = type_start[Any] + variant_type_ptr[Any] - 1
            end
        end
    end
    return
end

function EmitInfo(def::ADTTypeDef)
    ismutable = any(x->x.ismutable, def.variants)
    variant_names = map(def.variants) do variant
        return variant.name
    end
    info = EmitInfo(Symbol(def.name, "#Type"), variant_names, ismutable)
    # replace variant type in field types with
    # the actual type. Then add a dynamic type check
    # in the constructor.
    assign_type!(info, def)
    guess_type!(info, def)
    scan_fields!(info, def)
    return info
end

"""
    @adt name begin
        variant1
        variant2(field1, field2)

        <mutable> struct variant3
            field1
            field2 = <default>
        end
    end

Create an algebra data type (ADT).

### Arguments

- `<name>`: the name of the ADT, can be just a name or name with supertype.
- `<body>`: the body of the ADT, a list of variants in `begin ... end` block.

### Introduction

The ADT is a type that can have multiple
variants. Each variant can have different fields. The fields can be of different
types. The ADT is immutable by default. To make it mutable, use `mutable struct`
instead of `struct` in the definition.

The ADT is implemented as a tagged union. The tag is stored in the first field.
The rest of the fields are the actual data. The data is stored in a compact way
so that the size of the ADT is the size of the largest variant.

Use of multiple variants will not effect type stability, unlike `Union` types.

The variants must be used with the variant interface instead of the type interface
from Julia `Base`, and the pattern match must be MLStyle's pattern match. It is
recommended to use pattern match as much as possible.

### Pretty Printing

A default inline pretty printing is generated for `Base.show(io::IO, x::<your ADT type>)`.
If you want to customize inline text printing, overload
`Expronicon.ADT.variant_show_inline(io::IO, x::<your ADT type>)` method. For other `MIME`
types, you can overload the normal `Base.show(::IO, ::MIME, x::<your ADT type>)` method.
"""
macro adt(head, body)
    def = ADTTypeDef(__module__, head, body)
    return esc(emit(def))
end

macro adt(export_variants, head, body)
    export_variants == :public || error("expect `public` after `@adt`")
    def = ADTTypeDef(__module__, head, body; export_variants=true)
    return esc(emit(def))
end

function emit(def::ADTTypeDef, info::EmitInfo=EmitInfo(def))
    return quote
        primitive type $(info.typename) 32 end
        $(emit_exports(def, info))
        $(emit_struct(def, info))
        $(emit_variant_cons(def, info))
        $(emit_variant_getproperty(def, info))
        $(emit_variant_binding(def, info))
        $(emit_variant_type_show(def, info))
        $(emit_reflection(def, info))
        $(emit_getproperty(def, info))
        $(emit_propertynames(def, info))
        $(emit_is_enum(def, info))
        $(emit_enum_matcher(def, info))
        $(emit_pattern_uncall(def, info))
        $(emit_show(def, info))
    end
end

xvariant_type(info::EmitInfo, idx::Int) = :(Core.bitcast($(info.typename), $(UInt32(idx))))
xvariant_type(x) = xcall(Core, :getfield, x, QuoteNode(Symbol("#type")))

function emit_variant_binding(def::ADTTypeDef, info::EmitInfo)
    def.export_variants || return :($nothing)

    expr_map(enumerate(def.variants)) do (idx, variant)
        type_enum = xvariant_type(info, idx)
        if variant.type === :singleton
            return :(const $(variant.name) = $(def.name)($type_enum))
        else
            return :(const $(variant.name) = $(type_enum))
        end
    end
end

function emit_variant_getproperty(def::ADTTypeDef, info::EmitInfo)
    type_expr(idx) = xvariant_type(info, idx)

    body = JLIfElse()
    for (idx, variant) in enumerate(def.variants)
        body[:(name === $(QuoteNode(variant.name)))] = if variant.type === :singleton
            quote # instance is type
                $(def.name)($(type_expr(idx)))
            end
        else
            quote
                $(type_expr(idx))
            end
        end
    end

    builtin_names = (
        fieldnames(DataType)...,
        fieldnames(Union)...,
        fieldnames(UnionAll)...,
    )
    @static if VERSION < v"1.8-"
        body[:(name in $builtin_names)] = :($Base.getfield(Self, name))
    else
        body[:(name in $builtin_names)] = :(@inline $Base.getfield(Self, name))
    end
    body.otherwise = :(throw(ArgumentError("invalid variant type")))

    variant_names = map(def.variants) do variant
        QuoteNode(variant.name)
    end

    return quote
        function $Base.getproperty(::Type{Self}, name::Symbol) where {Self <:$(def.name)}
            return $(codegen_ast(body))
        end

        function $Base.propertynames(::Type{Self}) where {Self <:$(def.name)}
            return $(xtuple(variant_names...))
        end

        function $Base.propertynames(::Type{Self}, private::Bool) where {Self <:$(def.name)}
            private || return $Base.propertynames(Self)
            return $(xtuple(variant_names..., builtin_names...))
        end
    end
end

function emit_variant_type_show(def::ADTTypeDef, info::EmitInfo)
    show_body = JLIfElse()
    for (idx, variant) in enumerate(def.variants)
        show_body[:(t == $(xvariant_type(info, idx)))] = quote
            print(io, $(string(def.name)), ".", $(string(variant.name)))
        end
    end

    show_body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end

    return quote
        function $Base.show(io::IO, t::$(info.typename))
            $(codegen_ast(show_body))
            return
        end
    end
end

function struct_cons(def::ADTTypeDef, info::EmitInfo)
    construct_body = foreach_variant_type(:type, def, info) do variant
        nargs = length(variant.fieldtypes)
        msg = :("expect $($nargs) arguments, got $(length(args)) arguments")

        if isempty(def.typevars)
            new_head = :new
        else
            new_head = :(new{$(name_only.(def.typevars)...)})
        end

        args = map(eachindex(info.fieldtypes)) do idx
            idx == 1 && return :type
            return Symbol("#args#", idx)
        end

        assert_args = expr_map(2:length(info.fieldtypes)) do idx
            typeinfo = info.typeinfo[variant]
            idx in typeinfo.mask || return :($(args[idx]) = $(undef_value(info.fieldtypes[idx])))

            argname = args[idx]
            arg_idx = findfirst(isequal(idx), typeinfo.mask)
            type_guess = typeinfo.guess[arg_idx]
            jl = JLIfElse()
            jl[:(args[$arg_idx] isa $type_guess)] = quote
                $argname = args[$arg_idx]
            end

            jl.otherwise = quote
                $argname = $Base.convert($type_guess, args[$arg_idx])
            end
            codegen_ast(jl)
        end

        return quote
            length(args) == $nargs || throw(ArgumentError($msg))
            $assert_args
            $new_head($(args...))
        end
    end

    if isempty(def.typevars)
        name = def.name
        whereparams = nothing
    else
        name = Expr(:curly, def.name, name_only.(def.typevars)...)
        whereparams = def.typevars
    end

    return JLFunction(;
        name, whereparams,
        args=[:(type::$(info.typename)), :(args...)],
        body=construct_body
    )
end

function emit_exports(def::ADTTypeDef, info::EmitInfo)
    def.export_variants || return nothing

    names = map(def.variants) do variant
        return variant.name
    end
    push!(names, def.name)
    return Expr(:export, names...)
end

function emit_struct(def::ADTTypeDef, info::EmitInfo)
    def = JLStruct(;
        def.name, def.typevars, info.ismutable,
        def.supertype,
        fields=map(info.fieldnames, info.fieldtypes) do name, type
            JLField(;name, type)
        end,
        constructors=[struct_cons(def, info)]
    )

    return quote
        Core.@__doc__ $(codegen_ast(def))
    end
end

function emit_variant_cons(def::ADTTypeDef, info::EmitInfo)
    @gensym adt_type args kwargs
    kwarg_body = JLIfElse()
    for (idx, variant) in enumerate(def.variants)
        variant.type === :struct || continue
        nfields = length(variant.fieldtypes)
        assign_kwargs = expr_map(1:nfields,
            variant.fieldnames, variant.field_defaults) do idx, name, default

            var = Symbol("#kw#", idx)
            msg = "missing keyword argument: $(name)"
            throw_ex = Expr(:block, variant.lineinfo, :(throw(ArgumentError($msg))))
            if default === no_default
                quote
                    if haskey($kwargs, $(QuoteNode(name)))
                        $(name) = $kwargs[$(QuoteNode(name))]
                    else
                        $throw_ex
                    end
                end
            else
                :($name = get($kwargs, $(QuoteNode(name)), $(default)))
            end
        end

        @gensym valid_keys others
        kwarg_body[:($adt_type == $(xvariant_type(info, idx)))] = Expr(:block,
            variant.lineinfo,
            :(length($args) == 0 || throw(ArgumentError("expect keyword arguments instead of positional arguments"))),
            :($valid_keys = $(xtuple(QuoteNode.(variant.fieldnames)...))),
            :($others = filter(!in($valid_keys), keys($kwargs))),
            :(isempty($others) || throw(ArgumentError("unknown keyword argument: $(join($others, ", "))"))),
            assign_kwargs,
            :(return $(def.name)($adt_type, $(variant.fieldnames...)))
        )
    end
    kwarg_body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end

    return quote
        # NOTE: make sure struct definition is available
        function ($adt_type::$(info.typename))($args...; $kwargs...)
            isempty($args) || return $(def.name)($adt_type, $args...)
            $(codegen_ast(kwarg_body))
        end
    end
end

function emit_getproperty(def::ADTTypeDef, info::EmitInfo)
    getproperty_body = foreach_variant(:value, def, info) do variant
        if variant.type === :singleton || variant.type === :call
            msg = "$(variant.type) variant $(variant.name) does not have a field name"
            return quote
                throw(ArgumentError($msg))
            end
        else
            jl = JLIfElse()
            mask = info.typeinfo[variant].mask
            type_guess = info.typeinfo[variant].guess
            for (idx, field) in enumerate(variant.fieldnames)
                jl[:(name === $(QuoteNode(field)))] = quote
                    # annotate type to avoid type instability
                    return $Base.getfield(value, $(mask[idx]))::$(type_guess[idx])
                end
            end
            jl.otherwise = quote
                throw(ArgumentError("invalid field name"))
            end
            return codegen_ast(jl)
        end
    end

    return quote
        function $Base.getproperty(value::$(def.name), name::Symbol)
            name === :type && return $ADT.variant_type(value)
            $(codegen_ast(getproperty_body))
        end
    end
end

function emit_propertynames(def::ADTTypeDef, info::EmitInfo)
    propertynames_body = foreach_variant(:value, def, info) do variant
        if variant.type === :singleton || variant.type === :call
            :(return ())
        else
            :(return $(xtuple(map(QuoteNode, variant.fieldnames)...)))
        end
    end

    return quote
        function $Base.propertynames(value::$(def.name), private::Bool=false)
            $(codegen_ast(propertynames_body))
        end
    end
end

function emit_show(def::ADTTypeDef, info::EmitInfo)
    value_type = :($ADT.variant_type(t))
    show_body = foreach_variant(:t, def, info) do variant
        if variant.type === :singleton
            quote
                $Base.show(io, $value_type)
            end
        elseif variant.type === :call
            quote
                $Base.show(io, $value_type)
                print(io, "(")
                mask = $ADT.variant_masks($value_type)
                for (idx, field_idx) in enumerate(mask)
                    show(io, $Base.getfield(t, field_idx))

                    if idx < length(mask)
                        print(io, ", ")
                    end
                end
                print(io, ")")
            end
        else # struct
            quote
                $Base.show(io, $value_type)
                print(io, "(")
                mask = $ADT.variant_masks($value_type)
                names = $ADT.variant_fieldnames($value_type)
                for (idx, field_idx) in enumerate(mask)
                    print(io, names[idx], "=")
                    show(io, $Base.getfield(t, field_idx))

                    if idx < length(mask)
                        print(io, ", ")
                    end
                end
                print(io, ")")
            end
        end
    end

    return quote
        function Base.show(io::IO, t::$(def.name))
            $ADT.variant_show_inline(io, t)
        end

        function $ADT.variant_show_inline_default(io::IO, t::$(def.name))
            $(codegen_ast(show_body))
        end
    end
end

function emit_pattern_uncall(def::ADTTypeDef, info::EmitInfo)
    return quote
        function $MLStyle.pattern_uncall(t::$(info.typename), self, type_params, type_args, args)
            return $ADT.compile_adt_pattern(t, self, type_params, type_args, args)
        end

        function $MLStyle.pattern_uncall(x::$(def.name), self, type_params, type_args, args)
            isempty(type_params) && isempty(type_args) && isempty(args) || error("invalid pattern")
            return $MLStyle.AbstractPatterns.literal(x)
        end
    end
end

function emit_is_enum(def::ADTTypeDef, info::EmitInfo)
    is_enum_body = foreach_variant(:value, def, info) do variant
        if variant.type === :singleton
            :(return true)
        else
            :(return false)
        end
    end

    return quote
        function $MLStyle.is_enum(value::$(def.name))
            $(codegen_ast(is_enum_body))
        end
    end
end

function emit_enum_matcher(def::ADTTypeDef, info::EmitInfo)
    enum_matcher_body = foreach_variant(:value, def, info) do variant
        if variant.type === :singleton
            ex = :($ADT.variant_type($(Expr(:$, :value))) == $ADT.variant_type($(Expr(:$, :expr))))
            :(return $(Expr(:quote, ex)))
        else
            :(return :(error("not a singleton variant")))
        end
    end

    return quote
        function $MLStyle.enum_matcher(value::$(def.name), expr)
            $(codegen_ast(enum_matcher_body))
        end
    end
end

include("reflection.jl")

function foreach_variant(f, value::Symbol, def::ADTTypeDef, info::EmitInfo)
    value_type = :($ADT.variant_type($value))
    return foreach_variant_type(f, value_type, def, info)
end

function foreach_variant_type(f, type, def::ADTTypeDef, info::EmitInfo)
    body = JLIfElse()

    for (idx, variant) in enumerate(def.variants)
        type_expr = xvariant_type(info, idx)
        body[:($type == $type_expr)] = quote
            $(f(variant))
        end
    end
    body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end
    return body
end
