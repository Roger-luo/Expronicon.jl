using Test
using Expronicon.ADT: ADT, EmitInfo, ADTTypeDef, @adt, emit_struct,
    emit_show, emit_reflection, emit_variant_binding,
    emit_getproperty, emit_propertynames

@testset "EmitInfo(::ADTTypeDef)" begin
    body = quote
        Quit
        
        struct Move
            x::Int
            y::Int
        end

        Write(::String)

        struct Aka
            x::Vector{Int}
            y::Vector{Int}
        end

        ChangeColor(::Int, ::Int, ::Int)
    end

    def = ADTTypeDef(Main, :Message, body)
    info = EmitInfo(def)
    @test info.variant_masks[def.variants[1]] == Int[]
    @test info.variant_masks[def.variants[2]] == [1, 2]
    @test info.variant_masks[def.variants[3]] == [4]
    @test info.variant_masks[def.variants[4]] == [4, 5]
    @test info.variant_masks[def.variants[5]] == [1, 2, 3]

    @test info.fieldtypes == [Int, Int, Int, Any]
    @test length(info.fieldnames) == 4

    io = IOBuffer()
    show(io, MIME"text/plain"(), info)
    @test String(take!(io)) == """
    EmitInfo:
      Fields: 
        #Int64##1::Int64
        #Int64##2::Int64
        #Int64##3::Int64
        #Any##4::Any

      Variants:
        struct Aka => [4, 5]
            x::Vector{Int}
            y::Vector{Int}
        end
        ChangeColor(::Int, ::Int, ::Int) => [1, 2, 3]
        struct Move => [1, 2]
            x::Int
            y::Int
        end
        Quit => Int64[]
        Write(::String) => [4]"""
end

info = EmitInfo(def)
emit_struct(def, info)
emit_show(def, info)
emit_reflection(def, info)
emit_getproperty(def, info)
emit_propertynames(def, info)
emit_variant_binding(def, info)


@adt Message begin
    Quit
        
    struct Move
        x::Int
        y::Int
    end

    Write(::String)

    struct Aka
        x::Vector{Int}
        y::Vector{Int}
    end

    ChangeColor(::Int, ::Int, ::Int)
end

t = ADT.variant_type(Quit);
show(stdout, t)

eval(emit_variant_binding(def, info))
emit_show(def, info)
show(stdout, Quit)
ADT.variant_type(Quit) == Quit
