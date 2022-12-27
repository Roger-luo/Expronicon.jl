using ZhanKai.IgnoreFile
using ZhanKai.IgnoreFile: parse
Root
Asterisk
DoubleAsterisk
Id("a")
Paths(Root, Paths(Asterisk, DoubleAsterisk))

parse("/aaa/bbb/*/a")
