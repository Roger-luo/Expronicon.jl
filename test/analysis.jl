using Test
using Expronicon

@testset "is_function" begin
    @test is_function(:(foo(x) = x))
    @test is_function(:(x -> 2x))
end

@testset "uninferrable_typevars" begin
    def = @expr JLKwStruct struct Inferable1{T}
        x::Constaint{T, <(2)}
    end
    
    @test uninferrable_typevars(def) == []
    
    def = @expr JLKwStruct struct Inferable2{T}
        x::Constaint{Float64, <(2)}
    end

    @test uninferrable_typevars(def) == [:T]

    def = @expr JLKwStruct struct Inferable3{T, N}
        x::Int
        y::N
    end
    @test uninferrable_typevars(def) == [:T]


    def = @expr JLKwStruct struct Inferable4{T, N}
        x::T
        y::N
    end
    @test uninferrable_typevars(def) == []

    def = @expr JLKwStruct struct Inferable5{T, N}
        x::T
        y::Float64
    end

    @test uninferrable_typevars(def) == [:T, :N]
    @test uninferrable_typevars(def; leading_inferable=false) == [:N]
end

@testset "has_plain_constructor" begin
    def = @expr JLKwStruct struct Foo1{T, N}
        x::Int
        y::N
        Foo1{T, N}(x, y) where {T, N} = new{T, N}(x, y)
    end

    @test has_plain_constructor(def) == true

    def = @expr JLKwStruct struct Foo2{T, N}
        x::T
        y::N
        Foo2(x, y) = new{typeof(x), typeof(y)}(x, y)
    end

    @test has_plain_constructor(def) == false

    def = @expr JLKwStruct struct Foo3{T, N}
        x::Int
        y::N
        Foo3{T}(x, y) where T = new{T, typeof(y)}(x, y)
    end

    @test has_plain_constructor(def) == false

    def = @expr JLKwStruct struct Foo4{T, N}
        x::T
        y::N
        Foo4{T, N}(x::T, y::N) where {T, N} = new{T, N}(x, y)
    end

    @test has_plain_constructor(def) == false
end

@testset "is_kw_function" begin
    @test is_kw_function(:(
        function foo(x::Int; kw=1)
        end
    ))

    ex = :(function (x::Int; kw=1) end)
    @test is_kw_function(ex)
    @test !is_kw_function(true)

    @test !is_kw_function(:(
        function foo(x::Int)
        end
    ))

    @test !is_kw_function(:(
        function (x::Int)
        end
    ))
end

@testset "JLKwField" begin
    kw = JLKwField(;name=:arg)
    @test codegen_ast(kw) == :arg

    kw = JLKwField(;name=:arg, type=:Int)
    @test codegen_ast(kw) == :(arg::Int)

    kw = JLKwField(;name=:arg, default=10)
    @test codegen_ast(kw) == :($(Expr(:kw, :arg, 10)))

    kw = JLKwField(;name=:arg, type=:Int, default=10)
    @test codegen_ast(kw) == :($(Expr(:kw, :(arg::Int), 10)))
end

@testset "JLFunction(ex)" begin
    jlfn = JLFunction()
    @test jlfn.name === nothing

    @test_expr JLFunction function foo(x::Int, y::Type{T}) where {T <: Real}
        return x
    end

    def = @test_expr JLFunction function (x, y)
        return 2
    end
    @test is_kw_function(def) == false

    def = @test_expr JLFunction function (x, y; kw=2)
        return "aaa"
    end
    @test is_kw_function(def) == true

    @test_expr JLFunction (x, y)->sin(x)

    # canonicalize head when it's a block
    @test_expr JLFunction function (x::Int; kw=1) end

    ex = :(struct Foo end)
    @test_throws AnalysisError JLFunction(ex)
    ex = :(@foo(2, 3))
    @test_throws AnalysisError split_function_head(ex)

    ex = :(Foo(; a = 1) = new(a))
    @test JLFunction(ex).kwargs[1] == Expr(:kw, :a, 1)

    @test_expr JLFunction function f(x::T; a=10)::Int where T
        return x
    end

    @test_expr JLFunction f(x::Int)::Int = x
end

@testset "JLStruct(ex)" begin
    @test JLField(;name=:x).name === :x
    @test JLField(;name=:x).type === Any
    @test JLStruct(;name=:Foo).name === :Foo

    ex = :(struct Foo
        x::Int
    end)

    jlstruct = JLStruct(ex)
    println(jlstruct)
    @test jlstruct.name === :Foo
    @test jlstruct.ismutable === false
    @test length(jlstruct.fields) == 1
    @test jlstruct.fields[1].name === :x
    @test jlstruct.fields[1].type === :Int
    @test jlstruct.fields[1].line isa LineNumberNode
    @test codegen_ast(jlstruct) == ex

    ex = :(mutable struct Foo{T, S <: Real} <: AbstractArray
        a::Float64

        function foo(x, y, z)
            new(1)
        end
    end)

    jlstruct = JLStruct(ex)
    println(jlstruct)
    @test jlstruct.ismutable == true
    @test jlstruct.name === :Foo
    @test jlstruct.typevars == Any[:T, :(S <: Real)]
    @test jlstruct.supertype == :AbstractArray
    @test jlstruct.misc[1] == ex.args[3].args[end]
    @test rm_lineinfo(codegen_ast(jlstruct)) == rm_lineinfo(ex)

    ex = quote
        """
        Foo
        """
        struct Foo
            "xyz"
            x::Int
            y

            Foo(x) = new(x)
            1 + 1
        end
    end
    ex = ex.args[2]
    jlstruct = JLStruct(ex)
    @test jlstruct.doc == "Foo\n"
    @test jlstruct.fields[1].doc == "xyz"
    @test jlstruct.fields[2].type === Any
    @test jlstruct.constructors[1].name === :Foo
    @test jlstruct.constructors[1].args[1] === :x
    @test jlstruct.misc[1] == :(1 + 1)
    ast = codegen_ast(jlstruct)
    @test ast.args[1] == GlobalRef(Core, Symbol("@doc"))
    @test ast.args[3] == "Foo\n"
    @test ast.args[4].head === :struct
    @test is_function(ast.args[4].args[end].args[end-1])
    println(jlstruct)

    @test_throws AnalysisError split_struct_name(:(function Foo end))
end

@testset "JLKwStruct" begin
    def = @expr JLKwStruct struct Trait end
    @test_expr prettify(codegen_ast_kwfn(def)) == quote
    end

    @test JLKwField(;name=:x).name === :x
    @test JLKwField(;name=:x).type === Any
    @test JLKwStruct(;name=:Foo).name === :Foo

    def = @expr JLKwStruct struct ConvertOption
        include_defaults::Bool=false
        exclude_nothing::Bool=false
    end

    @test_expr codegen_ast_kwfn(def, :create) == quote
        function create(::Type{S}; include_defaults = false, exclude_nothing = false) where S <: ConvertOption
            ConvertOption(include_defaults, exclude_nothing)
        end
    end

    def = @expr JLKwStruct struct Foo1{N, T}
        x::T = 1
    end
    println(def)

    @test_expr codegen_ast_kwfn(def, :create) == quote
        function create(::Type{S}; x = 1) where {N, T, S <: Foo{N, T}}
            Foo1{N, T}(x)
        end
        function create(::Type{S}; x = 1) where {N, S <: Foo{N}}
            Foo1{N}(x)
        end
    end

    @test_expr codegen_ast(def) == quote
        struct Foo1{N, T}
            x::T
        end
        function Foo1{N, T}(; x = 1) where {N, T}
            Foo1{N, T}(x)
        end
        function Foo1{N}(; x = 1) where N
            Foo1{N}(x)
        end
    end

    def = @expr JLKwStruct struct Foo2 <: AbstractFoo
        x = 1
        y::Int
    end

    @test_expr codegen_ast(def) == quote
        struct Foo2 <: AbstractFoo
            x
            y::Int
        end
        function Foo2(; x = 1, y)
            Foo2(x, y)
        end
    end

    ex = quote
        """
        Foo
        """
        mutable struct Foo
            "abc"
            a::Int = 1
            b

            Foo(x) = new(x)
            1 + 1
        end
    end
    ex = ex.args[2]
    jlstruct = JLKwStruct(ex)
    @test jlstruct.doc == "Foo\n"
    @test jlstruct.fields[1].doc == "abc"
    @test jlstruct.fields[2].name === :b
    @test jlstruct.constructors[1].name === :Foo
    @test jlstruct.misc[1] == :(1 + 1)
    println(jlstruct)

    def = @expr JLKwStruct struct Foo3
        a::Int = 1
        Foo3(;a = 1) = new(a)
    end

    @test_expr codegen_ast(def) == quote
        struct Foo3
            a::Int
            Foo3(; a = 1) = new(a)
        end
    end

    def = @expr JLKwStruct struct Potts{Q}
        L::Int
        beta::Float64=1.0
        neighbors::Neighbors = square_lattice_neighbors(L)
    end

    @test_expr codegen_ast_kwfn(def, :create) == quote
        function create(::Type{S}; L, beta = 1.0, neighbors = square_lattice_neighbors(L)) where {Q, S <: Potts{Q}}
            Potts{Q}(L, beta, neighbors)
        end
    end

    def = @expr JLKwStruct struct Flatten
        x = 1
        begin
            y = 1
        end
    end

    @test def.fields[1].name === :x
    @test def.fields[2].name === :y
end

@test sprint(print, AnalysisError("a", "b")) == "expect a expression, got b."

@testset "JLIfElse" begin
    jl = JLIfElse()
    jl[:(foo(x))] = :(x = 1 + 1)
    jl[:(goo(x))] = :(y = 1 + 2)
    jl.otherwise = :(error("abc"))
    println(jl)

    ex = codegen_ast(jl)
    dst = JLIfElse(ex)
    @test_expr dst[:(foo(x))] == :(x = 1 + 1)
    @test_expr dst[:(goo(x))] == :(y = 1 + 2)
    @test_expr dst.otherwise == :(error("abc"))
end

@testset "JLFor" begin
    ex = :(for i in 1:10, j in 1:20,
            k in 1:10
        1 + 1
    end)
    jl = JLFor(ex)
    println(jl)
    @test codegen_ast(jl) == ex

    jl = JLFor(;vars=[:x], iterators=[:itr], kernel=:(x + 1))
    ex = codegen_ast(jl)
    @test ex.head === :for
    @test ex.args[1].args[1] == :(x = itr)
    @test ex.args[2] == :(x+1)

    ex = :(for i in 1:10
        1 + 1
    end)
    jl = JLFor(ex)
    println(jl)
    @test jl.vars == [:i]
    @test jl.iterators == [:(1:10)]
end
