using Expronicon: print_expr, prettify, print_inline, Substitute
using MLStyle: @match
using ZhanKai: parse_file, expand_macro

ex = parse_file("src/Expronicon.jl")
print_expr(ex)

ex = parse_file("src/print/inline.jl")
using ZhanKai: scan_expand_files, ignore, scan_dont_touch, ExpandInfo, edit_project_deps, expand
option = ZhanKai.Options(;macronames=["match", "switch"], deps=["MLStyle"])
expand_macro(Expronicon, ex, option)|>print_expr
