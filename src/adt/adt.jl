module ADT

using MLStyle
using MLStyle.MatchImpl: and, P_capture, guard
using ..Expronicon
using ..Expronicon: Maybe

include("utils.jl")
include("traits.jl")
include("types.jl")
include("emit.jl")
include("match.jl")
include("print.jl")

end # ADT
