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
    isfile(test_project) || error("cannot find test dependencies\
        do you have a test/Project.toml or [extras] in Project.toml?")
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

function replace_module(expr, options::Options)
    new = Symbol(options.project_name * options.postfix)
    old = Symbol(options.project_name)

    # convert object to expr
    s = sprint_expr(expr)
    ast = Meta.parse("begin $s end")

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

function rm_include(file::String, expr, options::Options)
    ignore = IgnoreFile(options.project, options.ignore)
    file_dir(xs...) = joinpath(dirname(file), xs...)
    sub = Substitute() do expr
        @match expr begin
            :(include($path)) || :(Base.include($path)) => begin
                contains(ignore, file_dir(path))
            end
            _=> false
        end
    end
    return sub(expr) do ex
        return
    end
end

function expand(m::Module, options::Options)
    info = ExpandInfo(options)
    isdir(build_dir(options)) || mkpath(build_dir(options))

    copy_dont_touch(info, options)
    edit_project_deps(options)

    for src in info.files_to_process
        @info "processing $src"
        if basename(src) == options.project_name * ".jl"
            dst = build_dir(options, relpath(src, options.project))
            dst = joinpath(dirname(dst), options.project_name * options.postfix * ".jl")
        else
            dst = build_dir(options, relpath(src, options.project))
        end
        ast = expand_file(m, src, options)
        ast = replace_module(ast, options)
        ast = rm_using(ast, options)
        ast = rm_include(src, ast, options)
        ast = rm_lineinfo(ast)
        ast = rm_nothing(ast)
        write_file(ast, dst)
    end

    for src in info.tests_to_copy
        @info "processing $src"
        ast = parse_file(src)
        ast = replace_module(ast, options)
        ast = rm_lineinfo(ast)
        ast = rm_nothing(ast)
        dst = build_dir(options, relpath(src, options.project))
        write_file(ast, dst)
    end
    return
end

function write_file(ast, dst::String)
    ispath(dirname(dst)) || mkpath(dirname(dst))
    open(dst, "w+") do io
        print_expr(io, ast)
    end
end
