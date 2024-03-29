module TestEmit

using Test
using Expronicon
using Expronicon.ADT: ADT, EmitInfo, ADTTypeDef, @adt, @use, @const_use,
    emit_exports,
    emit_struct,
    emit_show,
    emit_variant_cons,
    emit_reflection,
    emit_variant_binding,
    emit_getproperty,
    emit_propertynames,
    # reflection
    emit_variants,
    emit_variant_type,
    emit_variant_masks,
    emit_variant_typename,
    emit_variant_fieldname,
    emit_variant_fieldtype,
    emit_variant_field_default,
    emit_variant_fieldnames,
    emit_variant_fieldtypes,
    emit_variant_field_defaults

# function gentest(x)
#     ex = prettify(x; alias_gensym=false, rm_single_block=false)
#     buf = IOBuffer()
#     show(buf, MIME"text/plain"(), ex)
#     return clipboard(String(take!(buf)))
# end

body = quote
    Quit

    struct Move
        x::Int64
        y::Int64
    end

    Write(::String)

    struct Aka
        x::Vector{Int64}
        y::Vector{Int64}
    end

    ChangeColor(::Int64, ::Int64, ::Int64)
end

def = ADTTypeDef(Main, :Message, body)
info = EmitInfo(def)

@testset "EmitInfo(::ADTTypeDef)" begin
    def = ADTTypeDef(Main, :Message, body)
    info = EmitInfo(def)
    @test info.typeinfo[def.variants[1]].mask == Int[]
    @test info.typeinfo[def.variants[2]].mask == [2, 3]
    @test info.typeinfo[def.variants[3]].mask == [5]
    @test info.typeinfo[def.variants[4]].mask == [5, 6]
    @test info.typeinfo[def.variants[5]].mask == [2, 3, 4]

    @test info.fieldtypes == [Symbol("Message#Type"), Int64, Int64, Int64, Any, Any]
    @test length(info.fieldnames) == 6

    io = IOBuffer()
    show(io, MIME"text/plain"(), info)
    @test String(take!(io)) == """
    EmitInfo:
      typename: Message#Type
      ismutable: false
      fields: 
        #type::Message#Type
        #Int64##2::Int64
        #Int64##3::Int64
        #Int64##4::Int64
        #Any##5::Any
        #Any##6::Any
    
      variants:
        struct Aka ------------------------------ [5, 6]
            x::Vector{Int64}
            y::Vector{Int64}
        end
        ChangeColor(::Int64, ::Int64, ::Int64) -- [2, 3, 4]
        struct Move ----------------------------- [2, 3]
            x::Int64
            y::Int64
        end
        Quit ------------------------------------ []
        Write(::String) ------------------------- [5]"""
end

def = ADTTypeDef(Main, :Message, body)
info = EmitInfo(def)

@test_expr emit_struct(def, info) == quote
    #= /Users/roger/Code/Julia/Expronicon/src/adt/emit.jl:329 =# Core.@__doc__ struct Message
            var"#type"::var"Message#Type"
            var"#Int64##2"::Int64
            var"#Int64##3"::Int64
            var"#Int64##4"::Int64
            var"#Any##5"
            var"#Any##6"
            function Message(type::var"Message#Type", args...)
                if type == Core.bitcast(var"Message#Type", 0x00000001)
                    length(args) == 0 || throw(ArgumentError("expect $(0) arguments, got $(length(args)) arguments"))
                    var"#args#2" = 0
                    var"#args#3" = 0
                    var"#args#4" = 0
                    var"#args#5" = nothing
                    var"#args#6" = nothing
                    new(type, var"#args#2", var"#args#3", var"#args#4", var"#args#5", var"#args#6")
                elseif type == Core.bitcast(var"Message#Type", 0x00000002)
                    length(args) == 2 || throw(ArgumentError("expect $(2) arguments, got $(length(args)) arguments"))
                    if args[1] isa Int64
                        var"#args#2" = args[1]
                    else
                        var"#args#2" = (Base).convert(Int64, args[1])
                    end
                    if args[2] isa Int64
                        var"#args#3" = args[2]
                    else
                        var"#args#3" = (Base).convert(Int64, args[2])
                    end
                    var"#args#4" = 0
                    var"#args#5" = nothing
                    var"#args#6" = nothing
                    new(type, var"#args#2", var"#args#3", var"#args#4", var"#args#5", var"#args#6")
                elseif type == Core.bitcast(var"Message#Type", 0x00000003)
                    length(args) == 1 || throw(ArgumentError("expect $(1) arguments, got $(length(args)) arguments"))
                    var"#args#2" = 0
                    var"#args#3" = 0
                    var"#args#4" = 0
                    if args[1] isa String
                        var"#args#5" = args[1]
                    else
                        var"#args#5" = (Base).convert(String, args[1])
                    end
                    var"#args#6" = nothing
                    new(type, var"#args#2", var"#args#3", var"#args#4", var"#args#5", var"#args#6")
                elseif type == Core.bitcast(var"Message#Type", 0x00000004)
                    length(args) == 2 || throw(ArgumentError("expect $(2) arguments, got $(length(args)) arguments"))
                    var"#args#2" = 0
                    var"#args#3" = 0
                    var"#args#4" = 0
                    if args[1] isa Vector{Int64}
                        var"#args#5" = args[1]
                    else
                        var"#args#5" = (Base).convert(Vector{Int64}, args[1])
                    end
                    if args[2] isa Vector{Int64}
                        var"#args#6" = args[2]
                    else
                        var"#args#6" = (Base).convert(Vector{Int64}, args[2])
                    end
                    new(type, var"#args#2", var"#args#3", var"#args#4", var"#args#5", var"#args#6")
                elseif type == Core.bitcast(var"Message#Type", 0x00000005)
                    length(args) == 3 || throw(ArgumentError("expect $(3) arguments, got $(length(args)) arguments"))
                    if args[1] isa Int64
                        var"#args#2" = args[1]
                    else
                        var"#args#2" = (Base).convert(Int64, args[1])
                    end
                    if args[2] isa Int64
                        var"#args#3" = args[2]
                    else
                        var"#args#3" = (Base).convert(Int64, args[2])
                    end
                    if args[3] isa Int64
                        var"#args#4" = args[3]
                    else
                        var"#args#4" = (Base).convert(Int64, args[3])
                    end
                    var"#args#5" = nothing
                    var"#args#6" = nothing
                    new(type, var"#args#2", var"#args#3", var"#args#4", var"#args#5", var"#args#6")
                else
                    throw(ArgumentError("invalid variant type"))
                end
            end
        end
end

@test_expr emit_variant_cons(def, info) == quote
    function (var"##adt_type#1"::var"Message#Type")(var"##args#1"...; var"##kwargs#1"...)
        isempty(var"##args#1") || return Message(var"##adt_type#1", var"##args#1"...)
        if var"##adt_type#1" == Core.bitcast(var"Message#Type", 0x00000002)
            length(var"##args#1") == 0 || throw(ArgumentError("expect keyword arguments instead of positional arguments"))
            var"##valid_keys#1" = (:x, :y)
            var"##others#1" = filter(!((in)(var"##valid_keys#1")), keys(var"##kwargs#1"))
            isempty(var"##others#1") || throw(ArgumentError("unknown keyword argument: $(join(var"##others#1", ", "))"))
            if haskey(var"##kwargs#1", :x)
                x = var"##kwargs#1"[:x]
            else
                throw(ArgumentError("missing keyword argument: x"))
            end
            if haskey(var"##kwargs#1", :y)
                y = var"##kwargs#1"[:y]
            else
                throw(ArgumentError("missing keyword argument: y"))
            end
            return Message(var"##adt_type#1", x, y)
        elseif var"##adt_type#1" == Core.bitcast(var"Message#Type", 0x00000004)
            length(var"##args#1") == 0 || throw(ArgumentError("expect keyword arguments instead of positional arguments"))
            var"##valid_keys#2" = (:x, :y)
            var"##others#2" = filter(!((in)(var"##valid_keys#2")), keys(var"##kwargs#1"))
            isempty(var"##others#2") || throw(ArgumentError("unknown keyword argument: $(join(var"##others#2", ", "))"))
            if haskey(var"##kwargs#1", :x)
                x = var"##kwargs#1"[:x]
            else
                throw(ArgumentError("missing keyword argument: x"))
            end
            if haskey(var"##kwargs#1", :y)
                y = var"##kwargs#1"[:y]
            else
                throw(ArgumentError("missing keyword argument: y"))
            end
            return Message(var"##adt_type#1", x, y)
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
end

@test_expr emit_show(def, info) == quote
    function Base.show(io::IO, t::Message)
        (Expronicon.ADT).variant_show_inline(io, t)
    end
    function (Expronicon.ADT).variant_show_inline_default(io::IO, t::Message)
        if (Expronicon.ADT).variant_type(t) == Core.bitcast(var"Message#Type", 0x00000001)
            (Base).show(io, (Expronicon.ADT).variant_type(t))
        elseif (Expronicon.ADT).variant_type(t) == Core.bitcast(var"Message#Type", 0x00000002)
            (Base).show(io, (Expronicon.ADT).variant_type(t))
            print(io, "(")
            mask = (Expronicon.ADT).variant_masks((Expronicon.ADT).variant_type(t))
            names = (Expronicon.ADT).variant_fieldnames((Expronicon.ADT).variant_type(t))
            for (idx, field_idx) = enumerate(mask)
                print(io, names[idx], "=")
                show(io, (Base).getfield(t, field_idx))
                if idx < length(mask)
                    print(io, ", ")
                end
            end
            print(io, ")")
        elseif (Expronicon.ADT).variant_type(t) == Core.bitcast(var"Message#Type", 0x00000003)
            (Base).show(io, (Expronicon.ADT).variant_type(t))
            print(io, "(")
            mask = (Expronicon.ADT).variant_masks((Expronicon.ADT).variant_type(t))
            for (idx, field_idx) = enumerate(mask)
                show(io, (Base).getfield(t, field_idx))
                if idx < length(mask)
                    print(io, ", ")
                end
            end
            print(io, ")")
        elseif (Expronicon.ADT).variant_type(t) == Core.bitcast(var"Message#Type", 0x00000004)
            (Base).show(io, (Expronicon.ADT).variant_type(t))
            print(io, "(")
            mask = (Expronicon.ADT).variant_masks((Expronicon.ADT).variant_type(t))
            names = (Expronicon.ADT).variant_fieldnames((Expronicon.ADT).variant_type(t))
            for (idx, field_idx) = enumerate(mask)
                print(io, names[idx], "=")
                show(io, (Base).getfield(t, field_idx))
                if idx < length(mask)
                    print(io, ", ")
                end
            end
            print(io, ")")
        elseif (Expronicon.ADT).variant_type(t) == Core.bitcast(var"Message#Type", 0x00000005)
            (Base).show(io, (Expronicon.ADT).variant_type(t))
            print(io, "(")
            mask = (Expronicon.ADT).variant_masks((Expronicon.ADT).variant_type(t))
            for (idx, field_idx) = enumerate(mask)
                show(io, (Base).getfield(t, field_idx))
                if idx < length(mask)
                    print(io, ", ")
                end
            end
            print(io, ")")
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
end

@test_expr emit_variants(def, info) == quote
    function (Expronicon.ADT).variants(::Type{<:Message})
        return (Core.bitcast(var"Message#Type", 0x00000001), Core.bitcast(var"Message#Type", 0x00000002), Core.bitcast(var"Message#Type", 0x00000003), Core.bitcast(var"Message#Type", 0x00000004), Core.bitcast(var"Message#Type", 0x00000005))
    end
end

@test_expr emit_variant_type(def, info) == quote
    @inline function (Expronicon.ADT).variant_type(x::Message)
        return (Core).getfield(x, Symbol("#type"))
    end
end

@test_expr emit_variant_masks(def, info) == quote
    @inline function (Expronicon.ADT).variant_masks(t::var"Message#Type")
        if t == Core.bitcast(var"Message#Type", 0x00000001)
            ()
        elseif t == Core.bitcast(var"Message#Type", 0x00000002)
            (2, 3)
        elseif t == Core.bitcast(var"Message#Type", 0x00000003)
            (5,)
        elseif t == Core.bitcast(var"Message#Type", 0x00000004)
            (5, 6)
        elseif t == Core.bitcast(var"Message#Type", 0x00000005)
            (2, 3, 4)
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
    @inline function (Expronicon.ADT).variant_masks(x::Message)
        (Expronicon.ADT).variant_masks((Expronicon.ADT).variant_type(x))
    end
end

@test_expr emit_variant_typename(def, info) == quote
    @inline function (Expronicon.ADT).variant_typename(t::var"Message#Type")
        return if t == Core.bitcast(var"Message#Type", 0x00000001)
                :Quit
        elseif t == Core.bitcast(var"Message#Type", 0x00000002)
            :Move
        elseif t == Core.bitcast(var"Message#Type", 0x00000003)
            :Write
        elseif t == Core.bitcast(var"Message#Type", 0x00000004)
            :Aka
        elseif t == Core.bitcast(var"Message#Type", 0x00000005)
            :ChangeColor
        else
            throw(ArgumentError("invalid variant type"))
        end
    end

    @inline function (Expronicon.ADT).variant_typename(x::Message)
        return (Expronicon.ADT).variant_typename((Expronicon.ADT).variant_type(x))
    end
end

@test_expr emit_variant_fieldname(def, info) == quote
    @inline function (Expronicon.ADT).variant_fieldname(t::var"Message#Type", idx::Int)
        return ((Expronicon.ADT).variant_fieldnames(t))[idx]
    end
    @inline function (Expronicon.ADT).variant_fieldname(x::Message, idx::Int)
        return (Expronicon.ADT).variant_fieldname((Expronicon.ADT).variant_type(x), idx)
    end
end

@test_expr emit_variant_fieldtype(def, info) == quote
    @inline function (Expronicon.ADT).variant_fieldtype(t::var"Message#Type", idx::Int)
        return ((Expronicon.ADT).variant_fieldtypes(t))[idx]
    end
    @inline function (Expronicon.ADT).variant_fieldtype(x::Message, idx::Int)
        return (Expronicon.ADT).variant_fieldtype((Expronicon.ADT).variant_type(x), idx)
    end
end

@test_expr emit_variant_field_default(def, info) == quote
    @inline function (Expronicon.ADT).variant_field_default(t::var"Message#Type", idx::Int)
        return ((Expronicon.ADT).variant_field_defaults(t))[idx]
    end
    @inline function (Expronicon.ADT).variant_field_default(x::Message, idx::Int)
        return (Expronicon.ADT).variant_field_default((Expronicon.ADT).variant_type(x), idx)
    end
end

@test_expr emit_variant_fieldnames(def, info) == quote
    @inline function (Expronicon.ADT).variant_fieldnames(t::var"Message#Type")
        if t == Core.bitcast(var"Message#Type", 0x00000001)
            throw(ArgumentError("singleton variant or call variant has no field names"))
        elseif t == Core.bitcast(var"Message#Type", 0x00000002)
            (:x, :y)
        elseif t == Core.bitcast(var"Message#Type", 0x00000003)
            throw(ArgumentError("singleton variant or call variant has no field names"))
        elseif t == Core.bitcast(var"Message#Type", 0x00000004)
            (:x, :y)
        elseif t == Core.bitcast(var"Message#Type", 0x00000005)
            throw(ArgumentError("singleton variant or call variant has no field names"))
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
    @inline function (Expronicon.ADT).variant_fieldnames(x::Message)
        (Expronicon.ADT).variant_fieldnames((Expronicon.ADT).variant_type(x))
    end
end

@test_expr emit_variant_fieldtypes(def, info) == quote
    @inline function (Expronicon.ADT).variant_fieldtypes(t::var"Message#Type")
        if t == Core.bitcast(var"Message#Type", 0x00000001)
            ()
        elseif t == Core.bitcast(var"Message#Type", 0x00000002)
            (Int64, Int64)
        elseif t == Core.bitcast(var"Message#Type", 0x00000003)
            (String,)
        elseif t == Core.bitcast(var"Message#Type", 0x00000004)
            (Vector{Int64}, Vector{Int64})
        elseif t == Core.bitcast(var"Message#Type", 0x00000005)
            (Int64, Int64, Int64)
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
    @inline function (Expronicon.ADT).variant_fieldtypes(x::Message)
        (Expronicon.ADT).variant_fieldtypes((Expronicon.ADT).variant_type(x))
    end
end

@test_expr emit_variant_field_defaults(def, info) == quote
    @inline function (Expronicon.ADT).variant_field_defaults(t::var"Message#Type")
        if t == Core.bitcast(var"Message#Type", 0x00000001)
            ()
        elseif t == Core.bitcast(var"Message#Type", 0x00000002)
            (NoDefault(), NoDefault())
        elseif t == Core.bitcast(var"Message#Type", 0x00000003)
            ()
        elseif t == Core.bitcast(var"Message#Type", 0x00000004)
            (NoDefault(), NoDefault())
        elseif t == Core.bitcast(var"Message#Type", 0x00000005)
            ()
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
    @inline function (Expronicon.ADT).variant_field_defaults(x::Message)
        (Expronicon.ADT).variant_field_defaults((Expronicon.ADT).variant_type(x))
    end
end

@test_expr emit_getproperty(def, info) == quote
    function (Base).getproperty(value::Message, name::Symbol)
        name === :type && return (Expronicon.ADT).variant_type(value)
        if (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000001)
            throw(ArgumentError("singleton variant Quit does not have a field name"))
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000002)
            if name === :x
                return (Base).getfield(value, 2)::Int64
            elseif name === :y
                return (Base).getfield(value, 3)::Int64
            else
                throw(ArgumentError("invalid field name"))
            end
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000003)
            throw(ArgumentError("call variant Write does not have a field name"))
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000004)
            if name === :x
                return (Base).getfield(value, 5)::Vector{Int64}
            elseif name === :y
                return (Base).getfield(value, 6)::Vector{Int64}
            else
                throw(ArgumentError("invalid field name"))
            end
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000005)
            throw(ArgumentError("call variant ChangeColor does not have a field name"))
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
end

@test_expr emit_propertynames(def, info) == quote
    function (Base).propertynames(value::Message, private::Bool = false)
        if (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000001)
            return ()
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000002)
            return (:x, :y)
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000003)
            return ()
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000004)
            return (:x, :y)
        elseif (Expronicon.ADT).variant_type(value) == Core.bitcast(var"Message#Type", 0x00000005)
            return ()
        else
            throw(ArgumentError("invalid variant type"))
        end
    end
end

@test_expr emit_variant_binding(def, info) == nothing
@test_expr emit_exports(def, info) == nothing

pub_def = ADTTypeDef(Main, :Message, body; export_variants=true)
@test_expr emit_variant_binding(pub_def, info) == quote
    const Quit = Message(Core.bitcast(var"Message#Type", 0x00000001))
    const Move = Core.bitcast(var"Message#Type", 0x00000002)
    const Write = Core.bitcast(var"Message#Type", 0x00000003)
    const Aka = Core.bitcast(var"Message#Type", 0x00000004)
    const ChangeColor = Core.bitcast(var"Message#Type", 0x00000005)
end

@test_expr emit_exports(pub_def, info) == :(export Quit, Move, Write, Aka, ChangeColor, Message)

body = quote
    None
    # reference to a Julia variable
    Id(::Symbol)

    # <object>.<fieldname>
    struct Reference
        object::Union{Id, Reference} # Id or Reference
        fieldname::MubanLang # Id
        some::None
    end

    struct Template
        stmts::Vector{MubanLang}
    end
end
def = ADTTypeDef(Main, :MubanLang, body)
@test_throws ErrorException EmitInfo(def)

@testset "Vector{Variant}" begin
    body = quote
        Id(::Symbol)
        struct Template
            stmts::Vector{MubanLang}
        end
    end

    def = ADTTypeDef(Main, :MubanLang, body)
    info = EmitInfo(def)
    @test_expr info.typeinfo[def.variants[2]].guess[1] == :(Vector{MubanLang})
end

body = quote
    struct Waveform
        coeff::Vector{Float64}
        mask::BitVector
        shape
        duration::Float64
    end
end

def = ADTTypeDef(Main, :PulseLang, body)
info = EmitInfo(def)
@test_expr emit_struct(def, info) == quote
    Core.@__doc__ struct PulseLang
            var"#type"::var"PulseLang#Type"
            var"#Float64##2"::Float64
            var"#Any##3"
            var"#Any##4"
            var"#Any##5"
            function PulseLang(type::var"PulseLang#Type", args...)
                if type == Core.bitcast(var"PulseLang#Type", 0x00000001)
                    length(args) == 4 || throw(ArgumentError("expect $(4) arguments, got $(length(args)) arguments"))
                    if args[4] isa Float64
                        var"#args#2" = args[4]
                    else
                        var"#args#2" = (Base).convert(Float64, args[4])
                    end
                    if args[1] isa Vector{Float64}
                        var"#args#3" = args[1]
                    else
                        var"#args#3" = (Base).convert(Vector{Float64}, args[1])
                    end
                    if args[2] isa BitVector
                        var"#args#4" = args[2]
                    else
                        var"#args#4" = (Base).convert(BitVector, args[2])
                    end
                    if args[3] isa Any
                        var"#args#5" = args[3]
                    else
                        var"#args#5" = (Base).convert(Any, args[3])
                    end
                    new(type, var"#args#2", var"#args#3", var"#args#4", var"#args#5")
                else
                    throw(ArgumentError("invalid variant type"))
                end
            end
        end
end

end # module
