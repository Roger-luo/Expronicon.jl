module SSA

using MLStyle

export NewCodeInfo,
    # reexport SSA nodes from Core
    CodeInfo,
    SSAValue,
    Const,
    PartialStruct,
    Slot,
    GotoIfNot,
    GotoNode,
    SlotNumber,
    Argument,
    NewvarNode,
    ReturnNode,
    # reexport IRCode types from Core
    IRCode,
    obtain_codeinfo,
    obtain_const,
    obtain_const_or_stmt,
    # reflections
    code_ircode,
    code_ircode_by_signature

using Base: get_world_counter

using Core:
    CodeInfo,
    SSAValue,
    Const,
    PartialStruct,
    Slot,
    GotoIfNot,
    GotoNode,
    SlotNumber,
    Argument,
    NewvarNode,
    ReturnNode

using Core.Compiler:
    InferenceParams,
    InferenceResult,
    OptimizationParams,
    OptimizationState,
    Bottom,
    AbstractInterpreter,
    NativeInterpreter,
    VarTable,
    InferenceState,
    CFG,
    NewSSAValue,
    IRCode,
    InstructionStream,
    CallMeta

using Core.Compiler:
    get_world_counter,
    get_inference_cache,
    may_optimize,
    isconstType,
    isconcretetype,
    widenconst,
    isdispatchtuple,
    isinlineable,
    is_inlineable_constant,
    copy_exprargs,
    convert_to_ircode,
    coverage_enabled,
    argtypes_to_type,
    userefs,
    UseRefIterator,
    UseRef,
    MethodResultPure,
    is_pure_intrinsic_infer,
    intrinsic_nothrow,
    quoted,
    anymap,
    # Julia passes
    compact!,
    ssa_inlining_pass!,
    getfield_elim_pass!,
    adce_pass!,
    type_lift_pass!,
    verify_linetable,
    verify_ir,
    retrieve_code_info,
    slot2reg

include("patches.jl")
include("codeinfo.jl")
include("ircode.jl")

end
