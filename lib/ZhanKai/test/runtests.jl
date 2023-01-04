using ZhanKai
using Test

@testset "ignore" begin
    include("ignore/ignore.jl")
end

@testset "expand" begin
    include("expand.jl")
end
