using Test
using Expronicon
using Expronicon.ADT: ADTTypeDef, Variant, adt_split_head

@testset "adt_split_head" begin
    @test adt_split_head(:Message) == (:Message, Any[], nothing)
    @test adt_split_head(:(Message <: AbstractMessage)) == (:Message, Any[], :AbstractMessage)
    @test_throws ArgumentError adt_split_head(:(Message{T} <: AbstractMessage)) # == (:Message, Any[:T], :AbstractMessage)
    @test_throws ArgumentError adt_split_head(:(Message{T <: Int} <: AbstractMessage)) # == (:Message, Any[:(T <: Int)], :AbstractMessage)
end

@testset "ADTTypeDef(ex)" begin
    body = quote
        Quit
        
        struct Move
            x::Int
            y::Int
        end

        Write(::String)

        ChangeColor(::Int, ::Int, ::Int)
    end

    def = ADTTypeDef(Main, :Message, body)

    @test def.variants[1] == Variant(:Quit)
    @test def.variants[2] == Variant(:(struct Move; x::Int; y::Int; end))
    @test def.variants[3] == Variant(:(Write(::String)))
    @test def.variants[4] == Variant(:(ChangeColor(::Int, ::Int, ::Int)))

    io = IOBuffer()
    show(io, MIME"text/plain"(), def)
    @test String(take!(io)) == """
    @adt Message begin
        Quit

        struct Move
            x::Int
            y::Int
        end

        Write(::String)

        ChangeColor(::Int, ::Int, ::Int)
    end"""

    def = ADTTypeDef(Main, :(Message <: AbstractMessage), body)
    io = IOBuffer()
    show(io, MIME"text/plain"(), def)
    @test String(take!(io)) == """
    @adt Message <: AbstractMessage begin
        Quit

        struct Move
            x::Int
            y::Int
        end

        Write(::String)

        ChangeColor(::Int, ::Int, ::Int)
    end"""

    # def = ADTTypeDef(Main, :(Message{T <: Int, S} <: AbstractMessage), body)
    # io = IOBuffer()
    # show(io, MIME"text/plain"(), def)
    # @test String(take!(io)) == """
    # @adt Message{T <: Int, S} <: AbstractMessage begin
    #     Quit

    #     struct Move
    #         x::Int
    #         y::Int
    #     end

    #     Write(::String)

    #     ChangeColor(::Int, ::Int, ::Int)
    # end"""
end
