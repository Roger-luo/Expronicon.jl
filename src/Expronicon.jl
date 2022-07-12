module Expronicon

using MLStyle
using MLStyle.MatchImpl
using MLStyle.AbstractPatterns

export 
    # types
    NoDefault, JLExpr, JLFor, JLIfElse,
    JLFunction, JLField, JLKwField, JLStruct, JLKwStruct,
    # analysis
    @expr, @test_expr, compare_expr, compare_vars,
    AnalysisError, is_function, is_kw_function, is_struct,
    is_ifelse, is_for, is_field, is_field_default, is_datatype_expr,
    is_matrix_expr,
    split_function, split_function_head, split_struct,
    split_struct_name, split_ifelse,
    uninferrable_typevars, has_symbol,
    is_literal, is_gensym,
    alias_gensym,
    has_kwfn_constructor,
    has_plain_constructor,
    # transformations
    no_default, prettify, rm_lineinfo, flatten_blocks, name_only,
    rm_annotations, rm_single_block, rm_nothing,
    replace_symbol, subtitute, eval_interp, eval_literal,
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
    print_expr, sprint_expr




include("patches.jl")
include("types.jl")
include("transform.jl")
include("analysis.jl")
include("codegen.jl")
include("printing.jl")
include("match.jl")
include("expand.jl")

end
