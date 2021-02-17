using Yuan
using Test

@testset "analysis" begin
    include("analysis.jl")
end

@testset "transform" begin
    include("transform.jl")
end
