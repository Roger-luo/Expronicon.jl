using YuanExpr
using Documenter
using Test

@testset "analysis" begin
    include("analysis.jl")
end

@testset "transform" begin
    include("transform.jl")
end

doctest(YuanExpr)
