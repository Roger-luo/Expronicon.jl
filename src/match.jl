"""
$TYPEDEF

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
    map::OrderedDict{Any, Any}
    fallthrough::Any
    mod::Module
    line::LineNumberNode
end

"""
$SIGNATURES

Generate an empty `JLMatch` object with given item expression.
`item` can be a `Symbol` or an `Expr`.
"""
JLMatch(item) = JLMatch(item, OrderedDict(), nothing, Main, LineNumberNode(0))

"""
$SIGNATURES

Create a `JLMatch` object from keyword arguments.

# Kwargs

- `item`: item to match
- `map`: the pattern=>result map, should be an `OrderedDict`.
- `fallthrough`: the result of fallthrough pattern `_`.
- `mod`: module to evaluate the expression.
- `line`: line number `LineNumberNode`.
"""
JLMatch(;item, map=OrderedDict(), fallthrough=nothing, mod=Main, line=LineNumberNode(0)) =
    JLMatch(item, map, fallthrough, mod, line)


function codegen_ast(def::JLMatch)
    isempty(def.map) && return def.fallthrough
    body = Expr(:block)
    for (pattern, code) in def.map
        push!(body.args, :($pattern => $code))
    end
    push!(body.args, :(_ => $(def.fallthrough)))
    return init_cfg(gen_match(def.item, body, def.line, def.mod))
end


function print_ast(io::IO, def::JLMatch)
    print_ast(io, def.line)
    println(io)
    isempty(def.map) && return print_ast(io, def.fallthrough)
    tab = get(io, :tab, " ")
    indent_println(io, Color.kw("@match"), tab, def.item, tab, Color.kw("begin"))
    within_indent(io) do io
        for (k, (pattern, action)) in enumerate(def.map)
            within_line(io) do io
                print_ast(io, pattern)
                print(io, tab, Color.kw("=>"), tab)
                print_ast(io, action)
            end
            println(io)
        end

        # match must have fallthrough
        indent_print(io, "_")
        print(io, tab, Color.kw("=>"), tab)
        print_ast(io, def.fallthrough)
    end
    println(io)
    indent_print(io, Color.kw("end"))
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

@syntax_pattern JLFunction  is_function
@syntax_pattern JLStruct    is_struct_not_kw_struct
@syntax_pattern JLKwStruct  is_struct
@syntax_pattern JLIfElse    is_ifelse
@syntax_pattern JLFor       is_for
