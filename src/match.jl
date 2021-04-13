"""
    JLMatch <: JLExpr

`JLMatch` describes a Julia pattern match expression defined by
[`MLStyle`](https://github.com/thautwarm/MLStyle.jl). It allows
one to construct such expression by simply assign each code block
to the corresponding pattern expression.

# Example

One can construct a `MLStyle` pattern matching expression
easily by assigning the corresponding pattern and its result
to the `map` field.

```julia
julia> jl = JLMatch(:x)
#= line 0 =#
nothing

julia> jl = JLMatch(:x)
#= line 0 =#
nothing

julia> jl.map[1] = true
true

julia> jl.map[2] = :(sin(x))
:(sin(x))

julia> jl
#= line 0 =#
@match x begin
    1 => true
    2 => sin(x)
    _ =>     nothing
end
```

to generate the corresponding Julia `Expr` object, one can call [`codegen_ast`](@ref).

```julia
julia> codegen_ast(jl)
:(let
      true
      var"##return#263" = nothing
      var"##265" = x
      if var"##265" isa Int64
          #= line 0 =#
          if var"##265" === 1
              var"##return#263" = let
                      true
                  end
              #= unused:1 =# @goto var"####final#264#266"
          end
          #= line 0 =#
          if var"##265" === 2
              var"##return#263" = let
                      sin(x)
                  end
              #= unused:1 =# @goto var"####final#264#266"
          end
      end
      #= line 0 =#
      begin
          var"##return#263" = let
                  nothing
              end
          #= unused:1 =# @goto var"####final#264#266"
      end
      (error)("matching non-exhaustive, at #= line 0 =#")
      #= unused:1 =# @label var"####final#264#266"
      var"##return#263"
  end)
```
"""
struct JLMatch <: JLExpr
    item::Any
    patterns::Vector{Any}
    actions::Vector{Any}
    fallthrough::Any
    mod::Module
    line::LineNumberNode
end

"""
    JLMatch(item)

Generate an empty `JLMatch` object with given item expression.
`item` can be a `Symbol` or an `Expr`.
"""
JLMatch(item) = JLMatch(item, [], [], nothing, Main, LineNumberNode(0))

"""
    JLMatch(;kw...)

Create a `JLMatch` object from keyword arguments.

# Kwargs

- `item`: item to match
- `map`: the pattern=>result map, should be an `OrderedDict`.
- `fallthrough`: the result of fallthrough pattern `_`.
- `mod`: module to evaluate the expression.
- `line`: line number `LineNumberNode`.
"""
JLMatch(;item, patterns=[], actions=[], fallthrough=nothing, mod=Main, line=LineNumberNode(0)) =
    JLMatch(item, patterns, actions, fallthrough, mod, line)

Base.length(jl::JLMatch) = length(jl.patterns)

function Base.getindex(jl::JLMatch, pattern)
    idx = findfirst(jl.patterns) do p
        compare_expr(p, pattern)
    end
    idx === nothing && error("cannot find pattern: $pattern")
    return jl.actions[idx]
end

function Base.setindex!(jl::JLMatch, action, pattern)
    idx = findfirst(jl.patterns) do p
        compare_expr(p, pattern)
    end

    if idx === nothing
        push!(jl.patterns, pattern)
        push!(jl.actions, action)
    else
        jl.actions[idx] = action
    end
    return action
end

function Base.iterate(jl::JLMatch, st=1)
    st > length(jl) && return
    return jl.patterns[st] => jl.actions[st], st + 1
end

function codegen_ast(def::JLMatch)
    isempty(def.patterns) && return def.fallthrough
    body = Expr(:block)
    for (pattern, code) in def
        push!(body.args, :($pattern => $code))
    end
    push!(body.args, :(_ => $(def.fallthrough)))
    return init_cfg(gen_match(def.item, body, def.line, def.mod))
end


function print_expr(io::IO, def::JLMatch, ps::PrintState, theme::Color)
    print_expr(io, def.line, ps, theme)
    println(io)
    isempty(def.patterns) && return print_expr(io, def.fallthrough, ps, theme)

    within_line(io, ps) do
        print_kw(io, "@match ", ps, theme)
        print_expr(io, def.item, ps, theme)
        print_kw(io, " begin ", ps, theme)
    end
    println(io, ps)
    within_indent(ps) do
        for (k, (pattern, action)) in enumerate(def)
            within_line(io, ps) do
                print_expr(io, pattern, ps, theme)
                print_kw(io, " => ", ps, theme)
                print_expr(io, action, ps, theme)
            end
            println(io, ps)
        end
        within_line(io, ps) do
            print(io, "_")
            print_kw(io, " => ", ps, theme)
            print_expr(io, def.fallthrough, ps, theme)
        end
    end
    println(io, ps)
    print_end(io, ps, theme)
end



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

using ExproniconLite: is_struct_not_kw_struct

@syntax_pattern JLFunction  is_function
@syntax_pattern JLStruct    is_struct_not_kw_struct
@syntax_pattern JLKwStruct  is_struct
@syntax_pattern JLIfElse    is_ifelse
@syntax_pattern JLFor       is_for
