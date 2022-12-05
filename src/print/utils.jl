function is_line_no(x)
    x isa LineNumberNode && return true
    x isa Expr && x.head == :line && return true
    return false
end
