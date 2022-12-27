@adt public Pattern begin
    Comment(::String)
    
    Root
    EmptyLine
    Asterisk
    DoubleAsterisk

    Id(::String)
    Not(::Pattern)

    struct Path
        segments::Vector{Pattern}
    end

    # separator at the end of the pattern
    # will match only directories
    struct Directory
        segments::Vector{Pattern}
    end
end

struct IgnoreFile
    path::String
    stmts::Vector{Pattern}
end
