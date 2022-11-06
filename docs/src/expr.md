# Expression 101

Expression is the most basic object in a programming language
(or at least most basic in a lispy language like Julia). It
appears naturally in many case, such as a math equation,
a network interface, a programming language.

Let's start with a simple math equation of `+`, `-` and `*`
as an example

```julia
(a * b) + (c - d)
```

the above is a very simple math equation, we can store this
as a tree, there are many different ways to store the equation
above as a tree, we will stick to something called infix
expression, and the corresponding tree of above is
