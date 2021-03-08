using Test
using Yuan.SSA


ci = obtain_codeinfo(cos, (Float64, ))

obtain_const_or_stmt(SSAValue(50), ci)
