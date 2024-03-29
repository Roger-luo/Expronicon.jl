using Test
using Expronicon
using Expronicon: file_to_exclude
project_dir = pkgdir(Expronicon)
test_dir = joinpath(project_dir, "test")
build_dir = joinpath(test_dir, "build")
rm(build_dir; force=true, recursive=true)

options = ExpandOptions(;
    mod=Expronicon,
    build_dir=build_dir,
    uuid="55351af7-c7e9-48d6-89ff-24e801d99491",
    macronames=[Symbol("@match"), Symbol("@switch"), Symbol("@λ")],
    exclude_src=["match.jl", "expand.jl", "patches.jl", "adt.jl", "adt"],
    src_dont_touch=["types.jl", "codegen.jl"],
    exclude_paths=[
        "README.md",
        "node_modules",
        joinpath("test", "match.jl"),
        joinpath("test", "expand.jl"),
        joinpath("test", "adt.jl"),
        joinpath("test", "adt"),
        "generate.jl",
        joinpath("docs", "Manifest.toml"),
        joinpath("docs", "build"),
        "Manifest.toml", "build",
        ".git", "bin", ".vscode",
        ".github",
    ],
    exclude_modules=[:TOML, :Pkg, :MLStyle]
)



cd(project_dir) do
    expand_project(;
        mod=Expronicon,
        build_dir=build_dir,
        uuid="55351af7-c7e9-48d6-89ff-24e801d99491",
        macronames=[Symbol("@match"), Symbol("@switch"), Symbol("@λ")],
        exclude_src=["match.jl", "expand.jl", "patches.jl", "adt.jl", "adt"],
        src_dont_touch=["types.jl", "codegen.jl"],
        exclude_paths=[
            "README.md",
            joinpath("test", "match.jl"),
            joinpath("test", "expand.jl"),
            joinpath("test", "adt.jl"),
            joinpath("test", "adt"),
            "generate.jl",
            joinpath("docs", "Manifest.toml"),
            joinpath("docs", "build"),
            "Manifest.toml", "build",
            ".git", "bin", ".vscode",
            ".github",
        ],
        exclude_modules=[:TOML, :Pkg, :MLStyle]
    )
end

cd(build_dir) do
    run(`$(Base.julia_cmd()) --project -e 'using Pkg; Pkg.test()'`)
end

rm(build_dir; force=true, recursive=true)

options = ExpandOptions(
    mod=Expronicon,
    uuid="55351af7-c7e9-48d6-89ff-24e801d99491",
    macronames=[Symbol("@match"), Symbol("@switch"), Symbol("@λ")],
    exclude_src=["match.jl", "expand.jl", "patches.jl"],
    src_dont_touch=["types.jl", "codegen.jl"],
    exclude_paths=[
        "README.md",
        joinpath("test", "match.jl"),
        joinpath("test", "expand.jl"),
        "generate.jl",
        "node_modules",
        joinpath("docs", "Manifest.toml"),
        joinpath("docs", "build"),
        "Manifest.toml", "build",
        ".git", "bin", ".vscode",
        ".github",
    ],
    exclude_modules=[:TOML, :Pkg, :MLStyle]
)
