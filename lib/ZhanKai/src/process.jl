function read_tracked_files(path::String)
    return cd(path) do
        s = readchomp(`git ls-tree --full-tree --name-only -r HEAD`)
        split(s)
    end
end

struct ExpandInfo
    files_to_process::Vector{String}
    files_to_copy::Vector{String}
    tests_to_copy::Vector{String}
end

function Base.show(io::IO, info::ExpandInfo)
    println(io, "ExpandInfo(")
    println(io, "    files_to_process = [")
    for file in info.files_to_process
        print(io, "        \"", relpath(file, pwd()), "\"")
        println(io, ",")
    end
    println(io, "    ],")
    println(io, "    files_to_copy = [")
    for file in info.files_to_copy
        print(io, "        \"", relpath(file, pwd()), "\"")
        println(io, ",")
    end
    println(io, "    ],")
    println(io, "    tests_to_copy = [")
    for file in info.tests_to_copy
        print(io, "        \"", relpath(file, pwd()), "\"")
        println(io, ",")
    end
    println(io, "    ],")
    print(io, ")")
end

function ExpandInfo(option::Options)
    files_to_process = String[]
    files_to_copy = String[]
    tests_to_copy = String[]
    ignore = IgnoreFile(option.project, option.ignore)
    dont_touch = IgnoreFile(option.project, option.dont_touch)
    ignore_test = IgnoreFile(joinpath(option.project, "test"), option.ignore_test)

    for file in read_tracked_files(option.project)
        contains(ignore, file) && continue

        if startswith(relpath(file, option.project), "test")
            contains(ignore_test, file) && continue
            push!(tests_to_copy, file)
            continue
        end

        if contains(dont_touch, file)
            push!(files_to_copy, file)
        else
            push!(files_to_process, file)
        end
    end
    return ExpandInfo(files_to_process, files_to_copy, tests_to_copy)
end

function copy_dont_touch(info::ExpandInfo, options::Options)
    for src in info.files_to_copy
        dst = build_dir(options, relpath(src, options.project))
        ispath(dirname(dst)) || mkpath(dirname(dst))
        cp(src, dst; force=true)
    end
    return
end

# NOTE: put deps to extras or test/Project.toml if it is in Project.toml
function edit_test_deps!(project_toml::Dict, options::Options)
    haskey(project_toml, "deps") || return # no deps
    if haskey(project_toml, "extras")
        extras = project_toml["extras"]
        target = get!(project_toml, "targets", Dict("test"=>[]))
        test_target = get!(target, "test", String[])

        for package in options.deps
            haskey(project_toml["deps"], package) || error("package $package is not in deps")
            extras[package] = project_toml["deps"][package]
            push!(test_target, package)
        end
        return project_toml
    end

    test_project = project_dir(options, "test", "Project.toml")
    isfile(test_project) || error("cannot find test dependencies " * 
        "do you have a test/Project.toml or [extras] in Project.toml?")
    test_d = TOML.parsefile(test_project)
    haskey(test_d, "deps") || error("no deps in test/Project.toml")
    for package in options.deps
        haskey(d["deps"], package) || error("package $package is not in deps")
        test_d["deps"][package] = d["deps"][package]
    end

    test_dir = build_dir(options, "test")
    isdir(test_dir) || mkpath(test_dir)
    target_test_project = build_dir(options, relpath(test_project, options.project))
    open(target_test_project, "w+") do io
        TOML.print(io, test_d; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
    end
    return project_toml
end

function edit_project_deps(options::Options)
    project_toml = project_dir(options, options.project_toml)
    d = TOML.parsefile(project_toml)
    haskey(d, "name") || error("no name in Project.toml")
    haskey(d, "uuid") || error("no uuid in Project.toml")
    d["name"] = d["name"] * options.postfix
    d["uuid"] = options.uuid

    haskey(d, "deps") || return
    edit_test_deps!(d, options)

    for package in options.deps
        delete!(d["deps"], package)
        haskey(d, "compat") && delete!(d["compat"], package)
    end

    target_project_toml = build_dir(options, relpath(project_toml, options.project))
    open(target_project_toml, "w+") do io
        TOML.print(io, d; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
    end
    return
end

function object_to_expr(m::Module, ex)
    @match ex begin
        ::Union{Symbol, Int, Bool, Float64, String, Char, LineNumberNode} => ex
        ::QuoteNode => QuoteNode(object_to_expr(m, ex.value))
        Expr(head, args...) => Expr(head, map(x->object_to_expr(m, x), args)...)
        _ => begin
            s = sprint(print, ex; context=:module=>m)
            return Meta.parse("begin $s end").args[2]
        end
    end
end

function replace_module(m::Module, expr, options::Options)
    new = Symbol(options.project_name * options.postfix)
    old = Symbol(options.project_name)

    # convert object to expr
    ast = object_to_expr(m, expr)

    substitute(ex) = @match ex begin
        &old => new
        Expr(:., &old, args...) => Expr(:., new, map(substitute, args)...)
        Expr(head, args...) => Expr(head, map(substitute, args)...)
        _ => ex
    end

    return substitute(ast)
end

function rm_using(expr, options::Options)
    deps = map(Symbol, options.deps)
    sub = Substitute() do expr
        return Meta.isexpr(expr, (:using, :import))
    end
    return sub(expr) do imports
        @match imports begin
            Expr(:using, Expr(:(:), package, _...)) ||
                Expr(:import, Expr(:(:), package, _...)) ||
                Expr(:using, Expr(:(.), package, _...)) ||
                Expr(:import, Expr(:(.), package, _...)) => package in deps ? nothing : expr

            Expr(:using, packages...) => Expr(:using, filter(p->!(p in deps), packages))
            Expr(:import, packages...) => Expr(:import, filter(p->!(p in deps), packages))
        end
    end
end

function rm_test_include(file::String, expr, options::Options)
    ignore = IgnoreFile(joinpath(options.project, "test"), options.ignore_test)
    file_dir(xs...) = joinpath(dirname(file), xs...)
    sub = Substitute() do expr
        @match expr begin
            :(include($path)) || :(Base.include($path)) => contains(ignore, file_dir(path))
            _=> false
        end
    end
    return sub(_->nothing, expr)
end

function replace_include(file::String, expr, options::Options)
    ignore = IgnoreFile(options.project, options.ignore)
    file_dir(xs...) = joinpath(dirname(file), xs...)
    sub = Substitute() do expr
        @match expr begin
            :(include($path)) || :(Base.include($path)) => true
            _=> false
        end
    end
    return sub(expr) do ex
        @switch ex begin
            @case :(include($path)) || :(Base.include($path))
            @case _
        end

        contains(ignore, file_dir(path)) && return # ignore
        :(__include_generated__($path))
    end
end

function insert_toplevel(ex, code)
    @switch ex begin
        @case Expr(:module, bare, name, Expr(:block, stmts...))
            stmts = map(x->insert_toplevel(x, code), stmts)
            return Expr(:module, bare, name, Expr(:block, code, stmts...))
        @case Expr(head, args...)
            args = map(x->insert_toplevel(x, code), args)
            return Expr(head, args...)
        @case _
            return ex
    end
end

function insert_include_generated(ex)
    include_generated_def = quote
        @static if !isdefined(@__MODULE__(), :include_generated)
            function __include_generated__(_path::String)
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

function rm_single_toplevel_block(ex)
    @match ex begin
        Expr(:block, Expr(:module, args...)) => Expr(:module, args...)
        Expr(head, args...) => Expr(head, map(rm_single_toplevel_block, args)...)
        _ => ex
    end
end

function expand(m::Module, options::Options)
    info = ExpandInfo(options)
    isdir(build_dir(options)) || mkpath(build_dir(options))

    copy_dont_touch(info, options)
    edit_project_deps(options)

    N = length(info.files_to_process) + length(info.tests_to_copy)
    progress_count = 1

    @withprogress name="zhan" begin
        for src in info.files_to_process
            @info "processing $src"
            if basename(src) == options.project_name * ".jl"
                dst = build_dir(options, relpath(src, options.project))
                dst = joinpath(dirname(dst), options.project_name * options.postfix * ".jl")
            else
                dst = build_dir(options, relpath(src, options.project))
            end
            ast = expand_file(m, src, options)
            ast = replace_module(m, ast, options)
            ast = rm_using(ast, options)
            ast = replace_include(src, ast, options)
            ast = insert_include_generated(ast)
            ast = rm_single_toplevel_block(ast)
            ast = canonicalize_lambda_head(ast)
            ast = rm_lineinfo(ast)
            ast = rm_nothing(ast)
            write_file(m, ast, dst)

            @logprogress progress_count/N
            progress_count += 1
        end

        for src in info.tests_to_copy
            @info "processing $src"
            ast = parse_file(src)
            ast = replace_module(m, ast, options)
            ast = insert_include_generated(ast)
            ast = rm_single_toplevel_block(ast)
            ast = canonicalize_lambda_head(ast)
            ast = rm_test_include(src, ast, options)
            ast = rm_lineinfo(ast)
            ast = rm_nothing(ast)
            dst = build_dir(options, relpath(src, options.project))
            write_file(m, ast, dst)

            @logprogress progress_count/N
            progress_count += 1
        end
    end # progress
    return
end

function write_file(mod::Module, ast, dst::String)
    ispath(dirname(dst)) || mkpath(dirname(dst))
    open(dst, "w+") do io
        # show_block(io, "begin", ex, indent, quote_level)
        Base.show_block(IOContext(io, :module=>mod, :unquote_fallback => false), "", ast, 0, 0)
        # println(IOContext(io, :module=>mod), ast)
        # print_expr(io, ast)
    end
end
