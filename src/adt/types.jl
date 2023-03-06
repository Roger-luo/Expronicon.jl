# NOTE: let's not support inner constructors
# one should use a custom struct instead of
# defining a constructor for an ADT variant

Base.@kwdef struct Variant
    type::Symbol # singleton, struct, call
    name::Symbol
    # export the variant to parent namespace
    public::Bool = false

    # only for struct
    ismutable::Bool = false
    fieldnames::Vector{Symbol} = Symbol[] # maybe empty
    field_defaults::Vector{Any} = map(_->no_default, fieldnames)

    fieldtypes::Vector{Any} = map(_->Any, fieldnames)

    lineinfo::Maybe{LineNumberNode} = nothing

    function Variant(type, name, public, ismutable, fieldnames, field_defaults, fieldtypes, lineinfo)
        if type == :struct
            if length(fieldnames) != length(fieldtypes)
                throw(ArgumentError("length of fieldnames and fieldtypes must be equal"))
            end

            if length(fieldnames) != length(field_defaults)
                throw(ArgumentError("length of fieldnames and field_defaults must be equal"))
            end
        elseif type == :call
            isempty(fieldtypes) && throw(ArgumentError("call type must have at least one fieldtype"))
            isempty(fieldnames) || throw(ArgumentError("cannot have named field for call syntax variant"))
            isempty(field_defaults) || throw(ArgumentError("cannot have default value for call syntax variant"))
        end
        new(type, name, public, ismutable, fieldnames, field_defaults, fieldtypes, lineinfo)
    end
end

Base.@kwdef struct ADTTypeDef
    # head of the type
    m::Module = Main
    name::Symbol
    typevars::Vector{Any} = Any[]
    supertype::Any = nothing
    export_variants::Bool = false

    # enum of the type
    # <name>
    # <call signature>
    # <struct>
    variants::Vector{Variant}
end

function Variant(ex, lineinfo = nothing; public::Bool = false)
    @switch ex begin
        @case Expr(:macrocall, &(Symbol("@public")), _, ex)
            Variant(ex, lineinfo; public=true)
        @case ::Symbol
            Variant(;type=:singleton, name=ex, public)
        @case :($name($(args...)))
            foreach(args) do arg
                Meta.isexpr(arg, :(::)) && length(arg.args) == 1 ||
                    throw(ArgumentError("expect ::<type> in call syntax variant, got $arg"))
            end
            Variant(;type=:call, name=name, fieldtypes=annotations_only.(args), public)
        @case Expr(:struct, _...)
            def = JLKwStruct(ex)
            Variant(;
                type=:struct,
                name=def.name,
                public,
                ismutable=def.ismutable,
                fieldnames=map(x->x.name, def.fields),
                field_defaults=map(x->x.default, def.fields),
                fieldtypes=map(x->x.type, def.fields),
                lineinfo
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
    # TODO: use our custom constructor so we can
    # partially initialize a struct type with selected fields
    # to be #undef
    # julia/src/datatype.c:jl_new_structv(jl_datatype_t *type, jl_value_t **args, size_t nargs)

    # do not support generic ADT for now
    isempty(typevars) || throw(ArgumentError("generic ADT is not supported yet"))
    return name, typevars, supertype
end

function ADTTypeDef(m::Module, head, body::Expr; export_variants::Bool = false)
    variants = Variant[]
    lineinfo = nothing
    for ex in body.args
        if ex isa LineNumberNode
            lineinfo = ex
        else
            push!(variants, Variant(ex, lineinfo))
            lineinfo = nothing
        end
    end
    return ADTTypeDef(m, adt_split_head(head)..., export_variants, variants)
end

function Base.:(==)(a::Variant, b::Variant)
    a.type == b.type && a.name == b.name && a.ismutable == b.ismutable &&
    a.public == b.public && a.fieldnames == b.fieldnames &&
    a.fieldtypes == b.fieldtypes
end
