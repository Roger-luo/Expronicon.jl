using Test
using MLStyle
using Expronicon.ADT: ADT, @adt, ADTTypeDef, EmitInfo,
    emit_variant_cons, variant_fieldnames, variant_masks,
    variant_type, variants, variant_typename, adt_type

@adt Message begin
    Quit

    struct Move
        x::Int
        y::Int = 1
    end

    Write(::String)

    ChangeColor(::Int, ::Int, ::Int)
end

@testset "basic patterns" begin
    @test 3 == @match Move(1, 2) begin
        Move(x, y) => x + y
        _ => false
    end

    @test 1 == @match Move(1, 2) begin
        Move(x, _...) => x
        _ => false
    end

    @test @match Move(1, 2) begin
        Move(_...) => true
        _ => false
    end

    @test 1 == @match Move(1, 2) begin
        Move(;x) => x
        _ => false
    end

    @test 3 == @match Move(1, 2) begin
        Move(;x, y) => x + y
        _ => false
    end

    @test false == @match Move(1, 2) begin
        Move(;x, y=3) => x
        _ => false
    end

    @test 1 == @match Move(1, 2) begin
        Move(;x, y=2) => x
        _ => false
    end
end
