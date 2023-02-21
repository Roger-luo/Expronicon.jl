include("utils.jl")
include("colors.jl")
include("inline.jl")
include("multi.jl")

Base.show(io::IO, def::JLExpr) = print_inline(io, def)
Base.show(io::IO, ::MIME"text/plain", def::JLExpr) = print_expr(io, def)

function (p::Printer)(def::JLExpr)
    p(codegen_ast(def))
end

function (p::InlinePrinter)(def::JLExpr)
    p(codegen_ast(def))
end

"""
    sprint_expr(ex; context=nothing, kw...)

Print given expression to `String`, see also [`print_expr`](@ref).
"""
function sprint_expr(ex; context=nothing, kw...)
    buf = IOBuffer()
    if context === nothing
        print_expr(buf, ex; kw...)
    else
        print_expr(IOContext(buf, context), ex; kw...)
    end
    return String(take!(buf))
end
