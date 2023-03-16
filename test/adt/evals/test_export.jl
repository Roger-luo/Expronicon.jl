module TestExport

using Test
using Expronicon.ADT: @adt, @export_use

@adt PulseLang begin
    struct Waveform
        coeff::Vector{Float64}
        mask::BitVector
        shape
        duration::Float64
    end
end

export PulseLang
@export_use PulseLang: *

@adt public Foo begin
    A(::Int)
    B(::Float64)
end

@testset "TestExport" begin
    @test :PulseLang in names(TestExport)
    @test :Waveform in names(TestExport)
    @test :Foo in names(TestExport)
    @test :A in names(TestExport)
    @test :B in names(TestExport)
end

end # TestExport
