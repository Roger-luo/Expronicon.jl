module GitIgnore

export IgnoreFile, parse

using MLStyle: @match, @switch, @case
using Expronicon.ADT: ADT, @adt

include("types.jl")
include("print.jl")
include("parse.jl")
include("match.jl")

end # module
