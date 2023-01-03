function ADT.variant_show_inline(io::IO, x::Pattern)
    no_quote_io = IOContext(io, :quote => true)

    function valid_filename_char(c)
        return isletter(c) || isdigit(c) || c == '_' ||
            c == '-' || c == '.' || c == '/'
    end

    function print_iden(name::String)
        for c in name
            if c == '*' || c == '?' || c == '[' || c == ']'
                printstyled(io, c; color=:light_red)
            elseif valid_filename_char(c)
                print(io, c)
            else
                printstyled(io, '\\'; color=:magenta)
                print(io, c)
            end
        end
    end

    function print_paths(segments::Vector{Pattern})
        for (idx, segment) in enumerate(segments)
            segment == Root || ADT.variant_show_inline(no_quote_io, segment)
            if idx < length(segments)
                printstyled(io, "/"; color=:light_black)
            end
        end
    end

    quoted = get(io, :quote, false)
    quoted || (printstyled(io, "pattern"; color=:light_black); print(io, "\""))

    @match x begin
        Comment(msg) => printstyled(io, "#", msg; color=:light_black)
        Root => printstyled(io, "Root"; color=:light_red)
        EmptyLine => printstyled(io, "EmptyLine"; color=:light_red)
        DoubleAsterisk => printstyled(io, "**"; color=:light_red)

        FileName(name) => print_iden(name)

        Not(pattern) => begin
            printstyled(io, "!"; color=:light_red)
            ADT.variant_show_inline(no_quote_io, pattern)
        end

        Path(segments) => print_paths(segments)
        Directory(segments) => begin
            print_paths(segments)
            printstyled(io, "/"; color=:light_black)
        end
    end
    quoted || print(io, "\"")
end

function Base.show(io::IO, ::MIME"text/plain", file::IgnoreFile)
    printstyled(io, "# ignore path: ", file.path; color=:light_black)
    print(io, "\n\n")
    dump_ignore(io, file)
end

function dump_ignore(io::IO, file::IgnoreFile)
    for stmt in file.stmts
        stmt == EmptyLine || ADT.variant_show_inline(IOContext(io, :quote=>true), stmt)
        println(io)
    end
    return
end
