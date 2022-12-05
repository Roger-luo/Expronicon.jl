using Expronicon: @expr, print_inline

print_inline(:(1 + 1))
print_inline(:(module A end))
print_inline(:(using A, B))
print_inline(:(using A: a, b))
print_inline(:(import A, B))
print_inline(:(import A: a, b as c))
print_inline(:(import A as B))
print_inline(:(A.B))
print_inline(:(export a, b))
print_inline("aaaa")
print_inline(:("aaaa" * "bbbb"))
print_inline(:(A{T} where {T <: B}))
print_inline(:(A{T} where {T <: B, T2 <: C}))
print_inline(:(A::B))

print_inline(:(foo(x, y, z)))
print_inline(:(foo(x, y, z...)))
print_inline(:(foo(x, y, z; a, b=2)))
print_inline(:(@mymacro (x+1;x+2) y z+1))
print_inline(:((a in b).+1))
print_inline(:(1:10))

print_inline(:(x->x+1))
print_inline(:(x,y->x+1))
print_inline(:((x,y)->(x+1;y+1)))

print_inline(:(1 + x + y + z))
print_inline(:(+z))
print_inline(:(-z))
print_inline(:((1, 2, x)))

print_inline(:([1, 2, x]))
print_inline(:([1 2 x]))
print_inline(:([1;2;x]))
print_inline(:([1;;2;;x]))
print_inline(:(Float64[1, 2, x]))
print_inline(:(Float64[1 2 x]))

print_inline(quote; x+1; y+1; end)
print_inline(Expr(:string, "aaa", :x, "bbb"))

print_inline(:(:x))
print_inline(:(:(1 + 1; 2 + x)))
print_inline(:(1 + 1; 2 + x))
print_inline(:(let x = 1, y; x + 1; y+1 end))

print_inline(:(for i in 1:10; x + 1; y+1 end))
print_inline(:(while x < 10; x + 1; y+1 end))

print_inline(:(if x < 10; x + 1; y+1 end))
print_inline(:(if x < 10; x + 1; y+1 else; x + 1; y+1 end))
print_inline(:(if x < 10; x + 1; y+1 elseif x < 10; x + 1; y+1 else; x + 1; y+1 end))

print_inline(:(try; x + 1; y+1; catch; 1 + 1 end))
print_inline(:(try; x + 1; y+1; catch e; 1 + 1 end))
print_inline(:(try; x + 1; y+1; catch e; 1 + 1; finally 2 + 2 end))

@static if VERSION > v"1.8-"
    print_inline(:(try; x + 1; y+1; catch e; 1 + 1; else x; finally 2 + 2 end))
end

print_inline(Expr(:$, :(1 + 2)))
print_inline(Expr(:meta, :aa, 2))
print_inline(:($(Symbol("##a#112")) + 1))
print_inline(:(::$(Symbol("##a#112")) + 1))
