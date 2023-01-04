using ZhanKai
using Expronicon

# project_dir = pkgdir(ZhanKai)
# test_dir = joinpath(project_dir, "test")
build_dir = pkgdir(ZhanKai, "test", "build")
rm(build_dir; force=true, recursive=true)

cd(pkgdir(Expronicon)) do
    option = ZhanKai.Options(;
        macronames=["match", "switch"], deps=["MLStyle"],
        build_dir,
        ignore=[
            ".git", ".github", "docs",
            "lib", "bin", "package.json",
            "yarn.lock", "Project.toml",
            "src/patches.jl", "src/match.jl", "src/expand.jl", "src/adt/**",
        ],
        ignore_test = ["adt/**", "match.jl", "expand.jl"],
    )
    ZhanKai.expand(Expronicon, option)
end

cd(joinpath(build_dir, "ExproniconLite")) do
    mkpath("docs")
    mkpath("docs/src")
    touch("docs/README.md")
    touch("docs/src/index.md")
    run(`$(Base.julia_cmd()) --project -e 'using Pkg; Pkg.test()'`)
end

rm(build_dir; force=true, recursive=true)
