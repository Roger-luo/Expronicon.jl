# Defining algebra data types

`Expronicon` provides a macro `@adt` to define the algebra data types (ADT).
The syntax and semantic is very similar to rust's `enum` type. 

## A glance of the syntax

The simplest syntax of `@adt` is:

```julia
@adt <name> begin
    <variant1>
    <variant2>
    ...
end
```

where `<name>` should be a valid identifier, and can optionally
take a supertype as `<name> <: <supertype>`. `<variant>` is one of the following:

```julia
<name> # variant with no field
<name>(<field1>, <field2>, ...) # variant with anonymous fields
struct <name>
    <field1>
    <field2>
    ...
end # variant with named fields
```

## Singleton variants

The singleton variants are similar to an enum. It only requires a name
and no fields. For example:

```julia
@adt Food begin
    Apple
    Orange
    Banana
end
```

## Variants with anonymous fields

It is sometimes useful to define a variant with anonymous fields.
So you can save a few minutes for figuring out a good name for the fields.
To declare a variant with anonymous fields, you can use the following syntax:

```julia
@adt Message begin
    Info(::String)
    Warning(::String)
    Error(::String)
end
```

and you can construct the corresponding variant with the following syntax:

```julia
Message.Info("hello")
Message.Warning("hello")
Message.Error("hello")
```

## Variants with named fields

It is also possible to define a variant with named fields. This syntax
is the same as a keyword structure definition in Julia
(the syntax of `Base.@kwdef` or `Configurations.@option`). For example:

```julia
@adt Animal begin
    struct Cat
        name::String = "Tom"
        age::Int = 3
    end
    struct Dog
        name::String = "Jack"
        age::Int = 5
    end
end
```

and you can construct the corresponding variant with the following syntax:

```julia
Animal.Cat(; name="Tom", age=3)
Animal.Dog(; name="Jack", age=5)
```

Or you can also just construct normally:

```julia
Animal.Cat("Tom", 3)
Animal.Dog("Jack", 5)
```
