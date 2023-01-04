abstract type IgnoreStream end

mutable struct PatternStream <: IgnoreStream
    segments::Vector{Pattern}
    ptr::Int
    dir::Bool
    not::Bool
end

PatternStream(pattern::String) = PatternStream(parse_pattern(pattern))

function PatternStream(pattern::Pattern, not::Bool = false)
    return @match pattern begin
        Path(segments) => PatternStream(segments, 1, false, not)
        Directory(segments) => PatternStream(segments, 1, true, not)
        Not(p) => PatternStream(p, !not)
        _ => PatternStream([pattern], 1, false, not)
    end
end

mutable struct PathStream <: IgnoreStream
    segments::Vector{SubString}
    path::String
    ptr::Int
end

function PathStream(path::AbstractString, start::String=pwd())
    return PathStream(split(relpath(path, start), '/'), path, 1)
end

Base.string(stream::PathStream) = stream.path
Base.seek(stream::IgnoreStream, ptr::Int) = (stream.ptr = ptr)
Base.length(stream::IgnoreStream) = length(stream.segments)
Base.eof(stream::IgnoreStream) = stream.ptr > length(stream)
current_token(stream::IgnoreStream) = stream.ptr > 1 ? stream.segments[stream.ptr - 1] : error("No current token")

function next_token(stream::IgnoreStream)
    stream.ptr > length(stream) && error("EOF reached")
    token = stream.segments[stream.ptr]
    stream.ptr += 1
    return token
end

function Base.contains(p::Pattern, s::AbstractString)
    return contains(PatternStream(p), PathStream(s))
end

function Base.contains(p::IgnoreFile, s::AbstractString)
    return any(p.stmts) do stmt
        contains(PatternStream(stmt), PathStream(s, p.path))
    end    
end

function Base.contains(p::PatternStream, s::PathStream)
    ret = path_contains(p, s)
    p.not && return !ret
    return ret
end

function path_contains(p::PatternStream, s::PathStream)
    p.dir && (isdir(string(s)) || return false)
    length(p) == 1 && @match first(p.segments) begin
        DoubleAsterisk => return true
        FileName(name) => return any(s.segments) do segment
            occursin(FilenameMatch(name), segment)
        end
        _ => return false
    end

    # skip the root token since it is only used
    # to distinguish name match or path match
    p.segments[1] == Root && next_token(p)
    while !eof(s) && !eof(p)
        s_token, p_token = next_token(s), next_token(p)
        next = @match (s_token, p_token) begin
            ("", Root) => true
            (_, DoubleAsterisk) => accept_double_asterisk(s, p)
            (_, FileName(pattern_s)) => occursin(FilenameMatch(pattern_s), s_token)
            _ => false
        end
        next || return false
    end
    eof(s) && eof(p) && return true
    eof(s) && return false
    # eof(p)
    p_token == DoubleAsterisk && return true
    return false
end

function eat_double_asterisk(p::PatternStream)
    while !eof(p)
        @match next_token(p) begin
            DoubleAsterisk => continue
            _ => break
        end
    end
    return current_token(p)
end

function accept_double_asterisk(s::PathStream, p::PatternStream)
    p_token = eat_double_asterisk(p) # p_token is the token after the double asterisk
    p_token == DoubleAsterisk && return true # /**^ is always true
    s_token = current_token(s)
    while !eof(s)
        @match (s_token, p_token) begin
            (_, FileName(pattern_s)) => occursin(FilenameMatch(pattern_s), s_token) && return true
            _ => continue
        end
        s_token = next_token(s)
    end
    return false
end
