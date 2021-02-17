using Test
using Yuan
using Yuan.Transform

@testset "name_only" begin
    @test name_only(:(x::Int)) == :x
    @test name_only(:(T <: Int)) == :T
    @test name_only(:(Foo{T} where T)) == :Foo
    @test name_only(:(Foo{T})) == :Foo
end
