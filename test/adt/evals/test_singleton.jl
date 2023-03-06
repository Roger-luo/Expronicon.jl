module TestSingleton

using Test
using MLStyle
using Expronicon.ADT: @adt

@adt Food begin
    Apple
    Orange
    Banana
end

@testset "singleton" begin
    @match Food.Apple begin
        &Food.Apple => @test true
        &Food.Orange => @test false
        &Food.Banana => @test false
    end
end

end # TestSingleton
