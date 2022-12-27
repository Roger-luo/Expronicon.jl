tab(n) = " "^n
splitlines(s::String) = split(s, '\n')

function variant_show_inline(io::IO, x)
    return variant_show_inline_default(io, x)
end

function variant_show_inline_default(::IO, x)
    error("this method is expected to be generated for $(typeof(x)) by @adt macro")
end

function Base.show(io::IO, mime::MIME"text/plain", def::ADTTypeDef)
    printstyled(io, "@adt "; color=:cyan)
    def.export_variants && printstyled(io, "public "; color=197)
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
        for (i, fieldname) in enumerate(def.fieldnames)
            type = def.fieldtypes[i]
            print(io, tab(indent+4), fieldname)
            if type != Any
                printstyled(io, "::"; color=:light_black)
                printstyled(io, type; color=:cyan)
            end

            default = def.field_defaults[i]
            if default !== no_default
                print(io, " = ")
                print(io, default)
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
    print(io, tab(2), "typename: ")
    printstyled(io, info.typename; color=:cyan)
    println(io)
    print(io, tab(2), "ismutable: ")
    printstyled(io, info.ismutable; color=:light_magenta)
    println(io)
    println(io, tab(2), "fields: ")
    for (name, type) in zip(info.fieldnames, info.fieldtypes)
        print(io, tab(4), name)
        printstyled(io, "::"; color=:light_black)
        printstyled(io, type; color=:cyan)
        println(io)
    end

    isempty(info.typeinfo) && return

    println(io)
    println(io, tab(2), "variants:")

    variants = sort(collect(keys(info.typeinfo)); by=x->x.name)

    # find max line width
    variant_lines_nocolor = map(variants) do variant
        buf = IOBuffer()
        show(IOContext(buf, :color=>false), MIME"text/plain"(), variant)
        splitlines(String(take!(buf)))
    end

    max_line_width = maximum(variant_lines_nocolor) do lines
        maximum(length, lines)
    end

    # then we need to split out the color again
    for (idx, variant) in enumerate(variants)
        # split the lines with color so we can insert the mask print
        buf = IOBuffer()
        show(IOContext(buf, :color=>color), MIME"text/plain"(), variant)
        lines = splitlines(String(take!(buf))) # lines with color
        padding = max_line_width - length(variant_lines_nocolor[idx][1]) + 4

        mask = info.typeinfo[variant].mask
        print(io, tab(4), lines[1], tab(1))
        printstyled(io, '-'^(padding-2); color=:light_black)

        print(io, " [")
        join(io, mask, ", ")
        print(io, "]")
        # don't print newline if last line
        if !(length(lines) == 1 && idx == length(variants))
            println(io)
        end

        for line_idx in 2:length(lines)
            print(io, tab(4), lines[line_idx])

            # don't print newline if last line
            if !(idx == length(variants) && line_idx == length(lines))
                println(io)
            end
        end
    end
    return
end
