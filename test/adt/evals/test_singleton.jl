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
    @match Apple begin
        Apple => @test true
        Orange => @test false
        Banana => @test false
    end
end

end # TestSingleton
