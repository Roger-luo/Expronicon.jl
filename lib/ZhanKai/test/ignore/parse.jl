using Test
using Expronicon.ADT: variant_type
using ZhanKai.GitIgnore
using ZhanKai.GitIgnore: dump_ignore

@test variant_type(pattern"!/*/b/**/a/b") == Not
@test variant_type(pattern"/*/b/**/a/b") == Path
@test variant_type(pattern"/*.jl/b/**/a/b/") == Directory
@test variant_type(pattern"/*[a-zA-Z]?.jl/b/**/a/b/") == Directory

stmts = [
    Comment("This is a comment"),
    EmptyLine,
    Path([Root, FileName("*"), FileName("b"), DoubleAsterisk, FileName("a"), FileName("b")]),
    Directory([Root, FileName("*"), FileName("b"), DoubleAsterisk, FileName("a"), FileName("b")]),
    Not(Path([FileName("*"), FileName("b"), DoubleAsterisk, FileName("a"), FileName("b")])),
]

s = """
#This is a comment

/*/b/**/a/b
/*/b/**/a/b/
!*/b/**/a/b
"""
file = GitIgnore.parse(IOBuffer(s), "test")
buf = IOBuffer()
dump_ignore(buf, file)
@test String(take!(buf)) == s

buf = IOBuffer()
print(buf, file)
@test String(take!(buf)) == 
"""
IgnoreFile("test", Pattern[pattern"#This is a comment", pattern"EmptyLine", pattern"/*/b/**/a/b", pattern"/*/b/**/a/b/", pattern"!*/b/**/a/b"])"""

buf = IOBuffer()
show(buf, MIME"text/plain"(), file)
@test String(take!(buf)) == """
# ignore path: test

#This is a comment

/*/b/**/a/b
/*/b/**/a/b/
!*/b/**/a/b
"""

# root_dir(xs...) = normpath(pkgdir(ZhanKai, "..", "..", xs...))
# ignore = GitIgnore.parse(root_dir(".gitignore"))
# contains(ignore, "Manifest.toml")
# contains(ignore, "build")
