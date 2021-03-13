@active GlobalRef(x) begin
    if x isa GlobalRef
        (x.mod, x.name)
    else
        nothing
    end
end

@active Symbol(x) begin
    if x isa Symbol
        Some(string(x))
    else
        nothing
    end
end
