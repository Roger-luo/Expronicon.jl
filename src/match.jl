"""
    @syntax_pattern <syntax type> <syntax checker>

# Example

```julia
struct MyFunction
    ex :: Expr
    test_field :: Any
end

is_xxx(ex::Expr) = Meta.isexpr(ex, :function)
is_xxx(_) = false

julia> MyFunction(ex::Expr) = MyFunction(ex, :aaa)
julia> @syntax_pattern(MyFunction, is_xxx)

julia> @match :(function f() end) begin
        MyFunction(;test_field) => test_field
    end
:aaa
```
"""
macro syntax_pattern(type, checker)
    ex = quote
        $__source__
        function $MLStyle.pattern_uncall(
            t::Type{$type},
            self::Function,
            type_params::Any,
            type_args::Any,
            args::Any,
        )
            $__source__
            type_infer(_...) = Union{Expr, t}  # type of input
            transform(expr) = :($($checker)($expr) ? $($type)($expr) : nothing)
            $MLStyle.AbstractPatterns.P_fast_view(
                type_infer,
                transform,
                $MLStyle.Record._compile_record_pattern(t, self, type_params, type_args, args)
            )
        end
    end
    return esc(ex)
end

@syntax_pattern JLFunction  is_function
@syntax_pattern JLStruct    is_struct_not_kw_struct
@syntax_pattern JLKwStruct  is_struct
@syntax_pattern JLIfElse    is_ifelse
@syntax_pattern JLFor       is_for
