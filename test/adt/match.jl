module TestMatch

using Test
using MLStyle
using Expronicon.ADT: ADT, @adt, ADTTypeDef, EmitInfo,
    emit_variant_cons, variant_fieldnames, variant_masks,
    variant_type, variants, variant_typename, adt_type

@adt Message begin
    Quit

    struct Move
        x::Int
        y::Int = 1
    end

    Write(::String)

    ChangeColor(::Int, ::Int, ::Int)
end

@testset "basic patterns" begin
    @test 3 == @match Move(1, 2) begin
        Move(x, y) => x + y
        _ => false
    end

    @test 1 == @match Move(1, 2) begin
        Move(x, _...) => x
        _ => false
    end

    @test @match Move(1, 2) begin
        Move(_...) => true
        _ => false
    end

    @test 1 == @match Move(1, 2) begin
        Move(;x) => x
        _ => false
    end

    @test 3 == @match Move(1, 2) begin
        Move(;x, y) => x + y
        _ => false
    end

    @test false == @match Move(1, 2) begin
        Move(;x, y=3) => x
        _ => false
    end

    @test 1 == @match Move(1, 2) begin
        Move(;x, y=2) => x
        _ => false
    end

    @match Move(1, 2) begin
        Move(;x) => @test x == 1
        _ => false
    end

    @match Write("abc") begin
        Write(s) => @test s == "abc"
        _ => false
    end

    @test @match Quit begin
        Quit => true
        _ => false
    end
end


@adt Muban begin
    struct Template
        stmts::Vector{Muban}
    end

    Text(::String)
    Comment(::String)

    # inline expr
    # reference to a Julia variable
    Id(::String)
    Literal(::Any)

    struct InlineExpr
        head::Int
        args::Vector{Muban}
    end

    struct Loop
        indices::Vector{Muban} # list of Id
        iterator::Muban # <inline expr>
        body::Template # Template
    end
end

@testset "variant type match" begin
    x = Loop([Id("i"), Id("j")], InlineExpr(1, [Id("a"), Id("b")]), Template([]))

    @match x begin
        Text(s) => @test s == "abc"
        Loop(indices, iterator, body) => @test true
        _ => @test false
    end
end

end
