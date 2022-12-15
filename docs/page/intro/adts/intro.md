# Algebra data type

Expronicon provides a way to define algebra data types. The syntax and semantic
is very similar to rust's enum type. The algebra data type is useful when you
want to define an intermediate representation (IR) for your own language,
or when you want to define a type that can be used in a pattern matching.

## Features

- support `MLStyle` pattern matching
- type stable - this enables fast pattern matching and code manipulation
- rust-like syntax

## Limitations

**no support for generics**, because we want to guarantee the type stability.
For generic algebra data type, you can use the `@datatype` macro provided by
MLStyle.

## What's happening under the hood

The `@adt` macro will generate a new type and a set of constructors for the
type. It will wrap mulitple variants in the same Julia struct, and use a tag field
to distinguish the variants. This is why it is type stable.

The `@adt` macro will also generate a set of functions for pattern matching too, which
is why all `MLStyle` pattern matching works.

The `@adt` macro will also generate a set of reflection functions, so that you can
inspect the algebra data type easily.
