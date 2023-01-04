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

src = "test/analysis.jl"
ast = parse_file(src)
ast = ZhanKai.replace_block_call_syntax(ast.args[8])

s = sprint(show, ast; context=:module=>Expronicon)
write("test.jl", s)
println(Expr(:toplevel, ast.args[1]))