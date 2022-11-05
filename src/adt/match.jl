function compile_adt_pattern(t, self, type_params, type_args, args)
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

    # singleton is not dispatch to ::VariantType
    # variant_kind(t) === :singleton
    if variant_kind(t) === :call
        uncall_call(t, self, args, kwargs, type_args)
    else # variant_kind(t) === :struct
        uncall_struct(t, self, args, kwargs, type_args)
    end
end

function uncall_call(t, self, args, kwargs, type_args)
    isempty(kwargs) || throw(ArgumentError("keyword arguments are not supported"))
    patterns = Function[]
    fieldtypes = variant_fieldtypes(t)
    nfields = length(fieldtypes)
    n_args = length(args)

    @switch args begin
        @case if nfields === n_args end # default constructor
            append!(patterns, map(self, args))
        @case if nfields > n_args end # partial constructor
            last(args) == :(_...) || throw(ArgumentError("partial constructor must end with _..."))
            append!(patterns, map(self, args[1:end-1]))
        # @case [:(_...)]
        @case _
    end

    ret = call_decons(t, patterns)
    isempty(type_args) && return ret
    return and([self(Expr(:(::), Expr(:curly, adt_type(t), type_args...))), ret])
end

function uncall_struct(t, self, args, kwargs, type_args)
    partial_field_names = Symbol[]
    patterns = Function[]
    all_field_names = variant_fieldnames(t)
    nfields = length(all_field_names)
    n_args = length(args)

    @switch args begin
        @case if all(Meta.isexpr(arg, :kw) for arg in args) end# kwargs
            for arg in args
                field_name = arg.args[1]
                field_name in all_field_names || error("$t has no field $field_name")
                push!(partial_field_names, field_name)
                push!(patterns, self(arg.args[2]))
            end
        @case if n_args ≤ nfields end # default constructor
            if n_args < nfields
                last(args) == :(_...) || throw(ArgumentError("partial constructor must end with _..."))
            end

            if last(args) == :(_...)
                args = args[1:end-1]
            end
            append!(patterns, map(self, args))
            append!(partial_field_names, all_field_names[1:length(args)])
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

    ret = struct_decons(t, partial_field_names, patterns)
    isempty(type_args) && return ret
    return and([self(:(::$(adt_type(t)))), ret])
end

function call_decons(t, ps, prepr::AbstractString = repr(t))
    function tcons(_...)
        adt_type(t)
    end

    comp = MLStyle.Record.PComp(prepr, tcons;)
    mask = variant_masks(t)
    types = variant_fieldtypes(t)
    function extract(sub::Any, i::Int, ::Any, ::Any)
        quote
            $(xcall(Base, :getfield, sub, mask[i]))::$(types[i])
        end
    end
    MLStyle.Record.decons(comp, extract, ps)
end


function struct_decons(t, partial_fields, ps, prepr::AbstractString = repr(t))
    function tcons(_...)
        adt_type(t)
    end

    comp = MLStyle.Record.PComp(prepr, tcons;)

    names = variant_fieldnames(t)
    types = variant_fieldtypes(t)
    mask = variant_masks(t)
    function extract(sub::Any, i::Int, ::Any, ::Any)
        idx = findfirst(isequal(partial_fields[i]), names)::Int
        quote
            $(xcall(Base, :getfield, sub, mask[idx]))::$(types[idx])
        end
    end
    MLStyle.Record.decons(comp, extract, ps)
end
