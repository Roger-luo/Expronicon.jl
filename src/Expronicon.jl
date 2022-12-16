module Expronicon

using MLStyle
using MLStyle.MatchImpl
using MLStyle.AbstractPatterns

export 
    # types
    NoDefault, JLExpr, JLFor, JLIfElse,
    JLFunction, JLField, JLKwField, JLStruct, JLKwStruct,
    # analysis
    @expr, @test_expr, compare_expr,
    AnalysisError, is_function, is_kw_function, is_struct, is_tuple, is_splat,
    is_ifelse, is_for, is_field, is_field_default, is_datatype_expr,
    is_matrix_expr,
    split_function, split_function_head, split_struct,
    split_struct_name, split_ifelse,
    uninferrable_typevars, has_symbol,
    is_literal, is_gensym,
    alias_gensym,
    has_kwfn_constructor,
    has_plain_constructor,
    guess_type,
    guess_module,
    # transformations
    Substitute, no_default, prettify, rm_lineinfo, flatten_blocks, name_only,
    annotations_only, rm_annotations, rm_single_block, rm_nothing,
    substitute, eval_interp, eval_literal, renumber_gensym,
    expr_map, nexprs,
    # codegen
    codegen_ast,
    codegen_ast_kwfn,
    codegen_ast_kwfn_plain,
    codegen_ast_kwfn_infer,
    codegen_ast_struct,
    codegen_ast_struct_head,
    codegen_ast_struct_body,
    struct_name_plain,
    struct_name_without_inferable,
    # x functions
    xtuple,
    xnamedtuple,
    xcall,
    xpush,
    xgetindex,
    xfirst,
    xlast,
    xprint,
    xprintln,
    xmap,
    xmapreduce,
    xiterate,
    # printings
    print_inline,
    print_expr,
    sprint_expr


@static if !@isdefined(eachsplit)
    eachsplit(s, pat) = split(s, pat)
end

include("patches.jl")
include("types.jl")
include("transform.jl")
include("analysis/analysis.jl")
include("codegen.jl")
include("print/print.jl")

# cannot be bootstrapped
# include("printing.jl")
include("match.jl")
include("expand.jl")
include("adt/adt.jl")

end
