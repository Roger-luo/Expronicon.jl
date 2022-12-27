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

split_segments(s::String) = split_segments(IOBuffer(s))

function split_segments(io::IO)
    function read_segment()
        buf = IOBuffer()
        while !eof(io)
            c = read(io, Char)
            if c == '/'
                return String(take!(buf)), true
            elseif c == '\\' # escape
                c = read(io, Char)
                write(buf, c)
            else
                write(buf, c)
            end
        end
        return String(take!(buf)), false
    end

    segments = String[]
    has_sep = false
    while !eof(io)
        segment, has_sep = read_segment()
        push!(segments, segment)
    end
    has_sep && push!(segments, first(read_segment()))
    return segments
end

parse_pattern(s::String) = parse_pattern(IOBuffer(s))

function parse_pattern(io::IO)::Pattern
    mark(io)
    read(io, Char) == '!' && return Not(parse_pattern(io))
    reset(io)

    segments = Pattern[]
    segment_s = split_segments(io)
    cons = if last(segment_s) == ""
        pop!(segment_s)
        Directory
    else
        Path
    end

    if first(segment_s) == ""
        push!(segments, Root)
        popfirst!(segment_s)
    end

    for s in segment_s
        segment = @match s begin
            "*" => Asterisk
            "**" => DoubleAsterisk
            name => Id(name)
        end
        push!(segments, segment)
    end
    return cons(segments)
end

macro pattern_str(s)
    return esc(parse_pattern(s))
end
