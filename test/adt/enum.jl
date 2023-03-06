module TestEnum

using Test
using MLStyle
using Expronicon.ADT: ADT, @adt, @use, ADTTypeDef, EmitInfo,
    emit_variant_cons, variant_fieldnames, variant_masks,
    variant_type, variants, variant_typename, adt_type

@adt AddressMaskErr begin
    Ok
    InvalidSyntax(::Int, ::Char)
    BinLengthNotMatch(::Int, ::Int)
    InvalidChannelType(::Int, ::Char)
    ChannelTypeTooLong(::Int)
end

@use AddressMaskErr: *

@testset "singleton enum match" begin
    e = BinLengthNotMatch(1, 2)
    @match e begin
        Ok => @test false
        e => @test true
        _ => @test false
    end

    @match Ok begin
        Ok => @test true
        _ => @test false
    end
end

end
