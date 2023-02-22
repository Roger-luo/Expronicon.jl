module TestMultiline

using MLStyle
using Expronicon.ADT: @adt
using Expronicon.ADT.Tree.Multiline

@adt public DeviceKind begin
    CPU
    GPU(::Int)
end

function Base.:(==)(lhs::DeviceKind, rhs::DeviceKind)
    @match (lhs, rhs) begin
        (CPU, CPU) => true
        (GPU(n1), GPU(n2)) => n1 == n2
        _ => false
    end
end

function Base.hash(d::DeviceKind, h::UInt)
    @match d begin
        CPU => hash(:CPU, h)
        GPU(n) => hash((:GPU, n), h)
    end
end

@adt public Size begin
    ConstSize(::Int)
    VarSize(::String)
end

function Base.:(==)(lhs::Size, rhs::Size)
    @match (lhs, rhs) begin
        (ConstSize(n1), ConstSize(n2)) => n1 == n2
        (VarSize(s1), VarSize(s2)) => s1 == s2
        _ => false
    end
end

function Base.hash(s::Size, h::UInt)
    @match s begin
        ConstSize(n) => hash((:ConstSize, n), h)
        VarSize(s) => hash((:VarSize, s), h)
    end
end

macro size_str(s::String)
    return esc(:(VarSize($(s))))
end

Base.convert(::Type{Size}, s::String) = VarSize(s)
Base.convert(::Type{Size}, s::Int) = ConstSize(s)

@adt public Tensura begin
    struct Tensor
        name::String
        dims::Vector{Size}
    end

    struct Reshape
        tensor::Tensura
        dims::Vector{Size}
    end

    struct PermuteDims
        tensor::Tensura
        perm::Vector{Int}
    end

    struct Conjugate
        tensor::Tensura
    end

    struct Contract
        tensor1::Tensura
        tensor2::Tensura
        indices1::Vector{Int}
        indices2::Vector{Int}
    end

    struct Trace
        tensor::Tensura
        indices1::Vector{Int}
        indices2::Vector{Int}
    end

    struct Decompose
        tensor::Tensura
        indices::Vector{Int}
    end

    struct Device
        tensor::Tensura
        device::DeviceKind
    end
end

function Multiline.children(t::Tensura)
    @match t begin
        Tensor(_, _) => ()
        Reshape(tensor, _) => (tensor,)
        PermuteDims(tensor, _) => (tensor,)
        Conjugate(tensor) => (tensor,)
        Contract(tensor1, tensor2, indices1, indices2) =>
            Dict(tensor1 => indices1, tensor2 => indices2)
        Trace(tensor, i1, i2) => Dict(tensor => [i1, i2])
        Device(tensor, _) => (tensor,)
    end
end

Multiline.print_child_annotation(io::IO, node::Tensura, child::Tensura, key) = printstyled(io, key; color = :red, bold=true)

function Multiline.print_node(io::IO, node::Tensura)
    @match node begin
        Tensor(name, _) => print(io, name)
        Reshape(_...) => printstyled(io, "reshape", color=:cyan, bold=true)
        PermuteDims(_, perm) => printstyled(io, "permute ", perm, color=:cyan, bold=true)
        Conjugate(_) => printstyled(io, "conj", color=:cyan, bold=true)
        Contract(_...) => printstyled(io, "contract", color=:cyan, bold=true)
        Trace(_...) => printstyled(io, "trace", color=:cyan, bold=true)
        Device(_, device) => printstyled(io, "device ", device, color=:cyan, bold=true)
    end
    return
end

A = Tensor("A", [2, 3, 2])
R = Reshape(A, [6, 2])
R2 = Reshape(R, [2, 3, 2])
C = Contract(A, R2, [1, 2], [2, 3])
p = Multiline.Printer(stdout)
p(C)
p(R)

end # module TestMultiline

module TestFreeCommutativeSemiring

using MLStyle
using Expronicon.ADT: @adt
using Expronicon.ADT.Tree.Inline
using Expronicon.ADT.Tree.Multiline

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
function Inline.print_child_annotation_suffix(io::IO, node::FCSR, child::FCSR, annotation)
    @match (node, child) begin
        (Mul(d), _) => begin
            annotation == 1 && return
            print(io, superscriptnumber(annotation))
        end
        _ => return
    end
end
function Inline.print_child_annotation(io::IO, node::FCSR, child::FCSR, annotation)
    @match (node, child) begin
        (Add(d), _) => begin
            annotation == 1 && return
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
function Multiline.children(node::FCSR)
    @match node begin
        Add(d) => d
        Mul(d) => d
        _ => ()
    end
end
function Multiline.print_node(io::IO, node::FCSR)
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
function Multiline.print_child_annotation(io::IO, node::FCSR, child::FCSR, annotation)
    @match (node, child) begin
        (Add(d), _) || (Mul(d), _) => printstyled(io, annotation; color = :light_black)
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

multiline_printer = Multiline.Printer(stdout)
multiline_printer(a)
multiline_printer(b)
multiline_printer(a+b)
multiline_printer(ex)

end # module TestFreeCommutativeSemiring