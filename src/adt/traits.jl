"""
    variants(::Type{T}) where T

Returns the variant types of an algebra data type `T`.
"""
function variants(::Type{T}) where T
    throw(ArgumentError("expect an adt type, got $T"))
end

"""
    variant_type(variant)

Returns the variant type of an algebra data type instance `variant`.
"""
function variant_type(variant)
    throw(ArgumentError("expect an instance of an ADT type, got $variant"))
end

"""
    adt_type(variant_type)

Returns the algebra data type type of a variant type `variant_type`.
"""
function adt_type(variant_type)
    throw(ArgumentError("expect a variant type, got $variant_type"))
end

"""
    variant_masks(variant_type)

Returns the masks of a variant type.
"""
function variant_masks(variant_type)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end

"""
    variant_fieldnames(variant_type)

Returns the field names of a variant type.
"""
function variant_fieldnames(variant_type)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end

"""
    variant_fieldname(variant_type, idx)

Returns the `idx`-th field name of a variant type.
"""
function variant_fieldname(variant_type, ::Int)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end

"""
    variant_fieldtypes(variant_type)

Returns the field types of a variant type.
"""
function variant_fieldtypes(variant_type)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end

"""
    variant_fieldtype(variant_type, idx)

Returns the `idx`-th field type of a variant type.
"""
function variant_fieldtype(variant_type, ::Int)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end

"""
    variant_field_defaults(variant_type)

Returns the field defaults of a variant type.
"""
function variant_field_defaults(variant_type)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end

"""
    variant_field_default(variant_type, idx)

Returns the `idx`-th field default of a variant type.
"""
function variant_field_default(variant_type, ::Int)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end

function variant_typename(variant_type)
    throw(ArgumentError("expect a variant type, got $(typeof(variant_type))"))
end
