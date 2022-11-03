using ManualMemory: MemoryBuffer, Reference, load, store!
using MLStyle
# @adt Message begin
#     Quit
#     struct Move
#         x::Int32
#         y::Int32
#     end
#     Write(::String)
#     ChangeColor(::Int32, ::Int32, ::Int32)
# end

struct Something
    a::Int
    b::Float64
end


function undef_value(::Type{T}) where T
    if T <: Number
        return T(0)
    elseif isbitstype(T)
        return load(pointer(Reference{T}()))
    else
        throw(ArgumentError("Cannot create an undef value for non-bits type $T"))
    end
end

struct MessageA
    type::Int
    d1::Int
    d2::Int
    d3
    d4::Int
    d5::Something

    function MessageA(type, args...)
        if type == 1
            length(args) == 0 || throw(ArgumentError("MessageA(1) takes no arguments"))
            new(type,
                undef_value(Int),
                undef_value(Int),
                nothing,
                undef_value(Int),
                undef_value(Something),
            )
        elseif type == 2
            length(args) == 2 || throw(ArgumentError("MessageA(2) takes 2 arguments"))
            new(type,
                convert(Int, args[1]),
                convert(Int, args[2]),
                nothing,
                undef_value(Int),
                undef_value(Something),
            )
        elseif type == 3
            length(args) == 1 || throw(ArgumentError("MessageA(3) takes 1 argument"))
            new(type,
                undef_value(Int),
                undef_value(Int),
                convert(String, args[1]),
                undef_value(Int),
                undef_value(Something),
            )
        elseif type == 4 # ChangeColor
            length(args) == 3 || throw(ArgumentError("expect 3 arguments"))
            new(type,
                convert(Int, args[1]),
                convert(Int, args[2]),
                nothing,
                convert(Int, args[3]),
                undef_value(Something),
            )
        end
    end
end

abstract type EnumType end

struct MessageAType <: EnumType
    type::Int
end

function Base.show(io::IO, t::MessageAType)
    if t.type == 1
        print(io, "MessageA::Quit")
    elseif t.type == 2
        print(io, "MessageA::Move")
    elseif t.type == 3
        print(io, "MessageA::Write")
    elseif t.type == 4
        print(io, "MessageA::ChangeColor")
    end
end

function (t::MessageAType)(args...)
    MessageA(t.type, args...)
end

const Quit = MessageA(1)
const Move = MessageAType(2)
const Write = MessageAType(3)
const ChangeColor = MessageAType(4)

function Base.show(io::IO, msg::MessageA)
    if msg.type == 1
        print(io, "MessageA::Quit")
    elseif msg.type == 2
        print(io, "MessageA::Move(", repr(msg.d1), ", ", repr(msg.d2), ")")
    elseif msg.type == 3
        print(io, "MessageA::Write(", repr(msg.d3), ")")
    elseif msg.type == 4
        print(io, "MessageA::ChangeColor(", repr(msg.d1), ", ", repr(msg.d2), ", ", repr(msg.d4), ")")
    end
end


ChangeColor(1, 2, 3)
ChangeColor

@match ChangeColor(1, 2, 3) begin
    ChangeColor(r, g, b) => (r, g, b)
    Write(s) => s
    _ => nothing
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

function compile_adt_pattern(t::EnumType, self, type_params, type_args, args)
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