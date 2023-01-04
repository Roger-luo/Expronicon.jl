module GitIgnore

export IgnoreFile, parse, @pattern_str

using MLStyle: @match, @switch, @case
using Expronicon.ADT: ADT, @adt
using Glob: FilenameMatch

include("types.jl")
include("print.jl")
include("parse.jl")
include("match.jl")

end # module
