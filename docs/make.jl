using MLStyle
using Expronicon
using Documenter
using ANSIColoredPrinters
using DocumenterTools: Themes

DocMeta.setdocmeta!(Expronicon, :DocTestSetup, :(using Expronicon); recursive=true)
Themes.compile(joinpath(@__DIR__, "src/assets/main.scss"))

makedocs(;
    modules=[Expronicon],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Expronicon.jl/blob/{commit}{path}#{line}",
    sitename="Expronicon.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Roger-luo.github.io/Expronicon.jl",
        assets=String["assets/main.css"],
    ),
    pages=[
        "Quick Start" => "index.md",
        "Syntax Types" => "types.md",
        "Analysis" => "analysis.md",
        "Transform" => "transform.md",
        "CodeGen" => "codegen.md",
        "Printings" => "printings.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/Expronicon.jl",
)
