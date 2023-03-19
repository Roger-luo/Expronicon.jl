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

