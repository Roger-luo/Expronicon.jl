struct EmitInfo
    typename::Symbol
    ismutable::Bool
    fieldnames::Vector{Symbol}
    fieldtypes::Vector{Any}
    variant_masks::Dict{Variant, Vector{Int}} # variant masks
    type_guess::Dict{Variant, Vector{Any}}
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

function EmitInfo(typename::Symbol, ismutable::Bool=false)
    return EmitInfo(
        typename, ismutable,
        Symbol[], [],
        Dict{Variant, Vector{Int}}(),
        Dict{Variant, Vector{Any}}()
    )
end

function guess_type!(info::EmitInfo, def::ADTTypeDef)
    for variant in def.variants
        info.type_guess[variant] = map(variant.fieldtypes) do type
            guess_type(def.m, type)
        end
    end
    return info
end

function scan_fields!(info::EmitInfo, def::ADTTypeDef)
    typeset = Dict{Any, Int}()

    for variant in def.variants
        variant_type_set = Dict{Any, Int}()
        for type in info.type_guess[variant]
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
    for _ in 1:typeset[Any]
        push!(info.fieldnames, Symbol("#Any##", field_ptr))
        push!(info.fieldtypes, Any)
        field_ptr += 1
    end

    for variant in def.variants
        mask = info.variant_masks[variant] =
            Vector{Int}(undef, length(variant.fieldtypes))
        variant_type_ptr = Dict{Any, Int}()
        for (idx, type) in enumerate(info.type_guess[variant])
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
    info = EmitInfo(Symbol(def.name, "#Type"), ismutable)
    guess_type!(info, def)
    scan_fields!(info, def)
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
        $(emit_variant_binding(def, info))
        $(emit_reflection(def, info))
        $(emit_getproperty(def, info))
        $(emit_propertynames(def, info))
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

function struct_constructor(def::ADTTypeDef, info::EmitInfo)
    construct_body = JLIfElse()
    for (variant_idx, variant) in enumerate(def.variants)
        nargs = length(variant.fieldtypes)
        msg = :("expect $($nargs) arguments, got $(length(args)) arguments")

        if isempty(def.typevars)
            new_head = :new
        else
            new_head = :(new{$(name_only.(def.typevars)...)})
        end

        args = Vector{Any}(undef, length(info.fieldtypes))
        args[1] = :type

        arg_ptr = 1
        for idx in 2:length(info.fieldtypes)
            if idx in info.variant_masks[variant]
                args[idx] = :(args[$arg_ptr])
                arg_ptr += 1
            else
                args[idx] = undef_value(info.fieldtypes[idx])
            end
        end

        type_expr = :(Core.bitcast($(info.typename), $(UInt32(variant_idx))))
        construct_body[:(type == $(type_expr))] = quote
            length(args) == $nargs ||
                throw(ArgumentError($msg))
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
        constructors=[struct_constructor(def, info)]
    )

    return quote
        Core.@__doc__ $(codegen_ast(def))

        # NOTE: make sure struct definition is available
        function (t::$(info.typename))(args...)
            $(def.name)(t, args...)
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
            mask = info.variant_masks[variant]
            for (idx, field) in enumerate(variant.fields)
                jl[:(name === $(QuoteNode(field)))] = quote
                    return $Base.getfield(value, $(mask[idx]))
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
            :(return $(xtuple(map(QuoteNode, variant.fields)...)))
        end
    end

    return quote
        function $Base.propertynames(value::$(def.name), private::Bool=false)
            $(codegen_ast(propertynames_body))
        end
    end
end

function emit_reflection(def::ADTTypeDef, info::EmitInfo)
    variant_masks_body = JLIfElse()
    for (variant, mask) in info.variant_masks
        variant_masks_body[:(t == $(variant.name))] = xtuple(mask...)
    end
    variant_masks_body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end

    variant_fieldnames_body = JLIfElse()
    for variant in def.variants
        if variant.type === :singleton || variant.type === :call
            variant_fieldnames_body[:(t == $(variant.name))] = quote
                throw(ArgumentError("singleton variant or call variant has no field names"))
            end
        else
            variant_fieldnames_body[:(t == $(variant.name))] = xtuple(QuoteNode.(variant.fields)...)
        end
    end
    variant_fieldnames_body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end

    quote
        @inline function $ADT.variant_type(x::$(def.name))
            return $(xvariant_type(:x))
        end

        @inline function $ADT.variant_masks(t::$(info.typename))
            $(codegen_ast(variant_masks_body))
        end

        @inline function $ADT.variant_fieldnames(t::$(info.typename))
            $(codegen_ast(variant_fieldnames_body))
        end

        @inline function $ADT.variant_fieldname(t::$(info.typename), idx::Int)
            return $ADT.variant_fieldnames(t)[idx]
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

function foreach_variant(f, value::Symbol, def::ADTTypeDef, info::EmitInfo)
    body = JLIfElse()
    value_type = :($ADT.variant_type($value))

    for (idx, variant) in enumerate(def.variants)
        type_expr = xvariant_type(info, idx)
        body[:($value_type == $type_expr)] = quote
            $(f(variant))
        end
    end
    body.otherwise = quote
        throw(ArgumentError("invalid variant type"))
    end
    return body
end
