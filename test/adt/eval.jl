module TestEvalPulse

using Test
using Expronicon.ADT: @adt

@adt PulseLang begin
    struct Waveform
        coeff::Vector{Float64}
        mask::BitVector
        shape
        duration::Float64
    end
end

wf = Waveform([1.0, 2.0], trues(2), 1, 1.0)
@testset "eval(PulseLang)" begin
    @test wf.coeff == [1.0, 2.0]
    @test wf.mask == trues(2)
    @test wf.shape == 1
    @test wf.duration == 1.0
end

end # TestEvalPulse

module TestExport

using Test
using Expronicon.ADT: @adt

@adt public PulseLang begin
    struct Waveform
        coeff::Vector{Float64}
        mask::BitVector
        shape
        duration::Float64
    end
end

@testset "TestExport" begin
    @test :PulseLang in names(TestExport)
    @test :Waveform in names(TestExport)
end

end # TestExport

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
