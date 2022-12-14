using Expronicon
using Documenter
using DocumenterMarkdown

makedocs(;
    modules=[Expronicon],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Expronicon.jl/blob/{commit}{path}#{line}",
    sitename="Expronicon.jl",
    format=Markdown(),
    build=pkgdir(Expronicon, "docs_build"),
    doctest=false,
    source = "src",
    pages=[
        "API Reference" => "reference.md",
    ],
)
