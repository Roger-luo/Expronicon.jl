using MLStyle
using Expronicon.ADT: @adt
using Expronicon.ADT.Tree

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

function Tree.children(t::Tensura)
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

Tree.print_annotation(io::IO, node::Tensura, annotation) = printstyled(io, annotation; color = :red, bold=true)

function Tree.print_node(io::IO, node::Tensura)
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
p = Tree.Printer(stdout)
p(C)
p(R)

@test_throws "unimplemented children method for Vector{Int64}" Tree.children(Int64[1, 2, 3])
@test_throws "unimplemented print_node method for Vector{Int64}" Tree.print_node(stdout, Int64[1, 2, 3])
@test Tree.should_print_annotation(Int64[1, 2, 3]) == false
@test Tree.should_print_annotation(x for x in 1:3) == false