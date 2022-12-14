using Test
using Expronicon

@test_throws ArgumentError jlfn = JLFunction(;
    name=:aaa,
    args=[:a, JLKwField(name=:b, default=1)],
)

@test_throws ArgumentError jlfn = JLFunction(;
    name=":aaa",
    args=[:a, JLKwField(name=:b, default=1)],
)

@test_throws ArgumentError jlfn = JLFunction(;
    head=:aaa,
    name=":aaa",
    args=[:a, JLKwField(name=:b, default=1)],
)

@test_throws ArgumentError jlfn = JLFunction(;
    head=:aaa,
    name=":aaa",
    args=[:a],
    kwargs=[JLKwField(name=:b, default=1)]
)

@test_throws ArgumentError jlfn = JLFunction(;
    head=:aaa,
    name=":aaa",
    args=[:a],
    whereparams=[JLKwField(name=:b, default=1)]
)
