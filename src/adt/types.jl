# NOTE: let's not support inner constructors
# one should use a custom struct instead of
# defining a constructor for an ADT variant

Base.@kwdef struct Variant
    type::Symbol # singleton, struct, call
    name::Symbol

    # only for struct
    ismutable::Bool = false
    fields::Vector{Symbol} = Symbol[] # maybe empty

    fieldtypes::Vector{Any} = map(_->Any, fields)

    function Variant(type, name, ismutable, fields, fieldtypes)
        if type == :struct
            if length(fields) != length(fieldtypes)
                throw(ArgumentError("length of fields and fieldtypes must be equal"))
            end
        elseif type == :call
            isempty(fieldtypes) && throw(ArgumentError("call type must have at least one fieldtype"))
            isempty(fields) || throw(ArgumentError("cannot have named fields for call syntax variant"))
        end
        new(type, name, ismutable, fields, fieldtypes)
    end
end

Base.@kwdef struct ADTTypeDef
    # head of the type
    m::Module = Main
    name::Symbol
    typevars::Vector{Any} = Any[]
    supertype::Any = nothing

    # enum of the type
    # <name>
    # <call signature>
    # <struct>
    variants::Vector{Variant}
end

function Variant(ex)
    @switch ex begin
        @case ::Symbol
            Variant(type=:singleton, name=ex)
        @case :($name($(args...)))
            foreach(args) do arg
                Meta.isexpr(arg, :(::)) && length(arg.args) == 1 ||
                    throw(ArgumentError("expect ::<type> in call syntax variant, got $arg"))
            end                
            Variant(type=:call, name=name, fieldtypes=annotations_only.(args))
        @case Expr(:struct, _...)
            def = JLStruct(ex)
            Variant(;
                type=:struct,
                name=def.name,
                ismutable=def.ismutable,
                fields=map(x->x.name, def.fields),
                fieldtypes=map(x->x.type, def.fields)
            )
        @case _
            throw(ArgumentError("unknown variant syntax: $ex"))
    end
end

function adt_split_head(head)
    @switch head begin
        @case ::Symbol
            name = head
            typevars = []
            supertype = nothing
        @case :($name{$(typevars...)})
            supertype = nothing
        @case :($name{$(typevars...)} <: $supertype)
        @case :($name <: $supertype)
            typevars = []
        @case _
            throw(ArgumentError("unknown ADT syntax: $head"))
    end
    return name, typevars, supertype
end

function ADTTypeDef(m::Module, head, body::Expr)
    return ADTTypeDef(
        m, adt_split_head(head)...,
        Variant.(filter(x->!(x isa LineNumberNode), body.args)),
    )
end

function Base.:(==)(a::Variant, b::Variant)
    a.type == b.type && a.name == b.name && a.ismutable == b.ismutable &&
        a.fields == b.fields && a.fieldtypes == b.fieldtypes
end
