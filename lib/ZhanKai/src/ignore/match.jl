function Base.in(path::AbstractString, pattern::Pattern)
    return Base.in(parse_pattern(path), pattern)
end

function Base.in(path::Pattern, pattern::Pattern)
    @switch pattern begin
        @case Not(p)
            return !in(path, p)
        @case _
    end

    @switch (pattern, path) begin
        @case (Root, Root) || (Asterisk, Id(_)) || (DoubleAsterisk, _)
            return true
        @case (Id(name), Id(&name))
            return true
        @case (Path(segments_lhs), Path(segments_rhs)) || (Path(segments_lhs), Directory(segments_rhs))
            return match_segments(segments_lhs, segments_rhs)
        @case (Directory(segments_lhs), Directory(segments_rhs)) || (Directory(segments_lhs), Path(segments_rhs))
            isdir(string(path)) || return false
            return match_segments(segments_lhs, segments_rhs)
        @case _
            return false
    end
end

function match_segments(lhs::Vector{Pattern}, rhs::Vector{Pattern})
end
