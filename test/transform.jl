using Test
using Expronicon

@testset "name_only" begin
    @test name_only(:(x::Int)) == :x
    @test name_only(:(T <: Int)) == :T
    @test name_only(:(Foo{T} where T)) == :Foo
    @test name_only(:(Foo{T})) == :Foo
    @test_throws ErrorException name_only(Expr(:fake))
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

@testset "rm_annotations" begin
    ex = quote
        x :: Int
        begin
            y::Float64
        end
    end
    
    @test rm_lineinfo(rm_annotations(ex)) == quote
        x
        begin
            y
        end
    end|>rm_lineinfo
    
    ex = :(sin(::Float64; x::Int=2))
    ex = rm_annotations(ex)
    @test ex.head === :call
    @test ex.args[1] === :sin
    @test ex.args[2].head === :parameters
    @test ex.args[2].args[1] === :x
    @test ex.args[3] isa Symbol
end

@testset "prettify" begin
    ex = quote
        x :: Int
        begin
            y::Float64
        end
    end

    @test prettify(ex) == quote
        x::Int
        y::Float64
    end|>rm_lineinfo
end

global_x = 2

@testset "eval_interp" begin
    ex = Expr(:call, :+, Expr(:$, :global_x), 1)
    @test eval_interp(Main, ex) == :(2 + 1)    
end

@testset "eval_literal" begin
    ex = :(for i in 1:10
        1 + 1
    end)
    @test rm_lineinfo(eval_literal(Main, ex)) == rm_lineinfo(:(for i in $(1:10)
        2
    end))
end

@testset "subtitute" begin
    @test subtitute(:(x + 1), :x=>:y) == :(y + 1)
    @test subtitute(:(for i in 1:10;x += i;end), :x => :y) == :(for i in 1:10;y += i;end)
end
