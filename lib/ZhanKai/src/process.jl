struct ExpandInfo
    files_to_process::Vector{String}
    files_to_copy::Vector{String}
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
    print(io, ")")
end

function ExpandInfo(option::Options)
    return ExpandInfo(scan_expand_files(option), scan_dont_touch(option))
end

function scan_expand_files(options::Options)
    return scan_expand_files!(String[], options.project, options)
end

function scan_expand_files!(files::Vector{String}, root::String, options::Options)
    ignore(root, options) && return files
    dont_touch(root, options) && return files

    isfile(root) && return files
    for path in readdir(root)
        full = joinpath(root, path)
        ignore(full, options) && continue
        dont_touch(full, options) && continue

        isdir(full) && scan_expand_files!(files, full, options)
        isfile(full) && push!(files, full)
    end
    return files
end

function scan_dont_touch(options::Options)
    return scan_dont_touch!(String[], options.project, options)
end

function scan_dont_touch!(files::Vector{String}, root::String, options::Options)
    ignore(root, options) && return files

    if isfile(root)
        dont_touch(root, options) && push!(files, root)
        return files
    end

    for path in readdir(root)
        full = joinpath(root, path)
        ignore(full, options) && continue
        
        if dont_touch(full, options)
            isdir(full) && scan_expand_files!(files, full, options)
            isfile(full) && push!(files, full)
        end
    end
    return files
end

function copy_dont_touch(info::ExpandInfo, options::Options)
    for src in info.files_to_copy
        dst = build_dir(options, relpath(src, options.project))
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
    open(test_project, "w+") do io
        TOML.print(io, test_d; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
    end
    return project_toml
end

function edit_project_deps(options::Options)
    project_toml = project_dir(options, options.project_toml)
    d = TOML.parsefile(project_toml)
    haskey(d, "deps") || return
    edit_test_deps!(d, options)

    for package in options.deps
        delete!(d["deps"], package)
        haskey(d, "compat") && delete!(d["compat"], package)
    end

    open(project_toml, "w+") do io
        TOML.print(io, d; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
    end
    return
end
