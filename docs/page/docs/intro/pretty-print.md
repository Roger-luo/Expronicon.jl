# Pretty Printing

`Expronicon` offers two pretty printers for Julia expressions. The first one is called
a `InlinePrinter` and the second one is called a `Printer`. The `InlinePrinter` prints
Julia expressions strictly in a single line, while the `Printer` prints Julia expressions in
a multi-line format.

The inline printer can be accessed by `print_inline` function,
and the multi-line printer can be accessed by `print_expr` function.
