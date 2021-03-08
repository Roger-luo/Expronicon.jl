using YuanExpr
using Documenter

DocMeta.setdocmeta!(YuanExpr, :DocTestSetup, :(using YuanExpr); recursive=true)

makedocs(;
    modules=[YuanExpr],
    authors="Roger-luo <rogerluo.rl18@gmail.com> and contributors",
    repo="https://github.com/Roger-luo/YuanExpr.jl/blob/{commit}{path}#{line}",
    sitename="YuanExpr.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Roger-luo.github.io/YuanExpr.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Roger-luo/YuanExpr.jl",
)
