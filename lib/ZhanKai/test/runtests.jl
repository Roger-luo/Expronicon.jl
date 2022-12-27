using ZhanKai
using Test

@testset "ZhanKai.jl" begin
    # Write your tests here.
end

using ZhanKai: ExpandInfo, edit_project_deps, expand
option = ZhanKai.Options(;macronames=["match", "switch"], deps=["MLStyle"])
info = ExpandInfo(option)
expand(Expronicon, option)
