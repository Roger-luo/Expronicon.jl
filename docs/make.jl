using Expronicon
using Documenter

DocMeta.setdocmeta!(Expronicon, :DocTestSetup, :(using Expronicon); recursive=true)

makedocs(;
    modules=[Expronicon],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Expronicon.jl/blob/{commit}{path}#{line}",
    sitename="Expronicon.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Roger-luo.github.io/Expronicon.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "types" => "types.md",
        "Analysis" => "analysis.md",
        "Transform" => "transform.md",
        "CodeGen" => "codegen.md",
        "Printings" => "printings.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/Expronicon.jl",
)
