@adt Pattern begin
    Comment(::String)
    
    Root
    EmptyLine
    DoubleAsterisk # ** is special to gitignore, not a glob pattern
    Not(::Pattern) # this is the leading '!' in gitignore
    FileName(::String) # this will match a glob pattern

    struct Path
        segments::Vector{Pattern}
    end

    # separator at the end of the pattern
    # will match only directories
    struct Directory
        segments::Vector{Pattern}
    end
end

@export_use Pattern: *

struct IgnoreFile
    path::String
    stmts::Vector{Pattern}
end

function IgnoreFile(path::String, patterns::Vector{String})
    stmts = map(patterns) do pattern
        parse_pattern(pattern)
    end
    return IgnoreFile(path, stmts)
end
