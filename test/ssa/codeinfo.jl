using Test
using Yuan.SSA


ci = code_lowered(cos, (Float64, ))[1]
ci, typ = code_typed(cos, (Float64, ))[1]
ir, typ = code_ircode(cos, (Float64, ))[1]
ir

stmt, type = obtain_const_or_stmt(SSAValue(50), ci)
@test ci.code[50] == stmt
@test ci.ssavaluetypes[50] == type
