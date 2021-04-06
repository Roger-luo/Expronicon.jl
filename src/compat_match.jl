using MLStyle

"""
    @support_matching XXX is_xxx

# Example
```julia
struct MyFunction
    ex :: Expr
    test_field :: Any
end

is_xxx(ex::Expr) = Meta.isexpr(ex, :function)
is_xxx(_) = false

julia> MyFunction(ex::Expr) = MyFunction(ex, :aaa)
julia> @support_matching(MyFunction, is_xxx)

julia> @match :(function f() end) begin
        MyFunction(;test_field) => test_field
    end
:aaa
```
"""
macro support_matching(XXX, is_xxx)
    ex = quote
        $__source__
        function $MLStyle.pattern_uncall(
            t::Type{$XXX},
            self::Function,
            type_params::Any,
            type_args::Any,
            args::Any,
        )
            $__source__
            type_infer(_...) = Union{Expr, t}  # type of input
            transform(expr) = :($($is_xxx)($expr) ? $($XXX)($expr) : nothing)
            $MLStyle.AbstractPatterns.P_fast_view(
                type_infer,
                transform,
                $MLStyle.Record._compile_record_pattern(t, self, type_params, type_args, args)
            )
        end
    end
    esc(ex)
end
