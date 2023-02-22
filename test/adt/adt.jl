using Test

@testset "types" begin
    include("types.jl")
end

@testset "emit" begin
    include("emit.jl")
end

@testset "match" begin
    include("match.jl")
    include("enum.jl")
end

@testset "eval" begin
    include("eval.jl")
end

@testset "print" begin
    include("tree.jl")
    include("tree_inline.jl")
end
