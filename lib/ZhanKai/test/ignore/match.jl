using Test
using ZhanKai: ZhanKai
using ZhanKai.GitIgnore

curr = pwd()
cd(pkgdir(ZhanKai, "test", "ignore"))

@test contains(pattern"a/b/**/a/b", "a/b/ssss/c/a/b")
@test contains(pattern"build", "build")
@test contains(pattern"build", "project/bar/build")
@test contains(pattern"!build", "build") == false
@test contains(pattern"project/*.md", "project/README.md") == true
@test contains(pattern"/abc.md", "abc.md")
@test contains(pattern"abc.md", "foo/abc.md") == true
@test contains(pattern"/abc.md", "foo/abc.md") == false
@test contains(pattern"src/adt/**", "src/adt/adt.jl") == true

@testset "directory match" begin
    @test contains(pattern"project/", "project") == true
    @test contains(pattern"!project/", "project") == false
    @test contains(pattern"frotz/", "project/bar/frotz") == true
end

cd(curr)
