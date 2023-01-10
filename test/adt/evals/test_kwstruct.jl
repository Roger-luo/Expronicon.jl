module TestKwStruct

using Test
using Expronicon.ADT: @adt

@adt AT begin
    struct A
        common_field::Int = 0
        a::Bool = true
        b::Int = 10
    end

    struct B
        a::Int = 1
        foo::Float64 = sin(a)
    end
end

@testset "KwStruct" begin
    a = A()
    @test a.common_field == 0
    @test a.a == true
    @test a.b == 10

    b = B()
    @test b.a == 1
    @test b.foo == sin(1)
end

end # TestKwStruct
