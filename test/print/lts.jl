using Expronicon: @expr, Printer, InlinePrinter, print_inline, print_expr

print_inline(:(try; x + 1; y+1; catch e; 1 + 1; else x; finally 2 + 2 end))

ex = @expr try
    1 + 1
catch e
    2 + 2
else e
    3 + 3
finally
    4 + 4
end

print_expr(ex)

ex = @expr try
    1 + 1
catch e
    2 + 2
else e
    3 + 3
end

print_expr(ex)
