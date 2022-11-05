@test_expr JLStruct mutable struct Mutable
    const x::Int
    y::Int
end

def = @expr JLKwStruct mutable struct MutableKw
    const x::Int = 1
    y::Int = 2
end

@test_expr codegen_ast(def) == quote
    mutable struct MutableKw
        const x::Int
        y::Int
    end
    function MutableKw(; x = 1, y = 2)
        MutableKw(x, y)
    end
    nothing
end
