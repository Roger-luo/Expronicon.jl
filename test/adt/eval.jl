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
