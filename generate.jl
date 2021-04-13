using Expronicon
using MLStyle
using Pkg
using TOML


function expand_mlstyle(m::Module, ex)
    @switch ex begin
        @case Expr(:macrocall, Symbol("@match"), xs...) || Expr(:macrocall, Symbol("@switch"), xs...) ||
            Expr(:macrocall, Symbol("@λ"), xs...)
            return expand_mlstyle(m, macroexpand(m, ex))
        @case ::Expr
            return Expr(ex.head, map(x->expand_mlstyle(m, x), ex.args)...)
        @case _
            return ex
    end
end

function replace_include(m::Module, ex)
    @match ex begin
        :(include($path)) => quote
            @static if !isdefined(@__MODULE__(), :include_generated)
                function include_generated(m::Module, path::String)
                    raw = read(path, String)
                    ex = Meta.parse("quote $raw end")
                    ex = m.eval(ex)
                    eval_generated(m, ex)
                    return
                end
                
                function eval_generated(m, ex)
                    if ex isa Expr
                        if ex.head === :block
                            map(x->eval_generated(m, x), ex.args)
                        else
                            m.eval(ex)
                        end
                        return
                    else
                        m.eval(ex)
                        return
                    end
                end
            end
            include_generated(@__MODULE__(), joinpath(@__DIR__, $path))
        end
        ::Expr => Expr(ex.head, map(x->replace_include(m, x), ex.args)...)
        _ => ex
    end
end

function rm_using(name, ex)
    @match ex begin
        :(using $(&name)) => nothing
        :(using $(&name).$(_...)) => nothing
        Expr(head, args...) => Expr(head, map(x->rm_using(name, x), args)...)
        _ => ex
    end
end

function exclude_file(file::String, ex)
    @match ex begin
        :(include($(&file))) => nothing
        Expr(head, args...) => Expr(head, map(x->exclude_file(file, x), args)...)
        _ => ex
    end
end

function expand_file(m::Module, file::String, build_dir="build")
    src = read(file, String)
    ex = Meta.parse("begin $src end")
    dst = joinpath(build_dir, dirname(file))
    ispath(dst) || mkpath(dst)
    if basename(file) == "Expronicon.jl"
        file = joinpath(dirname(file), "ExproniconLite.jl")
    end
    open(joinpath(build_dir, file), "w+") do io
        ex = subtitute(ex, :Expronicon=>:ExproniconLite)
        ex = expand_mlstyle(m, ex)
        ex = exclude_file("match.jl", ex)
        ex = exclude_file("patches.jl", ex)
        ex = replace_include(m, ex)
        ex = rm_using(:MLStyle, ex)
        ex = prettify(ex)
        if ex isa Expr && ex.head === :block && length(ex.args) == 1
            ex = ex.args[1]
        end
        println(io, ex)
    end
end

function update_test(;excludes=[])
    for (root, dirs, files) in walkdir("test")
        for file in files
            file in excludes && continue
            path = joinpath(root, file)
            raw = read(path, String)
            raw = replace(raw, "Expronicon"=>"ExproniconLite")
            for each in excludes
                raw = replace(raw, "include(\"$each\")"=>"nothing")
            end
            write(joinpath("build", root, file), raw)
        end
    end
end

@info "expanding macro"

for each in readdir(dirname(pathof(Expronicon)))
    expand_file(Expronicon, joinpath("src", each))
end

@info "generate test"

update_test(;excludes=["match.jl"])

@info "copying docs"
cp("docs", joinpath("build", "docs"); force=true)

@info "generate Project.toml"
d = TOML.parsefile("Project.toml")
d["name"] = "ExproniconLite"
d["uuid"] = "55351af7-c7e9-48d6-89ff-24e801d99491"
delete!(d["deps"], "MLStyle")
delete!(d["compat"], "MLStyle")
open(joinpath("build", "Project.toml"), "w+") do io
    TOML.print(io, d; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
end
