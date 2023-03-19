macro derive(ex)
    esc(derive_m(__module__, __source__, ex))
end

function derive_m(mod::Module, line::LineNumberNode, ex::Expr)
    @switch ex begin
        @case Expr(:tuple, :($name:$(first::Symbol)), [e::Symbol for e in others]...)
        @case _
            error("Invalid expression")
    end

    expr_map((first, others...)) do rule
        derive_rule(Rule(rule), mod, line, name)
    end
end

struct Rule{name} end
Rule(name::Symbol) = Rule{name}()

function derive_rule(::Rule{name}, m::Module, line::LineNumberNode, Self::Symbol) where name
    error("derive_rule for $(name) is not defined")
end

macro derive_rule(jlfn::Expr)
    jlfn = JLFunction(jlfn)
    esc(derive_rule_m(jlfn))
end

function derive_rule_m(jlfn::JLFunction)
    length(jlfn.args) == 3 || error("Invalid function signature")
    pushfirst!(jlfn.args, :(::Rule{$(QuoteNode(jlfn.name))}))
    jlfn.name = GlobalRef(@__MODULE__, :derive_rule)
    return codegen_ast(jlfn)
end

@derive_rule function hash(m::Module, line::LineNumberNode, Self::Symbol)
    isdefined(m, Self) || error("$(Self) is not defined")
    quote
        function $Base.hash(x::$Self, h::UInt)
            type = $ADT.variant_type(x)
            h = hash(type, h)
            for idx in $ADT.variant_masks(x)
                h = hash($Base.getfield(x, idx), h)
            end
            return h
        end
    end
end

@derive_rule function isequal(m::Module, line::LineNumberNode, Self::Symbol)
    isdefined(m, Self) || error("$(Self) is not defined")
    quote
        function $Base.isequal(lhs::$Self, rhs::$Self)
            $ADT.variant_type(lhs) == $ADT.variant_type(rhs) || return false
        
            for idx in $ADT.variant_masks(lhs) # mask is the same for both
                isequal($Base.getfield(lhs, idx), $Base.getfield(rhs, idx)) || return false
            end
            return true
        end
    end
end

@derive_rule function ==(m::Module, line::LineNumberNode, Self::Symbol)
    isdefined(m, Self) || error("$(Self) is not defined")
    quote
        function $Base.:(==)(lhs::$Self, rhs::$Self)
            $ADT.variant_type(lhs) == $ADT.variant_type(rhs) || return false
        
            for idx in $ADT.variant_masks(lhs) # mask is the same for both
                $Base.getfield(lhs, idx) == $Base.getfield(rhs, idx) || return false
            end
            return true
        end
    end
end
