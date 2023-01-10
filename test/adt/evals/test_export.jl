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
