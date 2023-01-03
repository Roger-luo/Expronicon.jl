function parse(path::String)
    return open(path) do io
        parse(io, path)
    end
end

function parse(io::IO, path::String)
    stmts = map(eachline(io)) do line
        @match line begin
            if startswith(line, "#") end => Comment(line[2:end])
            if isempty(line) end => EmptyLine
            _ => parse_pattern(line)
        end
    end
    return IgnoreFile(path, stmts)
end

parse_pattern(s::AbstractString) = parse_pattern(IOBuffer(s))

function parse_pattern(io::IO)
    mark(io)
    read(io, Char) == '!' && return Not(parse_pattern(io))
    reset(io)

    pc, c = '\0', '\0'
    buf = IOBuffer()
    patterns = Pattern[]
    readchar() = (pc = c; c = read(io, Char); c)

    while !eof(io)
        readchar()
        if c == '\\'
            write(buf, read(io, Char))
        elseif pc == '\0' && c == '/'
            push!(patterns, Root)
        elseif c == '*'
            readchar()
            if c == '*'
                push!(patterns, DoubleAsterisk)
                eof(io) && return Path(patterns)
                readchar() == '/' && continue
                eof(io) || error("expect EOF or '/' after '**'")
            else
                write(buf, '*'); write(buf, c)
            end
        elseif c == '/'
            push!(patterns, FileName(String(take!(buf))))
        else
            write(buf, c)
        end
    end
    push!(patterns, FileName(String(take!(buf))))

    c == '/' && (pop!(patterns); return Directory(patterns))
    return Path(patterns)
end

macro pattern_str(s)
    return esc(parse_pattern(s))
end
