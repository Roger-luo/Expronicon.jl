using Metagrams
using Documenter

DocMeta.setdocmeta!(Metagrams, :DocTestSetup, :(using Metagrams); recursive=true)

makedocs(;
    modules=[Metagrams],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Metagrams.jl/blob/{commit}{path}#{line}",
    sitename="Metagrams.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Roger-luo.github.io/Metagrams.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/Metagrams.jl",
)
