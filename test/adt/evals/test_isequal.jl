module TestIsEqualEnum

using Test
using MLStyle
using Expronicon.ADT: @adt, @use, variant_type

@adt Foo begin
    Bar
    struct Baz
        args::Vector{Int}
    end
end

@use Foo: *

function Base.:(==)(lhs::Foo, rhs::Foo)
    @match (lhs, rhs) begin
        (Bar, Bar) => true
        (Baz(args), Baz(args)) => args == args
        _ => false
    end
end

@testset "isequal(enum)" begin
    @test Bar == Bar
end

end # module
