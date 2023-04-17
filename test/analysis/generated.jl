using Test
using Expronicon

jl = @expr JLFunction Base.@generated foo() = 1
@test jl.generated === true
@test_expr codegen_ast(jl) == :((Base).@generated foo() = 1)
