tab(n) = " "^n

function Base.show(io::IO, mime::MIME"text/plain", def::ADTTypeDef)
    printstyled(io, "@adt "; color=:cyan)
    def.m === Main || print(io, def.m, ".")
    print(io, def.name)
    if !isempty(def.typevars)
        print(io, "{")
        join(io, def.typevars, ", ")
        print(io, "}")
    end

    if def.supertype !== nothing
        print(io, " <: ")
        print(io, def.supertype)
    end

    print(io, tab(1))
    printstyled(io, "begin"; color=:light_red)
    println(io)

    for (i, variant) in enumerate(def.variants)
        show(IOContext(io, :indent => 4), mime, variant)
        println(io)

        if i < length(def.variants)
            println(io)
        end
    end
    printstyled(io, "end"  ; color=:light_red)
    return
end

function Base.show(io::IO, ::MIME"text/plain", def::Variant)
    indent = get(io, :indent, 0)
    print(io, tab(indent))

    if def.type == :singleton
        print(io, def.name)
    elseif def.type == :call
        print(io, def.name, "(")
        for (i, type) in enumerate(def.fieldtypes)
            printstyled(io, "::"; color=:light_black)
            printstyled(io, type; color=:cyan)
            if i < length(def.fieldtypes)
                print(io, ", ")
            end
        end
        print(io, ")")
    else
        if def.ismutable
            print(io, "mutable ")
        end
        printstyled(io, "struct "; color=:light_red)
        println(io, def.name)
        for (i, field) in enumerate(def.fields)
            type = def.fieldtypes[i]
            print(io, tab(indent+4), field)
            if type != Any
                printstyled(io, "::"; color=:light_black)
                printstyled(io, type; color=:cyan)
            end
            println(io)
        end
        printstyled(io, tab(indent), "end"; color=:light_red)
    end
    return
end

function Base.show(io::IO, ::MIME"text/plain", info::EmitInfo)
    color = get(io, :color, false)
    println(io, "EmitInfo:")
    println(io, tab(2), "Fields: ")
    for (name, type) in zip(info.fieldnames, info.fieldtypes)
        println(io, tab(4), name, "::", type)
    end

    println(io)
    println(io, tab(2), "Variants:")

    variants = sort(collect(keys(info.variant_masks)); by=x->x.name)
    for (idx, variant) in enumerate(variants)
        mask = info.variant_masks[variant]
        buf = IOBuffer()
        show(IOContext(buf, :color=>color), MIME"text/plain"(), variant)
        lines = split(String(take!(buf)), '\n')

        print(io, tab(4), lines[1], " => ", mask)
        if !(length(lines) == 1 && idx == length(variants))
            println(io)
        end

        for line_idx in 2:length(lines)
            print(io, tab(4), lines[line_idx])

            if !(idx == length(variants) && line_idx == length(lines))
                println(io)
            end
        end
    end
    return
end
