# Pattern Matching

Pattern matching with MLStyle is about deconstructing a value in the same
way as how you construct it. This is true for `Expronicon`'s algebra
data types defined using `@adt` macro.

## Pattern matching examples

Let's first define a simple ADT describes a message (taken from rust book)

```julia
@adt Message begin
    Quit

    struct Move
        x::Int
        y::Int = 1
    end

    Write(::String)

    ChangeColor(::Int, ::Int, ::Int)
end
```

the named fields can be matched using positional pattern matching:

```julia
julia> @match Message.Move(1, 2) begin
           Message.Move(x, y) => x + y
           _ => false
       end
3
```

or using named pattern matching:

```julia
julia> @match Message.Move(1, 2) begin
           Message.Move(;x) => x
           _ => false
       end
1
```

the anonymous fields can only be matched using positional pattern matching:

```julia
julia> @match Message.Write("hello") begin
           Message.Write(s) => s
           _ => false
       end
"hello"
```

the singleton variants can be matched directly by the variant name:

```julia
julia> @match Message.Quit begin
        &Message.Quit => true
        _ => false
    end
true
```

note that the `&` is required to match the singleton variant due to
a current limitation of [MLStyle pattern matcher](https://github.com/thautwarm/MLStyle.jl/issues/156).
