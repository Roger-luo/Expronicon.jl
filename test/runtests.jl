using Expronicon
using Documenter
using Test

@testset "@test_expr" begin
    @test_expr quote
        x + 1
        $nothing
    end == quote
        x + 1
        $nothing
    end
end

@testset "analysis" begin
    include("analysis.jl")
end

@testset "transform" begin
    include("transform.jl")
end

doctest(Expronicon)
