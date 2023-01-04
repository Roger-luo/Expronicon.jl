struct EmptyLine end
const empty_line = EmptyLine()
Base.show(io::IO, ::EmptyLine) = print(io, "<empty line>")

"""
    struct Variable

Marks a `Symbol` as a variable. So that [`compare_expr`](@ref)
will always return `true`.
"""
struct Variable
    name::Symbol
end
Base.show(io::IO, x::Variable) = printstyled(io, "<", x.name, ">"; color=:light_blue)

# must be called after `compare_expr` return false
function locate_inequal_expr(m::Module, lhs, rhs)
    lhs isa Expr && rhs isa Expr || return lhs, rhs

    # always make sure the lhs is the one has less args
    if length(lhs.args) > length(rhs.args)
        lhs, rhs = rhs, lhs
    end

    not_equals = Tuple{Any, Any}[]
    for (l, r) in zip(lhs.args, rhs.args)
        if !compare_expr(m, l, r)
            push!(not_equals, (l, r))
        end
    end

    # rest are all not equal
    for each in rhs.args[length(lhs.args)+1:end]
        push!(not_equals, (empty_line, each))
    end

    # all args are not equal
    # cannot narrow down the location
    if length(not_equals) == length(rhs.args)
        return lhs, rhs
    else # only some args are equal, narrow down the first one
        return locate_inequal_expr(m, first(not_equals)...)
    end
end

"""
    assert_equal_expr(m::Module, lhs, rhs)

Assert that `lhs` and `rhs` are equal in `m`.
Throw an `ExprNotEqual` if they are not equal.
"""
function assert_equal_expr(m::Module, lhs, rhs)
    lhs = prettify(lhs; preserve_last_nothing=true, alias_gensym=false)
    rhs = prettify(rhs; preserve_last_nothing=true, alias_gensym=false)
    lhs = renumber_gensym(lhs)
    rhs = renumber_gensym(rhs)
    compare_expr(m, lhs, rhs) && return true
    lhs, rhs = locate_inequal_expr(m, lhs, rhs)
    throw(ExprNotEqual(lhs, rhs))
end

"""
    @test_expr <type> <ex>

Test if the syntax type generates the same expression `ex`. Returns the
corresponding syntax type instance. Requires `using Test` before using
this macro.

# Example

```julia
def = @test_expr JLFunction function (x, y)
    return 2
end
@test is_kw_fn(def) == false
```
"""
macro test_expr(type, ex)
    @gensym def generated_expr original_expr
    quote
        $def = Expronicon.@expr $type $ex
        $Base.show(stdout, MIME"text/plain"(), $def)
        $generated_expr = $codegen_ast($def)
        $original_expr = $(Expr(:quote, ex))
        @test $(Expr(
            :block, __source__,
            :($assert_equal_expr($__module__, $generated_expr, $original_expr))
        ))
        $def
    end |> esc
end

"""
    @test_expr <expr> == <expr>

Test if two expression is equivalent semantically, this uses `compare_expr`
to decide if they are equivalent, ignores things such as `LineNumberNode`
generated `Symbol` in `Expr(:curly, ...)` or `Expr(:where, ...)`.

!!! note

    This macro requires one `using Test` to import the `Test` module
    name.
"""
macro test_expr(ex::Expr)
    esc(test_expr_m(__module__, __source__, ex))
end

function test_expr_m(__module__, __source__, ex::Expr)
    ex.head === :call && ex.args[1] === :(==) || error("expect <expr> == <expr>, got $ex")
    lhs, rhs = ex.args[2], ex.args[3]
    @gensym result cmp_result err
    return quote
        $result = try
            $cmp_result = $assert_equal_expr($__module__, $lhs, $rhs)
            Test.Returned($cmp_result, nothing, $(QuoteNode(__source__)))
        catch $err
            $err isa Test.InterruptException && Test.rethrow()
            Test.Threw($err, $Base.current_exceptions(), $(QuoteNode(__source__)))
        end
        Test.do_test($result, $(QuoteNode(ex)))
    end
end

# function Base.:(==)(lhs::JLKwField, rhs::JLKwField)
#     lhs.name === rhs.name || return false
#     compare_expr(lhs.type, rhs.type) || return false
#     return compare_expr(lhs.default, rhs.default)
# end

macro compare_expr(lhs, rhs)
    return quote
        $Expronicon.compare_expr($__module__, $lhs, $rhs)
    end |> esc
end

"""
    compare_expr([m=Main], lhs, rhs)

Compare two expression of type `Expr` or `Symbol` semantically, which:

1. ignore the detail value `LineNumberNode` in comparision;
2. ignore the detailed name of typevars declared by `where`;
3. recognize inserted objects and `Symbol`, e.g `:(\$Int)` is equal to `:(Int)`;
4. recognize `QuoteNode(:x)` and `Symbol("x")` as equal;
5. will guess module and type objects and compare their value directly
    instead of their expression;

!!! tips

    This function is usually combined with [`prettify`](@ref)
    with `preserve_last_nothing=true` and `alias_gensym=false`.

This gives a way to compare two Julia expression semantically which means
although some details of the expression is different but they should
produce the same lowered code.
"""
compare_expr(lhs, rhs) = compare_expr(Main, lhs, rhs)

function compare_expr(m::Module, lhs, rhs)
    @switch (lhs, rhs) begin
        @case (::Variable, ::Variable) || (::LineNumberNode, ::LineNumberNode)
            return true
        @case (::Symbol, ::Symbol) || (::Module, ::Module) ||
            (::GlobalRef, ::GlobalRef) # literals
            return lhs === rhs
        @case (::TypeVar, ::TypeVar)
            # typevars at the same position should ignore name
            compare_expr(m, lhs.lb, rhs.lb) || return false
            compare_expr(m, lhs.ub, rhs.ub) || return false
            return true
        @case (a::QuoteNode, :(Symbol($b))) || (:(Symbol($b)), a::QuoteNode)
            # Symbol is not imported, e.g baremodule
            isdefined(m, :Symbol) || return false
            return a.value === Symbol(b)
        @case (::Expr, ::Expr)
            return compare_expr_object(m, lhs, rhs)
        @case (Expr(:curly, _...), ::Type)
            return guess_type(m, lhs) == rhs
        @case (::Type, Expr(:curly, _...))
            return lhs == guess_type(m, rhs)


        # partially known value
        @case (a, b::Symbol) || (b::Symbol, a) # constants
            isdefined(m, b) || return false
            return getfield(m, b) === a
        # one of them has value
        @case (a, b::Expr) || (b::Expr, a)
            try
                return a == Base.eval(m, b)
            catch _
                return false
            end

        @case (a::Module, b) || (b, a::Module)
            mod = guess_module(m, b)
            isnothing(mod) && return false
            return a === mod
        @case _ # fallback to ==
            return lhs == rhs
    end
end

function compare_expr_object(m::Module, lhs::Expr, rhs::Expr)
    @switch (lhs, rhs) begin
        @case (:(::$tx), :(::$ty)) # type annotation
            tx = guess_type(m, tx)
            ty = guess_type(m, ty)
            return compare_expr(m, tx, ty)
        @case (:($x::$tx), :($y::$ty)) # type annotation
            tx = guess_type(m, tx)
            ty = guess_type(m, ty)
            return compare_expr(m, x, y) && compare_expr(m, tx, ty)
        @case (:($mod_a.$sub_a), :($mod_b.$sub_b))
            mod_a = guess_module(m, mod_a)
            mod_b = guess_module(m, mod_b)
            compare_expr(m, mod_a, mod_b) || return false
            return compare_expr(m, sub_a, sub_b)
        @case (Expr(:where, _...), Expr(:where, _...))
            return compare_where(m, lhs, rhs)
        @case (Expr(:curly, _...), Expr(:curly, _...))
            return compare_curly(m, lhs, rhs)
        @case (Expr(:function, _...), Expr(:function, _...))
            return compare_function(m, lhs, rhs)

        @case (::Expr, ::Expr)
            lhs.head === rhs.head || return false
            length(lhs.args) == length(rhs.args) || return false
            for (a, b) in zip(lhs.args, rhs.args)
                compare_expr(m, a, b) || return false
            end
            return true

        @case _ # well none of the cases above, fallback to ==
            return lhs == rhs
    end
end

function compare_function(m::Module, lhs::Expr, rhs::Expr)
    lhs,rhs = canonicalize_lambda_head(lhs), canonicalize_lambda_head(rhs)
    @show lhs
    compare_expr(m, lhs.args[1], rhs.args[1]) || return false
    length(lhs.args) == length(rhs.args) == 1 && return true

    function is_all_lineno(ex)
        Meta.isexpr(ex, :block) || return false
        return all(x->x isa LineNumberNode, ex.args)
    end

    if length(lhs.args) == 1
        is_all_lineno(rhs.args[2]) && return true
    elseif length(rhs.args) == 1
        is_all_lineno(lhs.args[2]) && return true
    end
    return compare_expr(m, lhs.args[2], rhs.args[2])
end

function compare_curly(m::Module, lhs::Expr, rhs::Expr)
    # this should be a type, let's guess what it is
    type_a = guess_type(m, lhs)
    type_b = guess_type(m, rhs)
    name_a, name_b = lhs.args[1], rhs.args[1]
    typevars_a, typevars_b = lhs.args[2:end], rhs.args[2:end]


    # one of them isa type
    if type_a isa Type || type_b isa Type
        return type_a === type_b
    else
        compare_expr(m, guess_type(m, name_a), guess_type(m, name_b)) || return false
        length(typevars_a) == length(typevars_b) || return false
        return all(zip(typevars_a, typevars_b)) do (a, b)
            compare_expr(m, guess_type(m, a), guess_type(m, b))
        end
    end
end

function compare_where(m::Module, lhs::Expr, rhs::Expr)
    lbody, lparams = lhs.args[1], lhs.args[2:end]
    rbody, rparams = rhs.args[1], rhs.args[2:end]

    lbody = mark_typevars(lbody, name_only.(lparams))
    rbody = mark_typevars(rbody, name_only.(rparams))

    compare_expr(m, lbody, rbody) || return false
    return all(zip(lparams, rparams)) do (l, r)
        l isa Symbol && r isa Symbol && return true
        Meta.isexpr(l, :(<:)) && Meta.isexpr(r, :(<:)) || return false
        @show l, r
        @show compare_expr(m, l.args[2], r.args[2])
        return compare_expr(m, l.args[2], r.args[2])
    end
end

function mark_typevars(expr, typevars::Vector{Symbol})
    sub = Substitute() do expr
        expr isa Symbol && expr in typevars && return true
        return false
    end
    return sub(Variable, expr)
end
