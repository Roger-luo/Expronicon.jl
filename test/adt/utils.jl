using Test
using Expronicon.ADT: @adt, Reference, load, undef_value

struct RandomBitsType
    x::Int
    y::Int
end

struct RandomNonBitsType
    x::Int
    y
end

@testset "undef_value" begin
    @test undef_value(Int) === 0
    @test undef_value(RandomBitsType) isa RandomBitsType
    @test undef_value(RandomNonBitsType) === nothing
end

@adt TestCaseUtils begin
    Quit
    Write(::RandomBitsType)
end

@testset "custom struct" begin
    @test Quit isa TestCaseUtils
    @test Write(RandomBitsType(1, 2)) isa TestCaseUtils
end
