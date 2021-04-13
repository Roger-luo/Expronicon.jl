const INDENT=4

"julia Expr printing color schema"
module Color
using Crayons.Box

kw(x) = LIGHT_MAGENTA_FG(Base.string(x))
fn(x) = LIGHT_BLUE_FG(Base.string(x))
line(x) = DARK_GRAY_FG(Base.string(x))
literal(x) = YELLOW_FG(Base.string(x))
type(x) = LIGHT_GREEN_FG(Base.string(x))
string(x::String) = Box.CYAN_FG(x)
string(x) = Box.CYAN_FG(Base.string(x))

end

no_indent(io::IO) = IOContext(io, :indent=>0)
no_indent_first_line(io::IO) = IOContext(io, :no_indent_first_line=>true)

# 1.0 compatibility
function indent_print(io::IO, ::Nothing)
    indent = get(io, :indent, 0)
    tab = get(io, :tab, " ")
    print(io, tab^indent, "nothing")
end

function indent_print(io::IO, xs...)
    indent = get(io, :indent, 0)
    tab = get(io, :tab, " ")
    Base.print(io, tab^indent, xs...)
end

function indent_println(io::IO, xs...)
    if get(io, :no_indent_first_line, false)
        indent_print(no_indent(io), xs..., "\n")
    else
        indent_print(io, xs..., "\n")
    end
end

function within_line(f, io)
    indent_print(io)
    f(no_indent(io))
end

function within_indent(f, io)
    f(indent(io))
end

function indent(io)
    IOContext(io, :indent => get(io, :indent, 0) + INDENT)
end

"""
    with_marks(f, io, lhs, rhs)

Print using `f` with marks specified on LHS and RHS by `lhs` and `rhs`.
See also [`with_parathesis`](@ref), [`with_curly`](@ref), [`with_brackets`](@ref),
[`with_begin_end`](@ref).
"""
function with_marks(f, io::IO, lhs, rhs)
    indent_print(io, lhs)
    f()
    indent_print(io, rhs)
end

"""
    with_parathesis(f, io::IO)

Print with parathesis. See also [`with_marks`](@ref),
[`with_curly`](@ref), [`with_brackets`](@ref),
[`with_begin_end`](@ref).

# Example

```julia
julia> with_parathesis(stdout) do
        print(1, ", ", 2)
    end
(1, 2)
```
"""
with_parathesis(f, io::IO) = with_marks(f, io, "(", ")")

"""
    with_curly(f, io::IO)

Print with curly parathesis. See also [`with_marks`](@ref), [`with_parathesis`](@ref),
[`with_brackets`](@ref), [`with_begin_end`](@ref).
"""
with_curly(f, io::IO) = with_marks(f, io, "{", "}")

"""
    with_brackets(f, io::IO)

Print with brackets. See also [`with_marks`](@ref), [`with_parathesis`](@ref),
[`with_curly`](@ref), [`with_begin_end`](@ref).
"""
with_brackets(f, io::IO) = with_marks(f, io, "[", "]")

"""
    with_triple_quotes(f, io::IO)

Print with triple quotes.
"""
with_triple_quotes(f, io::IO) = with_marks(f, io, Color.string("\"\"\"\n"), Color.string("\"\"\""))

"""
    with_double_quotes(f, io::IO)

Print with double quotes.
"""
with_double_quotes(f, io::IO) = with_marks(f, io, Color.string("\""), Color.string("\""))

"""
    with_begin_end(f, io::IO)

Print with begin ... end. See also [`with_marks`](@ref), [`with_parathesis`](@ref),
[`with_curly`](@ref), [`with_brackets`](@ref).
"""
with_begin_end(f, io::IO) = with_marks(f, io, "begin", "end")

"""
    print_collection(io, xs; delim=",")

Print a collection `xs` with deliminator `delim`, default is `","`.
"""
function print_collection(io, xs; delim=", ")
    for i in 1:length(xs)
        print_ast(io, xs[i])
        if i !== length(xs)
            indent_print(io, delim)
        end
    end
end

"""
    print_ast(io::IO, xs...)

Print Julia AST. This is a custom implementation of
`Base.show(io, ::Expr)`.
"""
function print_ast(io::IO, xs...)
    foreach(xs) do x
        print_ast(io, x)
    end
end



function print_ast(io::IO, ex)
    tab = get(io, :tab, " ")
    first_line_io = get(io, :no_indent_first_line, false) ? no_indent(io) : io
    @match ex begin
        ::Union{Number} => indent_print(first_line_io, Color.literal(ex))
        ::String => indent_print(first_line_io, Color.string(repr(ex)))
        ::Symbol => indent_print(first_line_io, ex)

        Expr(:tuple, xs...) => begin
            with_parathesis(io) do 
                print_collection(no_indent(io), xs)
            end
        end

        Expr(:(::), name, type) => begin
            within_line(io) do io
                print_ast(io, name)
                indent_print(io, "::")
                print_ast(io, Color.type(type))
            end
        end

        Expr(:kw, name, value) => begin
            within_line(io) do io
                print_ast(io, name)
                indent_print(io, tab, "=", tab)
                print_ast(io, value)
            end
        end

        Expr(:(=), l, r) => begin
            print_ast(io, l)
            print(io, tab, Color.kw("="), tab)
            print_ast(no_indent_first_line(io), r)
        end

        Expr(:call, name, args...) => begin
            if !get(io, :no_indent_first_line, false)
                indent_print(io)
            end
            if name in [:+, :-, :*, :/, :\, :(===), :(==), :(:)]
                print_collection(no_indent(io), args; delim=Color.fn(string(tab, name, tab)))
            else
                indent_print(no_indent(io), Color.fn(name))
                with_parathesis(no_indent(io)) do
                    print_collection(no_indent(io), args)
                end    
            end
        end

        Expr(:block, stmts...) => begin
            indent_println(io, Color.kw("begin"))
            io = IOContext(io, :no_indent_first_line=>false)
            within_indent(io) do io
                for i in 1:length(stmts)
                    print_ast(io, stmts[i])
                    indent_println(io)
                end
            end
            indent_print(io, Color.kw("end"))
        end

        Expr(:let, vars, body) => begin
            if get(io, :no_indent_first_line, false)
                print(io, Color.kw("let"))
            else
                indent_print(io, Color.kw("let"))
            end

            isempty(vars.args) || print_collection(no_indent(io), vars.args)
            println(io)
            io = IOContext(io, :no_indent_first_line=>false)
            within_indent(io) do io
                if body isa Expr && body.head === :block
                    stmts = body.args
                    for i in 1:length(stmts)
                        print_ast(io, stmts[i])
                        indent_println(io)
                    end
                else
                    print_ast(io, body)
                    println(io)
                end
            end
            indent_print(io, Color.kw("end"))
        end

        Expr(:return, xs...) => begin
            within_line(io) do io
                print_ast(io, Color.kw("return"))
                indent_print(io, tab)
                print_ast(io, xs...)
            end
        end

        Expr(:if, xs...) => begin
            print_ast(io, JLIfElse(ex))
        end

        ::LineNumberNode => indent_print(io, Color.line(ex))
        # fallback to default printing
        _ => begin
            if get(io, :no_indent_first_line, false)
                print(io, ex)
            else
                indent_print(io, ex)
            end
        end
    end
end

function print_ast(io::IO, def::JLFor)
    def.kernel === nothing && return
    tab = get(io, :tab, " ")
    indent_print(io, Color.kw("for"), tab)

    within_indent(io) do io
        for i in 1:length(def.vars)
            print_ast(i==1 ? no_indent(io) : io, def.vars[i])
            print(io, tab, Color.kw("in"), tab)
            print_ast(no_indent(io), def.iterators[i])
            i < length(def.vars) && print(io, ",")
            println(io)
        end
        indent_println(io, Color.line("#= loop body =#"))
        print_ast(io, def.kernel)
        println(io)
    end

    indent_print(io, Color.kw("end"))
end

function print_ast(io::IO, def::JLIfElse)
    isempty(def.map) && return print_ast(io, def.otherwise)
    tab = get(io, :tab, " ")
    indent_print(io, Color.kw("if"), tab)
    for (k, (cond, action)) in enumerate(def.map)
        print_ast(no_indent(io), cond)
        indent_println(io)
        print_ast(indent(io), action)
        indent_println(io)

        if k !== length(def.map)
            indent_print(io, Color.kw("elseif"), tab)
        end
    end
    if def.otherwise !== nothing
        indent_print(io, Color.kw("else"), "\n")
        print_ast(indent(io), def.otherwise)
        indent_println(io)
    end
    indent_print(io, Color.kw("end"))
end

function print_ast(io::IO, def::JLFunction)
    tab = get(io, :tab, " ")
    within_line(io) do io
        def.head === :function && indent_print(io, Color.kw("function"), tab)
        # print calls
        def.name === nothing || indent_print(io, Color.fn(def.name))
        with_parathesis(io) do
            print_collection(io, def.args)
            if def.kwargs !== nothing
                indent_print(io, "; ")
                print_collection(io, def.kwargs)
            end
        end

        if def.rettype !== nothing
            print(io, "::", Color.type(def.rettype))
        end

        if def.whereparams !== nothing
            indent_print(io, tab, Color.kw("where"), tab)
            with_curly(io) do
                print_collection(io, def.whereparams)    
            end
        end

        def.head === :(=) && indent_print(io, tab, "=", tab)
        def.head === :(->) && indent_print(io, tab, "->", tab)
    end

    # print body
    if def.head === :function
        println(io)
        within_indent(io) do io
            @match def.body begin
                Expr(:block, stmts...) => begin
                    for i in 1:length(stmts)
                        print_ast(io, stmts[i])
                        indent_println(io)
                    end
                end

                _ => begin
                    print_ast(io, def.body)
                    println(io)
                end
            end
        end
        indent_print(io, Color.kw("end"))
    else
        print_ast(no_indent_first_line(io), def.body)
    end
end

function print_ast(io::IO, def::JLStruct)
    print_ast_struct(io, def)
end

function print_ast(io::IO, def::JLKwStruct)
    print_ast_struct(io, def)
end

function print_ast(io::IO, def::JLField)
    print_ast_struct_field(io, def)
end

function print_ast(io::IO, def::JLKwField)
    print_ast_struct_field(io, def)
    def.default === no_default || indent_print(no_indent(io), " = ", def.default)
end

function print_ast_doc(io::IO, def)
    def.doc === nothing && return
    doc = def.doc
    with_triple_quotes(io) do
        indent_print(io, Color.string(doc))
    end
    indent_println(io)
end

function print_ast_struct(io::IO, def)
    def.line === nothing || indent_println(io, Color.line(def.line))
    print_ast_doc(io, def)
    print_ast_struct_head(io, def)
    for each in def.fields
        indent_println(no_indent(io))
        print_ast(indent(io), each)
    end
    indent_println(no_indent(io))

    for each in def.constructors
        print_ast(indent(io), each)
        indent_println(io)
    end

    indent_print(io, Color.kw("end"))
end

function print_ast_struct_field(io::IO, def)
    def.line === nothing || indent_println(io, Color.line(def.line))
    if def.doc !== nothing
        indent_print(io)
        with_double_quotes(no_indent(io)) do
            indent_print(no_indent(io), Color.string(def.doc))
        end
        indent_println(io)
    end
    indent_print(io, def.name)
    def.type === Any || indent_print(no_indent(io), "::", Color.type(def.type))
end

function print_ast_struct_head(io::IO, def)
    tab = get(io, :tab, " ")
    # make sure there is only one indent in the same line 
    printed_indent = false
    if def isa JLKwStruct
        indent_print(io, Color.line("#= kw =#"), tab)
        printed_indent = true
    end

    if def.ismutable
        indent_print(printed_indent ? no_indent(io) : io, Color.kw("mutable"), tab)
    end

    indent_print(printed_indent ? no_indent(io) : io, Color.kw("struct"))
    indent_print(io, tab, def.name)

    isempty(def.typevars) || with_curly(no_indent(io)) do
        print_collection(no_indent(io), def.typevars)
    end

    if def.supertype !== nothing
        indent_print(no_indent(io), tab, "<:", tab, Color.type(def.supertype))
    end
end

print_ast(::IO, def::JLExpr) = error("Printings.print_ast is not defined for $(typeof(def))")
Base.show(io::IO, def::JLExpr) = print_ast(io, def)
