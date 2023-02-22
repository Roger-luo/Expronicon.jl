
using MLStyle
using Expronicon.ADT: @adt
using Expronicon.ADT.Tree.Inline
using Expronicon.ADT.Tree

# FCSR: free commutative semiring
@adt public FCSR begin
    struct Add
        dict::Dict{FCSR, Int} = Dict{FCSR, Int}()
    end
    struct Mul
        dict::Dict{FCSR, Int} = Dict{FCSR, Int}()
    end
    struct Literal
        name::Symbol
    end
end
function Base.:(==)(lhs::FCSR, rhs::FCSR)
    @match (lhs, rhs) begin
        (Add(d1), Add(d2)) => d1 == d2
        (Mul(d1), Mul(d2)) => d1 == d2
        (Literal(n1), Literal(n2)) => n1 == n2
        _ => false
    end
end
function Base.hash(f::FCSR, h::UInt)
    @match f begin
        Add(d) => hash(d, h ⊻ hash(:Add))
        Mul(d) => hash(d, h ⊻ hash(:Mul))
        Literal(n) => hash(n, h ⊻ hash(:Literal))
    end
end
function Base.:+(lhs::FCSR, rhs::FCSR)
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
function Base.:*(lhs::FCSR, rhs::FCSR)
    @match (lhs, rhs) begin
        (Mul(d1), Mul(d2)) => Mul(merge(*, d1, d2))
        (Mul(d), _) => begin
            d = copy(d)
            d[rhs] = get(d, rhs, 0) + 1
            Mul(d)
        end
        (_, Mul(d)) => rhs * lhs
        _ => begin
            d = Dict(lhs => 1)
            d[rhs] = get(d, rhs, 0) + 1
            Mul(d)
        end
    end
end

# define inline printer for FCSR
function Inline.children(node::FCSR)
    @match node begin
        Add(d) => d
        Mul(d) => d
        _ => ()
    end
end
function Inline.print_node(io::IO, node::FCSR)
    @match node begin
        Add(d) => return
        Mul(d) => return
        Literal(n) => printstyled(io, n; color = :green)
    end
end
function Inline.print_annotation_suffix(io::IO, node::FCSR, annotation)
    @match node begin
        Mul(d) => begin
            isone(annotation) && return
            print(io, superscriptnumber(annotation))
        end
        _ => return
    end
end
function Inline.print_annotation(io::IO, node::FCSR, annotation)
    @match node begin
        Add(d) => begin
            isone(annotation) && return
            printstyled(io, annotation; color = :light_black)
        end
        _ => return
    end
end
function Inline.delimiter(node::FCSR)
    @match node begin
        Add(d) => return " ⊕ "
        Mul(d) => return " ⊙ "
        _ => return ""
    end
end
function Inline.precedence(node::FCSR)
    @match node begin
        Add(d) => return 1
        Mul(d) => return 2
        _ => return 3
    end
end
function superscriptnumber(i::Int)
    if i < 0
        c = [Char(0x207B)]
    else
        c = []
    end
    for d in reverse(digits(abs(i)))
        if d == 0 push!(c, Char(0x2070)) end
        if d == 1 push!(c, Char(0x00B9)) end
        if d == 2 push!(c, Char(0x00B2)) end
        if d == 3 push!(c, Char(0x00B3)) end
        if d > 3 push!(c, Char(0x2070+d)) end
    end
    return join(c)
end

# define multiline printer for FCSR
function Tree.children(node::FCSR)
    @match node begin
        Add(d) => d
        Mul(d) => d
        _ => ()
    end
end
function Tree.print_node(io::IO, node::FCSR)
    @match node begin
        Add(d) => printstyled(io, "Add"; color = :cyan, bold = true)
        Mul(d) => printstyled(io, "Mul"; color = :cyan, bold = true)
        Literal(n) => begin
            printstyled(io, "Literal("; color = :cyan, bold = true)
            printstyled(io, n; color = :green)
            printstyled(io, ")"; color = :cyan, bold = true)
        end
    end
end
function Tree.print_annotation(io::IO, node::FCSR, annotation)
    @match node begin
        Add(d) || Mul(d) => printstyled(io, annotation; color = :light_black)
        _ => return
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

multiline_printer = Tree.Printer(stdout)
multiline_printer(a)
multiline_printer(b)
multiline_printer(a+b)
multiline_printer(ex)
