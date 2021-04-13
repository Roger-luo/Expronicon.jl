using Test
using MLStyle
using Expronicon


@testset "JLFunction pattern" begin
    f = @λ begin
        JLFunction(;head=:function, args) => args
        JLFunction(;head=:(=), name) => name
        _ => nothing 
    end

    @test f(:(function foo(x) x end)) == [:x]
    @test f(:(goo(x) = x)) === :goo
    @test f(:(1 + 1)) === nothing
end

@testset "JLStruct/JLKwStruct pattern" begin
    f = @λ begin
            JLStruct(;name) => (name, )
            JLKwStruct(;name, typealias) => (name, typealias)
            _ => nothing 
        end

    ex = @expr struct KwStructP
        x::Int = 1
    end

    @test f(ex) == (:KwStructP, nothing)

    ex = @expr struct StructP
        x::Int
    end

    @test f(ex) == (:StructP, )

    ex = :(foo(x) = x)
    @test f(ex) === nothing
end


@testset "JLIfElse pattern" begin    
    f = @λ begin
        JLIfElse(;map, otherwise) => (map, otherwise)
        _ => nothing
    end
    
    ex = @expr if x > 1
        x + 1
    else
        nothing
    end
    d, otherwise = f(ex)
    @test_expr d[:(x > 1)] == quote
        x + 1
    end
    @test_expr otherwise == quote
        nothing
    end

    ex = :(foo(x) = x)
    @test f(ex) === nothing
end

@testset "JLFor pattern" begin
    f = @λ begin
        JLFor(;vars) => vars
        _ => nothing
    end

    ex = @expr for i in 1:10, j in 1:l
        M[i, j] += 1
    end

    @test f(ex) == [:i, :j]
    @test f(:(1 + 1)) === nothing
end

@testset "patch" begin
    f = @λ begin
        Symbol(x) => x
        _ => nothing
    end

    @test f(:x) == "x"
    @test f(1) === nothing

    f = @λ begin
        GlobalRef(m, s) => (m, s)
        _ => nothing
    end

    @test f(GlobalRef(Main, :sin)) == (Main, :sin)
    @test f(:(1 + 1)) === nothing
end

@testset "codegen_match" begin
    ex = codegen_match(:x) do
        quote
            1 => true
            2 => false
            _ => nothing
        end
    end

    eval(codegen_ast(JLFunction(;name=:test_match, args=[:x], body=ex)))

    @test test_match(1) == true
    @test test_match(2) == false
    @test test_match(3) === nothing
end

@testset "JLMatch" begin
    jl = JLMatch(:x)
    jl.map[1] = true
    jl.map[2] = :(sin(x))
    println(jl)
    ex = codegen_ast(jl)
    jl = JLFunction(;name=:test_match, args=[:x], body=ex)
    println(jl)
    eval(codegen_ast(jl))

    @test test_match(1) == true
    @test test_match(2) == sin(2)
    @test test_match(3) === nothing
end