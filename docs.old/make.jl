using MLStyle
using Expronicon
using Documenter
using ANSIColoredPrinters
using DocumenterMarkdown

makedocs(;
    modules=[Expronicon],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Expronicon.jl/blob/{commit}{path}#{line}",
    sitename="Expronicon.jl",
    format=Markdown(),
    pages=[
        "Quick Start" => "index.md",
        "Case Study" => "case.md",
        "API Reference" => "reference.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/Expronicon.jl",
)
