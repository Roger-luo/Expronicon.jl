"""
    guess_module(m, ex)

Guess the module of given expression `ex` (of a module)
in module `m`. If `ex` is not a module, or cannot be
determined return `nothing`.
"""
function guess_module(m::Module, ex)
    @switch ex begin
        @case ::Module
            return ex
        @case ::Symbol && if isdefined(m, ex) end
            maybe_m = getproperty(m, ex)
            maybe_m isa Module && return maybe_m
            return ex
        @case :($name.$sub)
            mod = guess_module(m, name)
            if mod isa Module
                return guess_module(mod, sub)
            else
                return ex
            end
        @case _
            return ex
    end
end

"""
    guess_type(m::Module, ex)

Guess the actual type of expression `ex` (of a type) in module `m`.
Returns the type if it can be determined, otherwise returns the
expression. This function is used in [`compare_expr`](@ref).
"""
function guess_type(m::Module, ex)
    @switch ex begin
        @case ::Type || ::QuoteNode
            return ex
        @case ::Symbol
            isdefined(m, ex) || return ex
            return getproperty(m, ex)
        @case :($name{$(typevars...)})
            type = guess_type(m, name)
            typevars = map(typevars) do typevar
                guess_type(m, typevar)
            end

            if type === Union
                all(x->isa(x,Type), typevars) || return ex
                return Union{typevars...}
            elseif type isa Type && all(is_valid_typevar, typevars)
                return type{typevars...}
            else
                return ex
            end
        @case _
            return ex
    end
end
