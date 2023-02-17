using MLStyle
using Expronicon.ADT: @adt

@macroexpand @adt Foo begin
    Bar
    struct Baz
        args::Vector{Int}
    end
end

function Base.:(==)(lhs::Foo, rhs::Foo)
    @match (lhs, rhs) begin
        (Bar, Bar) => true
        (Baz(args), Baz(args)) => args == args
        _ => false
    end
end

Bar == Bar

@less Bar == Bar
@edit Baz([1, 2, 3]) == Baz([1, 2, 3])
Baz([1, 2, 3]) == Baz([1, 2, 3])

@match (lhs, rhs) begin
    (Bar, Bar) => true
    (Baz(args), Baz(args)) => args == args
    _ => false
end

@enum Fruit begin
    Apple
    Banana
    Orange
end

function Base.:(==)(lhs::Fruit, rhs::Fruit)
    @match (lhs, rhs) begin
        (&Apple, &Apple) => true
        (&Banana, &Banana) => true
        (&Orange, &Orange) => true
        _ => false
    end
end

Apple == Apple

@macroexpand @match (lhs, rhs) begin
(Apple, Apple) => true
(Banana, Banana) => true
(Orange, Orange) => true
_ => false
end


