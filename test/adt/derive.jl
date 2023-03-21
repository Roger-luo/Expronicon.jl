module Derive

using Test
using MLStyle
using Expronicon
using Expronicon.ADT: ADT, @adt, @derive

@adt MyADT begin
    Token
    struct Message
        x::Int
        y::Int
    end
end

@derive MyADT: hash, isequal, ==
@test_throws ErrorException begin
    @derive MyADT: isless
end

@testset "hash" begin
    @test hash(MyADT.Token) == hash(ADT.variant_type(MyADT.Token))
    msg = MyADT.Message(1, 2)
    h = hash(ADT.variant_type(msg))
    h = hash(1, h)
    h = hash(2, h)
    @test hash(msg) == h
end

@testset "isequal" begin
    @test isequal(MyADT.Message(1, 2), MyADT.Message(1, 2))
    @test !isequal(MyADT.Message(1, 2), MyADT.Message(1, 3))
end

@testset "==" begin
    @test MyADT.Message(1, 2) == MyADT.Message(1, 2)
    @test MyADT.Message(1, 2) != MyADT.Message(1, 3)
end

end # Derive
