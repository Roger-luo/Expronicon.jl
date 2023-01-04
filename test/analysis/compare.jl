using Test
using Expronicon: compare_expr

lhs = :(function (x; y) end)
rhs = Expr(:function, Expr(:tuple, Expr(:parameters, :y), :x))
@test compare_expr(lhs, rhs)

lhs = :(function (x; y) end)
rhs = Expr(:function, Expr(:tuple, Expr(:parameters, :y), :x), nothing)
@test compare_expr(lhs, rhs)
