using MLStyle
using Expronicon
using Expronicon.ADT: ADT, @adt, @derive

is_hash_equal(::Type{<:Union{}}) = false

@adt MyADT begin
    Token
    struct Message
        x::Int
        y::Int
    end
end

@derive MyADT: hash, isequal, ==
ex = @expr MyADT: isless

@switch ex begin
    @case :($name:$(first::Symbol))
    @case Expr(:tuple, :($name:$(first::Symbol)), [e::Symbol for e in others]...)
    @case _
        error("Invalid expression")
end