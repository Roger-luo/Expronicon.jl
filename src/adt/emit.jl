mutable struct VariantFieldTypes
    expr::Vector{Any}
    mask::Vector{Int}
    guess::Vector{Any}
    variant_types::Vector{Vector{Any}}

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

function guess_type!(info::EmitInfo, def::ADTTypeDef)
    function change_type(expr)
        @switch expr begin
            @case ::Symbol
                expr in info.variant_names && return def.name
                return expr
            @case :(Union{$(types...)}) || :(&Union{$(types...)})
                types = map(types) do type
                    type in info.variant_names && return def.name
                    return type
                end
                return Expr(:curly, :Union, types...)
            @case ::Expr
                return Expr(expr.head, map(change_type, expr.args)...)
            @case _
                return expr
        end
    end

    for variant in def.variants
        typeinfo = get!(VariantFieldTypes, info.typeinfo, variant)
        typeinfo.guess = map(variant.fieldtypes) do type
            guess_type(def.m, change_type(type))
        end
        typeinfo.expr = variant.fieldtypes
    end
    return info
end

function scan_variant_types!(info::EmitInfo, def::ADTTypeDef)
    for variant in def.variants
        typeinfo = get!(VariantFieldTypes, info.typeinfo, variant)
        typeinfo.variant_types = Vector{Vector{Any}}(undef, length(variant.fieldtypes))
        for (idx, expr) in enumerate(variant.fieldtypes)
            list = scan_field_variant_types!([], expr, info.variant_names)
            typeinfo.variant_types[idx] = list
        end
    end
    return info
end

# NOTE: we ignore Foo{VariantType} since we cannot actually check it
function scan_field_variant_types!(list::Vector{Any}, expr, variant_names::Vector{Symbol})
    @switch expr begin
        @case ::Symbol
            expr in variant_names && push!(list, expr)
        @case :(Union{$(types...)}) || :(&Union{$(types...)})
            for type in types
                scan_field_variant_types!(list, type, variant_names)
            end
        # @case :($name{$(types...)}) # Foo{VariantType}
        #     contains_variant_type(types, variant_names) && push!(list, expr)
        # Foo{VariantType, A} where VariantType, just happen to have the same name
        @case Expr(:where, type, params)
            type = Expronicon.mark_typevars(type, name_only.(params))
            scan_field_variant_types!(list, type, variant_names)
        @case _
    end
    return list
end

function scan_fields!(info::EmitInfo, def::ADTTypeDef)
    typeset = Dict{Any, Int}()

    for variant in def.variants
        variant_type_set = Dict{Any, Int}()
        for type in info.typeinfo[variant].guess
            if isbitstype(type)
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
    sizehint!(sorted_types, length(typeset)-1)
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
            if isbitstype(type)
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
    scan_variant_types!(info, def)
    return info
end

macro adt(head, body)
    def = ADTTypeDef(__module__, head, body)
    return esc(emit(def))
end

function emit(def::ADTTypeDef, info::EmitInfo=EmitInfo(def))
    return quote
        primitive type $(info.typename) 32 end

        $(emit_struct(def, info))
        $(emit_variant_cons(def, info))
        $(emit_variant_binding(def, info))
        $(emit_reflection(def, info))
        $(emit_getproperty(def, info))
        $(emit_propertynames(def, info))
        $(emit_pattern_uncall(def, info))
        $(emit_show(def, info))
    end
end

xvariant_type(info::EmitInfo, idx::Int) = :(Core.bitcast($(info.typename), $(UInt32(idx))))
xvariant_type(x) = xcall(Core, :getfield, x, QuoteNode(Symbol("#type")))

function emit_variant_binding(def::ADTTypeDef, info::EmitInfo)
    type_expr(idx) = xvariant_type(info, idx)
    type_defs = expr_map(enumerate(def.variants)) do (idx, variant)
        if variant.type === :singleton # instance is type
            :(const $(variant.name) = $(def.name)($(type_expr(idx))))
        else
            :(const $(variant.name) = $(type_expr(idx)))
        end
    end

    show_body = JLIfElse()
    for (idx, variant) in enumerate(def.variants)
        show_body[:(t == $(type_expr(idx)))] = quote
            print(io, $(string(def.name)), "::", $(string(variant.name)))
        end
    end

    show_body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end

    return quote
        $(type_defs)

        function Base.show(io::IO, t::$(info.typename))
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

        arg_ptr = 0
        assert_args = expr_map(2:length(info.fieldtypes)) do idx
            typeinfo = info.typeinfo[variant]
            if idx in typeinfo.mask
                arg_ptr += 1
                argname = args[idx]
                vtypenames = typeinfo.variant_types[arg_ptr]
                type_guess = typeinfo.guess[arg_ptr]
                jl = JLIfElse()
                if !isempty(vtypenames)
                    @gensym variant_type
                    msg = "expect $(join(vtypenames, " or "))"
                    vtypes = map(vtypenames) do t
                        :(Core.bitcast($(info.typename), $(info.name_type_map[t])))
                    end
                    jl[:(args[$arg_ptr] isa $(def.name))] = quote
                        $argname = args[$arg_ptr]
                        $variant_type = $ADT.variant_type($argname)
                        $variant_type in $(xtuple(vtypes...)) || throw(ArgumentError(
                            "$($msg), got $($variant_type)"))
                    end

                    if type_guess !== def.name
                        jl[:(args[$arg_ptr] isa $type_guess)] = quote
                            $argname = args[$arg_ptr]
                        end
                    end
                else
                    jl[:(args[$arg_ptr] isa $type_guess)] = quote
                        $argname = args[$arg_ptr]
                    end
                end

                jl.otherwise = quote
                    $argname = $Base.convert($type_guess, args[$arg_ptr])
                end
                codegen_ast(jl)
            else
                :($(args[idx]) = $(undef_value(info.fieldtypes[idx])))
            end
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

function emit_struct(def::ADTTypeDef, info::EmitInfo)
    def = JLStruct(;
        def.name, def.typevars, info.ismutable,
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
                    if haskey(kwargs, $(QuoteNode(name)))
                        $(var) = kwargs[$(QuoteNode(name))]
                    else
                        $throw_ex
                    end
                end
            else
                :($var = get(kwargs, $(QuoteNode(name)), $(default)))
            end
        end
        kwarg_body[:(t == $(xvariant_type(info, idx)))] = Expr(:block,
            variant.lineinfo,
            :(length(args) == 0 || throw(ArgumentError("expect keyword arguments instead of positional arguments"))),
            :(valid_keys = $(xtuple(QuoteNode.(variant.fieldnames)...))),
            :(others = filter(!in(valid_keys), keys(kwargs))),
            :(isempty(others) || throw(ArgumentError("unknown keyword argument: $(join(others, ", "))"))),
            assign_kwargs,
            :(return $(def.name)(t, $([Symbol("#kw#", idx) for idx in 1:nfields]...)))
        )
    end
    kwarg_body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end

    return quote
        # NOTE: make sure struct definition is available
        function (t::$(info.typename))(args...; kwargs...)
            isempty(kwargs) && return $(def.name)(t, args...)
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
            $(codegen_ast(show_body))
        end
    end
end

function emit_pattern_uncall(::ADTTypeDef, info::EmitInfo)
    return quote
        function $MLStyle.pattern_uncall(t::$(info.typename), self, type_params, type_args, args)
            return $ADT.compile_adt_pattern(t, self, type_params, type_args, args)
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
