using ZhanKai
using Test

@testset "ZhanKai.jl" begin
    # Write your tests here.
end

using ZhanKai: scan_expand_files, ignore, scan_dont_touch, ExpandInfo, edit_project_deps
option = ZhanKai.Options(;macronames=["match", "switch"])
ExpandInfo(option)
scan_expand_files(option)
scan_dont_touch(option)

using Glob

ismatch(fn".git/*", ".git/")

p = "/Users/roger/Code/Julia/Expronicon/Manifest.toml"
occursin(fn"/Manifest.toml", "Manifest.toml")
option.ignore
p in option.gitignore
relpath(p, option.project) in option.gitignore
relpath(p, option.project)