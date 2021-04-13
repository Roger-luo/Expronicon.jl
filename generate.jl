using Expronicon


misc = map(splitpath.(split(read(".gitignore", String)))) do xs
    joinpath(xs...)
end

expand_project(;
    mod=Expronicon,
    uuid="55351af7-c7e9-48d6-89ff-24e801d99491",
    macronames=[Symbol("@match"), Symbol("@switch"), Symbol("@λ")],
    exclude_src=["match.jl", "expand.jl", "patches.jl"],
    src_dont_touch=["types.jl", "codegen.jl"],
    exclude_paths=["test/match.jl", ".git", "bin", misc...],
    exclude_modules=[:TOML, :Pkg, :MLStyle]
)

rm("build"; force=true, recursive=true)

raw = read("src/types.jl", String);
ex = Meta.parse("begin $raw end")
old_mod = options.project
new_mod = Symbol(options.project, options.postfix)
ex = subtitute(ex, old_mod=>new_mod)
ex = Expronicon.expand_macro(options.mod, ex; macronames=options.macronames)
ex = Expronicon.rm_include(options.exclude_src, ex)
ex = Expronicon.rm_include(options.exclude_paths, ex)
ex = Expronicon.rm_using(options.exclude_modules, ex)
ex = Expronicon._replace_include(options.mod, ex)

print_expr(ex)

ex = rm_lineinfo(ex)
ex = flatten_blocks(ex)
ex = rm_nothing(ex)
ex = rm_single_block(ex)
prettify(ex)
ex
rm_lineinfo(ex)