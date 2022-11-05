# Copied from ManualMemory

mutable struct Reference{T}
    data::T
    Reference{T}() where {T} = new{T}()
    Reference(x) = new{typeof(x)}(x)
end

@inline Base.pointer(r::Reference{T}) where {T} = Ptr{T}(pointer_from_objref(r))
@inline load(p::Ptr{Reference{T}}) where {T} = getfield(ccall(:jl_value_ptr, Ref{Reference{T}}, (Ptr{Cvoid},), unsafe_load(Base.unsafe_convert(Ptr{Ptr{Cvoid}}, p))), :data)

function undef_value(type)
    if type isa Type && type <: Number
        return type(0)
    elseif isbitstype(type)
        return load(pointer(Reference{T}()))
    else
        # non-bitstype is always Any
        # so we can set it to nothing
        return nothing
    end
end
