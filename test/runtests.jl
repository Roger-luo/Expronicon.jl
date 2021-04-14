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

@testset "printings" begin
    include("printing.jl")
end

@testset "analysis" begin
    include("analysis.jl")
end

@testset "transform" begin
    include("transform.jl")
end

@testset "match" begin
    include("match.jl")
end

@testset "codegen" begin
    include("codegen.jl")
end

# this feature is only available for 1.6+
@static if VERSION > v"1.6-" && Sys.isunix()
    @testset "expand" begin
        include("expand.jl")
    end
end

doctest(Expronicon)
