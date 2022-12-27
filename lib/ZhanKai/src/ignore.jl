struct Ignore
    path::String # root path
    files::Vector{String}
end

function Ignore(path::String, patterns::Vector{GlobMatch})
    files = String[]
    for p in patterns
        append!(files, glob(p, path))
    end
    return Ignore(path, files)
end

function Base.show(io::IO, ignore::Ignore)
    filepath = relpath(joinpath(ignore.path, ignore.file), pwd())
    print(io, "Ignore(\"", filepath, "\")")
end

function Base.show(io::IO, ::MIME"text/plain", ignore::Ignore)
    indent = get(io, :indent, 0)
    tab = "  "^indent
    printstyled(io, tab, "# path: ", ignore.path; color=:light_black)
    print(io, "\n\n")
    for (idx, p) in enumerate(ignore.patterns)
        print(io, tab, p.pattern)
        if idx < lastindex(ignore.patterns)
            println(io)
        end
    end
end

function Base.in(path::String, ignore::Ignore)
    return relpath(path, ignore.path) in ignore.files
end
