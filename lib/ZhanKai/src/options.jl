function find_project_name(path::String, project_toml::String)
    project_toml_file = joinpath(path, project_toml)
    d = TOML.parsefile(project_toml_file)
    haskey(d, "name") || error("no name in $project_toml_file")
    return d["name"]
end

function find_uuid(build_dir::String, project::String, postfix::String, project_toml::String)
    built_project = joinpath(build_dir, project * postfix, project_toml)
    isfile(built_project) || return string(uuid1())
    d = TOML.parsefile(built_project)
    haskey(d, "uuid") || return string(uuid1())
    return d["uuid"]
end

# paths to exclude that is not in gitignore
function default_paths_to_ignore(project::String)
    Ignore(project, [
        fn".git", fn".github", fn"docs", fn"lib", fn"bin",
        fn"package.json", fn"yarn.lock",
        fn"Project.toml" # we will generate a new one
    ])
end

# dont touch these files, just copy them
function default_paths_dont_touch(project::String)
    Ignore(project, [
        fn"LICENSE",
        fn".gitignore",
        fn"README.md",
    ])
end

@option struct Options
    macronames::Vector{String}
    deps::Vector{String} = String[] # deps to remove

    project::String = pwd()
    project_toml::String = "Project.toml"
    project_name::String = find_project_name(pwd(), project_toml)
    postfix::String = "Lite"
    build_dir::String = "build"
    uuid::String = find_uuid(build_dir, project, postfix, project_toml)

    ignore::Ignore = default_paths_to_ignore(project)
    dont_touch::Ignore = default_paths_dont_touch(project)
end

function Base.show(io::IO, ::MIME"text/plain", opt::Options)
    println(io, "Options(")
    println(io, "    macronames = ", opt.macronames)
    println(io, "    deps = ", opt.deps)
    println(io, "    project = \"", opt.project, "\"")
    println(io, "    project_toml = \"", opt.project_toml, "\"")
    println(io, "    project_name = \"", opt.project_name, "\"")
    println(io, "    postfix = \"", opt.postfix, "\"")
    println(io, "    build_dir = \"", opt.build_dir, "\"")
    println(io, "    uuid = \"", opt.uuid, "\"")
    println(io, "    ignore = ", opt.ignore)
    println(io, "    dont_touch = ", opt.dont_touch)
    print(io, ")")
end

function ignore(path::String, options::Options)
    path_ = relpath(path, options.project)
    isnothing(options.ignore) || path_ in options.ignore && return true
    return false
end

function dont_touch(path::String, options::Options)
    path_ = relpath(path, options.project)
    return path_ in options.dont_touch
end

expand_name(options::Options) = options.project_name * options.postfix
project_dir(options::Options, xs...) = joinpath(options.project, xs...)

function build_dir(options::Options, xs...)
    return joinpath(options.build_dir, expand_name(options), xs...)
end
