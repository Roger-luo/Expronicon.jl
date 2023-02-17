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
    include("print/inline.jl")
    include("print/multi.jl")
    include("print/old.jl")
    include("print/tree.jl")

    @static if VERSION > v"1.8-"
        include("print/lts.jl")
    end
end

@testset "types" begin
    include("types.jl")
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

DocMeta.setdocmeta!(Expronicon, :DocTestSetup, :(using Expronicon); recursive=true)
doctest(Expronicon)
