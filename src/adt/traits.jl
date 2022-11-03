abstract type EnumType end

"""
    variant_types(::Type{T}) where T

Returns the variant of an algebra data type `T`.
"""
function variant(::Type{T}) where T
    throw(ArgumentError("expect an adt type, got $T"))
end

function variant_type(x)
    throw(ArgumentError("expect an adt type, got $x"))
end

function variant_masks(variant)
    throw(ArgumentError("expect an adt type, got $(typeof(variant))"))
end

function variant_fieldnames(variant)
    throw(ArgumentError("expect an adt type, got $(typeof(variant))"))
end

function variant_fieldname(variant, ::Int)
    throw(ArgumentError("expect an adt type, got $(typeof(variant))"))
end
