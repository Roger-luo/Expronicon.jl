export expand_project, expand_file, ExpandOptions

using Pkg
using TOML

function rm_using(names::Vector{Symbol}, ex)
    for name in names
        ex = rm_using(name, ex)
    end
    return ex
end

function rm_include(paths::Vector{String}, ex)
    for path in paths
        ex = rm_include(path, ex)
    end
    return ex
end

function substitute(f, ex, new)
    @match ex begin
        GuardBy(f) => new
        Expr(head, args...) => Expr(head, map(x->substitute(f, x, new), args)...)
        _ => ex
    end
end

function rm_using(name::Symbol, ex)
    @match ex begin
        :(using $(&name)) => nothing
        :(using $(&name).$(_...)) => nothing
        Expr(head, args...) => Expr(head, map(x->rm_using(name, x), args)...)
        _ => ex
    end
end

function rm_include(path::String, ex)
    @match ex begin
        :(include($(&path))) => nothing
        Expr(head, args...) => Expr(head, map(x->rm_include(path, x), args)...)
        _ => ex
    end
end

function insert_toplevel(ex, code)
    @switch ex begin
        @case Expr(:module, bare, name, Expr(:block, stmts...))
            stmts = map(x->insert_toplevel(x, code), stmts)
            return Expr(:module, bare, name, Expr(:block, code, stmts...))
        @case _
            return ex
    end
end

function expand_macro(m::Module, ex; macronames=[])
    @switch ex begin
        @case Expr(:macrocall, name, line, xs...)
            if name in macronames
                return expand_macro(m, macroexpand(m, ex); macronames=macronames)
            else
                xs = map(x->expand_macro(m, x; macronames=macronames), xs)
                return Expr(:macrocall, name, line, xs...)
            end
        @case Expr(head, args...)
            args = map(args) do x
                expand_macro(m, x; macronames=macronames)
            end
            return Expr(head, args...)
        @case _
            return ex
    end
end

Base.@kwdef struct ExpandOptions
    mod::Module
    macronames::Vector{Any}=[]
    project::Symbol = nameof(mod)
    project_toml::String = "Project.toml"
    postfix::Symbol = :Lite
    build_dir::String = "build"
    uuid::String
    exclude_src::Vector{String} = String[] # src/*.jl to exclude
    exclude_paths::Vector{String} = String[] # misc path to exclude
    exclude_modules::Vector{Symbol} = Symbol[] # modules to remove
    src_dont_touch::Vector{String} = String[] # src/* not touch
end

# NOTE:
# this should not be an API
# it should be part of the implement detail
# of expand_file
function _replace_include(ex, options::ExpandOptions)
    @match ex begin
        :(include($path)) => begin
            if path in options.src_dont_touch
                return ex
            else
                return _xinclude_generated(path)
            end
        end
        ::Expr => Expr(ex.head, map(x->_replace_include(x, options), ex.args)...)
        _ => ex
    end
end

function _insert_include_generated(ex)
    include_generated_def = quote
        @static if !isdefined(@__MODULE__(), :include_generated)
            function _include_generated(_path::String)
                Base.@_noinline_meta
                mod = @__MODULE__()
                path, prev = Base._include_dependency(mod, _path)
                code = read(path, String)
                tls = task_local_storage()
                tls[:SOURCE_PATH] = path
                try
                    ex = include_string(mod, "quote $code end", path)
                    mod.eval(mod.eval(ex))
                    return
                finally
                    if prev === nothing
                        delete!(tls, :SOURCE_PATH)
                    else
                        tls[:SOURCE_PATH] = prev
                    end
                end
            end
        end
    end
    return insert_toplevel(ex, include_generated_def)
end

function _insert_var_str(ex)
    var_str = quote
        @static if VERSION < v"1.3"
            macro var_str(x)
                Symbol(x)
            end
        end
    end

    return insert_toplevel(ex, var_str)
end

function _xinclude_generated(path)
    return quote
        _include_generated($path)
    end
end


function expand_file(src, dst; kw...)
    expand_file(src, dst, ExpandOptions(;kw...))
end

function parse_file(src)
    raw = read(src, String)
    ex = Meta.parse("begin $raw end")
    return prettify(ex)
end

function expand_file(src, dst, options::ExpandOptions)
    ex = parse_file(src)
    ispath(dirname(dst)) || mkpath(dirname(dst))

    @info "substitute module identifier"
    old_mod = options.project
    new_mod = Symbol(options.project, options.postfix)
    ex = subtitute(ex, old_mod=>new_mod)
    ex = expand_macro(options.mod, ex; macronames=options.macronames)
    ex = rm_include(options.exclude_src, ex)
    ex = rm_include(options.exclude_paths, ex)
    ex = rm_using(options.exclude_modules, ex)
    ex = _insert_var_str(ex)
    ex = _insert_include_generated(ex)
    ex = _replace_include(ex, options)
    ex = prettify(ex)

    open(dst, "w+") do io
        println(io, ex)
    end
end

function expand_project(; kw...)
    expand_project(ExpandOptions(;kw...))
end

function expand_project(options::ExpandOptions)
    if Sys.iswindows()
        error("expand_project does not support windows")
    end

    pathof(options.mod) === nothing && error("not a project module")
    project_dir = dirname(dirname(pathof(options.mod)))
    @info "expanding macro"
    src_dir = joinpath(project_dir, "src")
    for (root, dirs, files) in walkdir(src_dir)
        for file in files
            src = joinpath(root, file)
            relsrc = relpath(src, src_dir)
            relsrc in options.exclude_src && continue
            if file == string(options.project, ".jl") && root == src_dir
                dst = joinpath(options.build_dir, "src",
                    string(options.project, options.postfix, ".jl"))
            else
                dst = joinpath(options.build_dir, "src", relsrc)
            end

            if relsrc in options.src_dont_touch
                cp(src, dst; force=true)
            else
                @info "expanding..." src dst
                expand_file(src, dst, options)
            end
        end
    end

    @info "copying other files..."
    for each in readdir(project_dir)
        each == "src" && continue
        each == options.project_toml && continue
        each in options.exclude_paths && continue
        src = joinpath(project_dir, each)

        if isfile(src)
            dst = joinpath(options.build_dir, each)
            _cp(src, dst, options)
        else
            # check if there are files to exclude
            for (root, dirs, files) in walkdir(src)
                for file in files
                    path = joinpath(root, file)
                    relpath(path, project_dir) in options.exclude_paths && continue
                    dst = joinpath(options.build_dir, relpath(path, project_dir))
                    _cp(path, dst, options)
                end
            end
        end
    end

    # rm packages + rename project
    @info "generating new $(options.project_toml)"
    d = TOML.parsefile(joinpath(project_dir, options.project_toml))
    d["name"] = string(options.project, options.postfix)
    d["uuid"] = options.uuid

    # NOTE:
    # we don't need to care about test deps
    for each in options.exclude_modules
        package = string(each)
        delete!(d["deps"], package)
        delete!(d["compat"], package)
    end

    open(joinpath(options.build_dir, options.project_toml), "w+") do io
        TOML.print(io, d; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
    end
    return
end

function _cp(src, dst, options::ExpandOptions)
    @info "copying..." src dst
    raw = read(src, String)
    # replace project module name
    old = string(options.mod)
    new = string(options.mod, options.postfix)
    raw = replace(raw, old=>new)

    for each in options.exclude_paths
        # use local path
        path = normpath(relpath(each, dirname(src)))
        raw = replace(raw, "include(\"$path\")"=>"nothing")
    end
    dst_dir = dirname(dst)
    ispath(dst_dir) || mkpath(dst_dir)
    write(dst, raw)
end
