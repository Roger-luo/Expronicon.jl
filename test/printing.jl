using Expronicon
using MLStyle

print_expr(:(name::type))
print_expr(:("abc $name"))

ex = :(function compare_expr(lhs, rhs)
@switch (lhs, rhs) begin
    @case (::Symbol, ::Symbol)
        lhs === rhs
    @case (Expr(:curly, name, lhs_vars...), Expr(:curly, &name, rhs_vars...))
        all(map(compare_vars, lhs_vars, rhs_vars))
    @case (Expr(:where, lbody, lparams...), Expr(:where, rbody, rparams...))
        compare_expr(lbody, rbody) &&
            all(map(compare_vars, lparams, rparams))
    @case (Expr(head, largs...), Expr(&head, rargs...))
            isempty(largs) && isempty(rargs) ||
        (length(largs) == length(rargs) && all(map(compare_expr, largs, rargs)))
    # ignore LineNumberNode
    @case (::LineNumberNode, ::LineNumberNode)
        true
    @case _
        lhs == rhs
end
end)

