using Exmonicon
using Documenter

DocMeta.setdocmeta!(Exmonicon, :DocTestSetup, :(using Exmonicon); recursive=true)

makedocs(;
    modules=[Exmonicon],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Exmonicon.jl/blob/{commit}{path}#{line}",
    sitename="Exmonicon.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Roger-luo.github.io/Exmonicon.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/Exmonicon.jl",
)
