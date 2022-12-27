using ZhanKai.GitIgnore

# @adt public Pattern begin
#     Comment(::String)
    
#     Root
#     EmptyLine
#     Asterisk
#     DoubleAsterisk

#     Not(::Pattern)
#     Path(::Vector{Pattern})
#     # separator at the end of the pattern
#     # will match only directories
#     Directory(::Vector{Pattern})
# end

stmts = [
    Comment("This is a comment"),
    EmptyLine,
    Path([Root, Asterisk, Id("b"), DoubleAsterisk, Id("a"), Id("b")]),
    Directory([Root, Asterisk, Id("b"), DoubleAsterisk, Id("a"), Id("b")]),
    Not(Path([Asterisk, Id("b"), DoubleAsterisk, Id("a"), Id("b")])),
]

file = IgnoreFile("test", stmts)
s = """
#This is a comment

/*/b/**/a/b
/*/b/**/a/b/
!*/b/**/a/b
"""

GitIgnore.parse(IOBuffer(s), "test")
using Expronicon.ADT: variant_type
parse_pattern("a/b/**/a/b")
parse_pattern("!a/b/**/a/b")
parse_pattern("a/b/**/a/b/") |> variant_type

using ZhanKai.GitIgnore: split_segments, @pattern_str

buf = IOBuffer("a/b/**/a/b/")
read_segment(buf)

split_segments("a/b/**/a/b/")
pattern"a/b/**/a/b/"
