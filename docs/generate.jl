using Expronicon
using Documenter
using DocumenterVitepress

# the VitePress site in docs/page is maintained by hand, so only the markdown
# for the API reference is generated here
makedocs(;
    modules=[Expronicon],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/Expronicon.jl/blob/{commit}{path}#{line}",
    sitename="Expronicon.jl",
    format=MarkdownVitepress(;
        repo="https://github.com/Roger-luo/Expronicon.jl",
        build_vitepress=false,
        install_npm=false,
        md_output_path=".",
    ),
    build=pkgdir(Expronicon, "docs_build"),
    doctest=false,
    source = "src",
    pages=[
        "API Reference" => "api.md",
    ],
)
