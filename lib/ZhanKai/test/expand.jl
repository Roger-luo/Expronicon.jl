using Expronicon: Expronicon, print_expr, prettify, print_inline, Substitute
using MLStyle: @match
using ZhanKai: ZhanKai, parse_file, expand_macro, expand, IgnoreFile
using ZhanKai: ExpandInfo, edit_project_deps, expand, read_tracked_files
option = ZhanKai.Options(;
    macronames=["match", "switch"], deps=["MLStyle"],
    ignore=[
        ".git", ".github", "docs",
        "lib", "bin", "package.json",
        "yarn.lock", "Project.toml",
        "src/patches.jl", "src/match.jl", "src/expand.jl", "src/adt/**",
    ],
    ignore_test = ["adt/**", "match.jl", "expand.jl"],
)

ExpandInfo(option)
expand(Expronicon, option)

using Expronicon: splitlines

splitlines(:("aaaa\n$(Abc)aaaa"))