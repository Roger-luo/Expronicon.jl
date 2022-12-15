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
julia> @match Move(1, 2) begin
           Move(x, y) => x + y
           _ => false
       end
3
```

or using named pattern matching:

```julia
julia> @match Move(1, 2) begin
           Move(;x) => x
           _ => false
       end
1
```

the annoymous fields can only be matched using positional pattern matching:

```julia
julia> @match Write("hello") begin
           Write(s) => s
           _ => false
       end
"hello"
```

the singleton variants can be matched directly by the variant name:

```julia
julia> @match Quit begin
        Quit => true
        _ => false
    end
true
```
