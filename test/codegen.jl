using Test
using Expronicon

@testset "x function" begin
    @test_expr xtuple(1, :x) == :((1, x))
    @test_expr xnamedtuple(;x=2, y=3) == :((x = 2, y = 3))
    @test_expr xcall(Base, :sin, 1; x=2) == :($Base.sin(1; x = 2))
    @test_expr xpush(:coll, :x) == :($Base.push!(coll, x))
    @test_expr xfirst(:coll) == :($Base.first(coll))
    @test_expr xlast(:coll) == :($Base.last(coll))
    @test_expr xprint(:coll) == :($Base.print(coll))
    @test_expr xprintln(:coll) == :($Base.println(coll))
    @test_expr xmap(:f, :coll) == :($Base.map(f, coll))
    @test_expr xmapreduce(:f, :op, :coll) == :($Base.mapreduce(f, op, coll))
    @test_expr xiterate(:it) == :($Base.iterate(it))
    @test_expr xiterate(:it, :st) == :($Base.iterate(it, st))        
end
