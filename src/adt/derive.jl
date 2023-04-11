macro derive(ex)
    esc(derive_m(__module__, __source__, ex))
end

function derive_m(mod::Module, line::LineNumberNode, ex::Expr)
    @switch ex begin
        @case :($name:$first)
            others = ()
        @case Expr(:tuple, :($name:$(first)), [e for e in others]...)
        @case _
            error("Invalid expression")
    end

    expr_map((first, others...)) do rule
        msg = "$(rule) is not defined"
        fn = guess_value(mod, rule)
        (fn isa Expr || fn isa Symbol) && return :(error($msg))
        derive_rule(fn, mod, line, name)
    end
end

function derive_rule(rule, m::Module, line::LineNumberNode, Self::Symbol)
    msg = "derive_rule for $(rule) is not defined"
    return :(error($msg))
end

macro derive_rule(jlfn::Expr)
    jlfn = JLFunction(jlfn)
    esc(derive_rule_m(__module__, jlfn))
end

function derive_rule_m(mod::Module, jlfn::JLFunction)
    length(jlfn.args) == 3 || error("Invalid function signature")

    fn_type = @match jlfn.name begin
        Expr(:., path, name::QuoteNode) => begin
            m = guess_module(mod, path)
            isdefined(m, name.value) || error("$(jlfn.name) is not defined")
            typeof(getfield(m, name.value))
        end
        name::Symbol => begin
            isdefined(mod, name) || error("$(jlfn.name) is not defined")
            typeof(getfield(mod, name))
        end
        _ => error("Invalid function name: $(jlfn.name)")
    end

    pushfirst!(jlfn.args, :(::$fn_type))
    jlfn.name = GlobalRef(@__MODULE__, :derive_rule)
    return codegen_ast(jlfn)
end

@derive_rule function Base.hash(m::Module, line::LineNumberNode, Self::Symbol)
    isdefined(m, Self) || error("$(Self) is not defined")
    quote
        function $Base.hash(x::$Self, h::UInt)
            type = $ADT.variant_type(x)
            h = $Base.hash(type, h)
            for idx in $ADT.variant_masks(x)
                h = $Base.hash($Base.getfield(x, idx), h)
            end
            return h
        end
    end
end

@derive_rule function Base.isequal(m::Module, line::LineNumberNode, Self::Symbol)
    isdefined(m, Self) || error("$(Self) is not defined")
    quote
        function $Base.isequal(lhs::$Self, rhs::$Self)
            $ADT.variant_type(lhs) == $ADT.variant_type(rhs) || return false
        
            for idx in $ADT.variant_masks(lhs) # mask is the same for both
                $Base.isequal($Base.getfield(lhs, idx), $Base.getfield(rhs, idx)) || return false
            end
            return true
        end
    end
end

@derive_rule function Base.:(==)(m::Module, line::LineNumberNode, Self::Symbol)
    isdefined(m, Self) || error("$(Self) is not defined")
    quote
        function $Base.:(==)(lhs::$Self, rhs::$Self)
            Base.:(==)($ADT.variant_type(lhs), $ADT.variant_type(rhs)) || return false

            for idx in $ADT.variant_masks(lhs) # mask is the same for both
                Base.:(==)($Base.getfield(lhs, idx), $Base.getfield(rhs, idx)) || return false
            end
            return true
        end
    end
end
