using Test
using Expronicon

@test is_tuple(:((a, b, c)))
@test is_splat(:(f(x)...))
