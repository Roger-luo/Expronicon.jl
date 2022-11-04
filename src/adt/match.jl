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

    partial_field_names = Symbol[]
    patterns = Function[]
    all_field_names = variant_fieldnames(t)
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
            args = replace(args, :(_...) => :_) # only one left
            append!(patterns, map(self, args))
            append!(partial_field_names, all_field_names)
        @case [:(_...)]
            partial_field_names = Symbol[]
            patterns = Function[]
        @case if length(args) == 0 end # kwargs pattern
            # skip
        @case if length(args) !== length(all_field_names) end
            error("count of positional fields should be same as "*
            "the fields: $(join(all_field_names, ", "))")
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

    ret = struct_decons(adt_type(t), partial_field_names, patterns)
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
