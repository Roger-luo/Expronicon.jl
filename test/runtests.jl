using Expronicon
using Documenter
using Test
using Aqua
Aqua.test_all(Expronicon)

@test_expr quote
    x + 1
    $nothing
end == quote
    x + 1
    $nothing
end

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

@testset "adt" begin
    include("adt/adt.jl")
end

# this feature is only available for 1.6+
@static if VERSION > v"1.6-" && Sys.isunix()
    @testset "expand" begin
        include("expand.jl")
    end
end

DocMeta.setdocmeta!(Expronicon, :DocTestSetup, :(using Expronicon); recursive=true)
doctest(Expronicon)

@macroexpand @test 1 + x