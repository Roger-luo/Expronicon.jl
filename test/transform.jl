using Test
using Yuan
using Yuan.Transform

@testset "name_only" begin
    @test name_only(:(x::Int)) == :x
    @test name_only(:(T <: Int)) == :T
    @test name_only(:(Foo{T} where T)) == :Foo
    @test name_only(:(Foo{T})) == :Foo
end

@testset "rm_lineinfo" begin
    ex = quote
        1 + 1
        2 + 2
    end
    
    @test rm_lineinfo(ex) == Expr(:block, :(1 + 1), :(2 + 2))        
end

@testset "flatten_blocks" begin
    ex = quote
        1 + 1
        begin
            2 + 2
        end
    end
    
    @test rm_lineinfo(flatten_blocks(ex)) == Expr(:block, :(1+1), :(2+2))        
end
