module ZhanKai

using Expronicon: Substitute, print_expr, prettify
using Expronicon.ADT: @adt
using Configurations: @option, Maybe
using MLStyle: @match
using Glob: @glob_str, GlobMatch, glob
using GarishPrint: pprint_struct
using TOML: TOML
using UUIDs: uuid1
using Pkg: Pkg

include("ignore/ignore.jl")
# include("ignore.jl")
# include("options.jl")
# include("expand.jl")
# include("process.jl")

end
