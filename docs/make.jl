using Yuan
using Documenter

DocMeta.setdocmeta!(Yuan, :DocTestSetup, :(using Yuan); recursive=true)

makedocs(;
    modules=[Yuan],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Yuan.jl/blob/{commit}{path}#{line}",
    sitename="Yuan.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Roger-luo.github.io/Yuan.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/Yuan.jl",
)
