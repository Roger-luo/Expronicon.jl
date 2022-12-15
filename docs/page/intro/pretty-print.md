# Pretty Printing

`Expronicon` offers two pretty printers for Julia expressions. The first one is called
a `InlinePrinter` and the second one is called a `Printer`. The `InlinePrinter` prints
Julia expressions strictly in a single line, while the `Printer` prints Julia expressions in
a multi-line format.

The inline printer can be accessed by `print_inline` function,
and the multi-line printer can be accessed by `print_expr` function.

## Inline Printer

The inline printer has two configuration

- `color`: what color theme to use, default is `Monokai256`.
- `line`: print line number or not, default is false.

## Multi-line Printer

The multi-line printer has the following configuration

- `indent`: the indentation level, default is the same as `get(io, :indent, 0)`.
- `color`: what color theme to use, default is `Monokai256`.
- `line`: print line number or not, default is `false`.
- `always_begin_end`: always print `begin` and `end` even if it is not necessary, default is `false`.
- `root`: if `true` then the expression is printed as a root expression, default is `true`.

## Colors

The color of printing is configured by `Expronicon.ColorScheme` type. 

```julia
Base.@kwdef struct ColorScheme
    symbol::Int
    type::Int
    variable::Int
    quoted::Int
    keyword::Int
    number::Int
    string::Int
    comment::Int
    line::Int
    call::Int
    macrocall::Int
    op::Int
end
```

The default color is the `Monakai256`:

```julia
function Monokai256()
    return ColorScheme(;
        symbol=141,
        type=141,
        variable=141,
        quoted=141,
        keyword=197,
        number=141,
        string=185,
        comment=240,
        line=240,
        call=81,
        macrocall=81,
        op=197,
    )
end
```