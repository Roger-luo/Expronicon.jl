module Expronicon

using MLStyle
using Markdown
using OrderedCollections
using MLStyle.MatchImpl
using MLStyle.AbstractPatterns

export 
    # types
    NoDefault, JLExpr, JLFor, JLIfElse, JLMatch,
    JLFunction, JLField, JLKwField, JLStruct, JLKwStruct,
    # analysis
    AnalysisError, is_fn, is_kw_fn, split_function, split_function_head, split_struct,
    split_struct_name, split_ifelse, annotations, uninferrable_typevars, has_symbol,
    is_literal,
    # transformations
    no_default, prettify, rm_lineinfo, flatten_blocks, name_only,
    rm_annotations, replace_symbol, subtitute, eval_interp, eval_literal,
    # codegen
    codegen_ast,
    codegen_ast_kwfn,
    codegen_ast_struct,
    codegen_ast_struct_curly,
    codegen_ast_struct_head,
    codegen_ast_struct_body,
    codegen_match,
    # printings
    with_marks, with_parathesis, with_curly, with_brackets, within_line, within_indent,
    with_begin_end, indent, no_indent, no_indent_first_line, indent_print, indent_println




include("patches.jl")
include("types.jl")
include("transform.jl")
include("analysis.jl")
include("codegen.jl")
include("printing.jl")

end
