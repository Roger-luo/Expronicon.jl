function find_project_name(path::String, project_toml::String)
    project_toml_file = joinpath(path, project_toml)
    d = TOML.parsefile(project_toml_file)
    haskey(d, "name") || error("no name in $project_toml_file")
    return d["name"]
end

function find_uuid(build_dir::String, project::String, postfix::String, project_toml::String)
    built_project = joinpath(project, build_dir, basename(project) * postfix, project_toml)
    isfile(built_project) || return string(uuid1())
    d = TOML.parsefile(built_project)
    haskey(d, "uuid") || return string(uuid1())
    return d["uuid"]
end

# paths to exclude that is not in gitignore
function default_paths_to_ignore(project::String)
    [
        ".git", ".github", "docs",
        "lib", "bin", "package.json",
        "yarn.lock", "Project.toml"
    ]
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

    ignore::Vector{String} = default_paths_to_ignore(project)
    dont_touch::Vector{String} = ["LICENSE", ".gitignore", "README.md"]
    ignore_test::Vector{String} = String[]
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
    println(io, "    ignore_test = ", opt.ignore_test)
    print(io, ")")
end

expand_name(options::Options) = options.project_name * options.postfix
project_dir(options::Options, xs...) = joinpath(options.project, xs...)

function build_dir(options::Options, xs...)
    return joinpath(options.build_dir, expand_name(options), xs...)
end
