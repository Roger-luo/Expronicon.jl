using MLStyle
using Expronicon.Tree
using Expronicon.ADT: @adt

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
            Dict(indices1=>tensor1, indices2=>tensor2)
        Trace(tensor, i1, i2) => Dict([i1, i2]=>tensor,)
        Device(tensor, _) => (tensor,)
    end
end

function print_annotation(io, dims)
    printstyled(io, " <", color=:light_black)
    mapjoin(dims, "×") do x
        printstyled(io, x, color=:light_black)
    end
    printstyled(io, ">", color=:light_black)
end

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
    get(io, :shape, false) && Tree.print_annotation(io, size(node))
    return
end


A = Tensor("A", [2, 3, 2])
R = Reshape(A, [6, 2])
R2 = Reshape(R, [2, 3, 2])
C = Contract(A, R2, [1, 2], [2, 3])
p = Tree.Printer(stdout)
p(C)
