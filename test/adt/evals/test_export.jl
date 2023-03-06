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

@testset "TestExport" begin
    @test :PulseLang in names(TestExport)
    @test :Waveform in names(TestExport)
end

end # TestExport
