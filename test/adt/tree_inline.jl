
using MLStyle
using Expronicon.ADT: @adt
using Expronicon.ADT.Tree.Inline
using Expronicon.ADT.Tree

# FSR: free semiring
@adt public FSR begin
    struct Add
        dict::Dict{FSR, Int} = Dict{FSR, Int}()
    end
    struct Mul
        args::Vector{FSR} = Vector{FSR}
    end
    struct Literal
        name::Symbol
    end
end
function Base.:(==)(lhs::FSR, rhs::FSR)
    @match (lhs, rhs) begin
        (Add(d1), Add(d2)) => d1 == d2
        (Mul(d1), Mul(d2)) => d1 == d2
        (Literal(n1), Literal(n2)) => n1 == n2
        _ => false
    end
end
function Base.hash(f::FSR, h::UInt)
    @match f begin
        Add(d) => hash(d, h ⊻ hash(:Add))
        Mul(args) => hash(args, h ⊻ hash(:Mul))
        Literal(n) => hash(n, h ⊻ hash(:Literal))
    end
end
function Base.:+(lhs::FSR, rhs::FSR)
    @match (lhs, rhs) begin
        (Add(d1), Add(d2)) => Add(merge(+, d1, d2))
        (Add(d), _) => begin
            d = copy(d)
            d[rhs] = get(d, rhs, 0) + 1
            Add(d)
        end
        (_, Add(d)) => rhs + lhs
        _ => begin
            d = Dict(lhs => 1)
            d[rhs] = get(d, rhs, 0) + 1
            Add(d)
        end
    end
end
function Base.:*(lhs::FSR, rhs::FSR)
    @match (lhs, rhs) begin
        (Mul(a1), Mul(a2)) => Mul(vcat(a1, a2))
        (Mul(a), _) => begin
            a = copy(a)
            push!(a, rhs)
            Mul(a)
        end
        (_, Mul(a)) => begin
            a = copy(a)
            pushfirst!(a, lhs)
            Mul(a)
        end
        _ => Mul([lhs, rhs])
    end
end

# define inline printer for FSR
function Inline.children(node::FSR)
    @match node begin
        Add(d) => d
        Mul(a) => a
        _ => ()
    end
end
function Inline.print_node(io::IO, node::FSR)
    @match node begin
        Add(d) => return
        Mul(d) => return
        Literal(n) => printstyled(io, n; color = :green)
    end
end
function Inline.print_annotation(io::IO, node::FSR, annotation)
    @match node begin
        Add(d) => begin
            isone(annotation) && return
            printstyled(io, annotation; color = :light_black)
        end
        _ => return
    end
end
function Inline.delimiter(node::FSR)
    @match node begin
        Add(d) => return " ⊕ "
        Mul(d) => return " ⊙ "
        _ => return ""
    end
end
function Inline.precedence(node::FSR)
    @match node begin
        Add(d) => return 1
        Mul(d) => return 2
        _ => return 3
    end
end

# define multiline printer for FSR
function Tree.children(node::FSR)
    @match node begin
        Add(d) => d
        Mul(a) => a
        _ => ()
    end
end
function Tree.print_node(io::IO, node::FSR)
    @match node begin
        Add(d) => printstyled(io, "Add"; color = :cyan, bold = true)
        Mul(a) => printstyled(io, "Mul"; color = :cyan, bold = true)
        Literal(n) => begin
            printstyled(io, "Literal("; color = :cyan, bold = true)
            printstyled(io, n; color = :green)
            printstyled(io, ")"; color = :cyan, bold = true)
        end
    end
end

x, y, z = map(Literal, [:x, :y, :z])
a = x + y
b = x + z
ex = a * a * b + a * b * b

inline_printer = Inline.Printer(stdout)
inline_printer(a)
inline_printer(b)
inline_printer(a+b)
inline_printer(ex)
ex_deep = x * (y + x * (y + x * (y + x * (y + x * (y + x))))) 
inline_printer(ex_deep)

multiline_printer = Tree.Printer(stdout)
multiline_printer(a)
multiline_printer(b)
multiline_printer(a+b)
multiline_printer(ex)
multiline_printer(ex_deep)

@test_throws "unimplemented children method for Vector{Int64}" Inline.children([1, 2, 3])
@test_throws "unimplemented print_node method for Vector{Int64}" Inline.print_node(stdout, [1, 2, 3])
@test_throws "unimplemented print_annotation method for (Vector{Int64}, Symbol)" Inline.print_annotation(stdout, [1, 2, 3], :x)
@test isnothing(Inline.print_annotation_suffix(stdout, [1, 2, 3], :x))
@test Inline.precedence([1, 2, 3]) == 1
@test Inline.delimiter([1, 2, 3]) == ", "
@test Inline.should_print_annotation([1, 2, 3]) == false
@test Inline.should_print_annotation(x for x in 1:3) == false
