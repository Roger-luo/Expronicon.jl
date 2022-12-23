struct Ignore{P <: FilenameMatch}
    path::String # root path
    file::String # ignore file
    patterns::Vector{P}
end

Ignore(path::String, patterns) = Ignore(path, "<in-memory>", patterns)

function Ignore(path::String) # read from ignore file
    patterns = FilenameMatch[]
    open(path) do f
        for line in eachline(f)
            startswith(line, "#") && continue
            isempty(line) && continue
            push!(patterns, FilenameMatch(line))
        end
    end
    return Ignore(dirname(abspath(path)), basename(path), patterns)
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
    any(ignore.patterns) do p
        occursin(p, relpath(path, ignore.path)) && return true
        if startswith(p.pattern, "/") # use ignore.path as root
            p = FilenameMatch(joinpath(ignore.path, p.pattern[2:end]), p.options)
            if !isabspath(path) # path is relative to ignore.path
                path_ = joinpath(ignore.path, path)
            end
            occursin(p, path_) && return true
        end
        return false
    end
end
