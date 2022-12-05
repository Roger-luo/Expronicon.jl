Base.@kwdef mutable struct PrinterState
    indent::Int = 0
    level::Int = 0
    no_first_line_indent::Bool = false
    block::Bool = true
    quoted::Bool = false
end

function with(f, ps::PrinterState, name::Symbol, new)
    old = getfield(ps, name)
    setfield!(ps, name, new)
    f()
    setfield!(ps, name, old)
    return
end

struct Printer{IO_t <: IO}
    io::IO_t
    color::ColorScheme
    line::Bool
    always_begin_end::Bool # always print begin ... end
    state::PrinterState
end

function Printer(io::IO;
        indent::Int=get(io, :indent, 0),
        color::ColorScheme=Monokai256(),
        line::Bool=false,
        always_begin_end=false,
        root::Bool=true,
    )
    state = PrinterState(;indent, level = root ? 0 : 1)
    Printer(io, color, line, always_begin_end, state)
end

function (p::Printer)(ex)
    c = p.color
    inline = InlinePrinter(p.io, color=c, line=p.line)
    print(xs...) = Base.print(p.io, xs...)
    println(xs...) = Base.println(p.io, xs...)
    printstyled(xs...;kw...) = Base.printstyled(p.io, xs...; kw...)
    keyword(s) = printstyled(s, color=c.keyword)
    tab() = print(" " ^ p.state.indent)
    leading_tab() = p.state.no_first_line_indent || tab()

    function indent(f; size::Int=4, level::Int=1)
        with(p.state, :level, p.state.level + level) do
            with(f, p.state, :indent, p.state.indent + size)
        end
    end

    function print_stmts(stmts; leading_indent::Bool=true)
        first_line = true
        if !p.line
            stmts = filter(!is_line_no, stmts)
        end

        for (i, stmt) in enumerate(stmts)
            if !leading_indent && first_line
                first_line = false
            else
                tab()
            end

            no_first_line_indent() do
                p(stmt)
            end

            if i < length(stmts)
                println()
            end
        end
    end

    noblock(f) = with(f, p.state, :block, false)
    quoted(f) = with(f, p.state, :quoted, true)

    is_root() = p.state.level == 0
    no_first_line_indent(f) = with(f, p.state, :no_first_line_indent, true)

    function print_if(cond, body, otherwise = nothing)
        stmts = split_body(body)
        leading_tab(); keyword("if "); inline(cond); println()
        indent() do
            print_stmts(stmts)
        end
        isnothing(otherwise) || print_else(otherwise)
        println(); tab(); keyword("end")
    end

    function print_else(otherwise)
        println()
        Meta.isexpr(otherwise, :elseif) && return p(otherwise)

        tab(); keyword("else"); println()

        @match otherwise begin
            Expr(:block, stmts...) => indent() do
                print_stmts(stmts)
            end
            _ => indent() do
                tab(); no_first_line_indent() do
                    p(otherwise)
                end
            end
        end
    end

    function print_elseif(cond, body, line=nothing, otherwise=nothing)
        stmts = split_body(body)
        tab(); keyword("elseif ");
        isnothing(line) || (p.line && (inline(line); print(" ")))
        inline(cond); println()

        indent() do
            print_stmts(stmts)
        end
        isnothing(otherwise) || print_else(otherwise)
    end

    function print_function(head, call, body)
        stmts = split_body(body)
        leading_tab()
        keyword("$head "); inline(call); println()
        indent() do
            print_stmts(stmts)
        end
        println(); tab(); keyword("end")
    end

    function split_body(body)
        return @match body begin
            Expr(:block, stmts...) => stmts
            _ => (body, )
        end
    end

    function print_try(body)
        body == false && return
        stmts = split_body(body)
        leading_tab()
        keyword("try"); println()
        indent() do
            print_stmts(stmts)
        end
    end

    function print_catch(body, vars)
        body == false && return
        stmts = split_body(body)
        println(); tab(); keyword("catch");
        if vars != false
            print(" "); inline(vars)
        end
        println()
        indent() do
            print_stmts(stmts)
        end
    end

    function print_finally(body)
        body == false && return
        stmts = split_body(body)
        println(); tab(); keyword("finally"); println()
        indent() do
            print_stmts(stmts)
        end
    end



    @switch ex begin
        @case Expr(:block, stmts...)
            leading_tab()
            show_begin_end = p.always_begin_end ? true : !is_root()
            if show_begin_end
                p.state.quoted ? keyword("quote") : keyword("begin")
                println()
            end

            # NOTE: begin ... end does not add quote level
            indent(size = show_begin_end ? 4 : 0, level = 0) do
                print_stmts(stmts; leading_indent=show_begin_end)
            end
            show_begin_end && (println(); tab(); keyword("end"))
        @case Expr(:quote, Expr(:block, stmts...)) && if is_root() end
            leading_tab(); keyword("quote"); println()
            indent(size=4) do
                print_stmts(stmts)
            end
            println(); tab(); keyword("end")
        @case Expr(:quote, Expr(:block, stmts...))
            leading_tab(); keyword("quote"); println()
            indent(size=p.state.quoted ? 4 : 0) do
                p.state.quoted && (tab(); keyword("quote"); println())
                indent() do
                    quoted() do
                        print_stmts(stmts; leading_indent=!is_root())
                    end
                end
                p.state.quoted && (println(); tab(); keyword("end");)
            end
            println(); tab(); keyword("end")
        @case Expr(:quote, code)
            is_root() || (leading_tab(); keyword("quote"); println())
            indent(size=is_root() ? 0 : 4) do
                quoted() do
                    tab(); no_first_line_indent() do
                        p(code)
                    end
                end
            end
            is_root() || (println(); tab(); keyword("end"))
        @case Expr(:let, Expr(:block, args...), Expr(:block, stmts...))
            leading_tab()
            keyword("let "); inline(args...); println()
            indent() do
                print_stmts(stmts)
            end
            println(); keyword("end")
        @case Expr(:if, cond, body)
            print_if(cond, body)
        @case Expr(:if, cond, body, otherwise)
            print_if(cond, body, otherwise)

        @case Expr(:elseif,
                Expr(:block, line, cond),
                body,
            )
            print_elseif(cond, body, line)
        @case Expr(:elseif, cond, body)
            print_elseif(cond, body)

        @case Expr(:elseif,
                Expr(:block, line, cond),
                body,
                otherwise
            )
            print_elseif(cond, body, line, otherwise)
        @case Expr(:elseif, cond, body, otherwise)
            print_elseif(cond, body, nothing, otherwise)

        @case Expr(:for, iteration, body)
            leading_tab()
            keyword("for "); inline(iteration); println()
            stmts = split_body(body)
            indent() do
                print_stmts(stmts)
            end
            println(); tab(); keyword("end")

        @case Expr(:while, cond, body)
            leading_tab()
            keyword("while "); inline(cond); println()
            stmts = split_body(body)
            indent() do
                print_stmts(stmts)
            end
            println(); tab(); keyword("end")

        @case Expr(:(=), lhs, Expr(:block, line, Expr(:if, _...))) && if is_line_no(line) end
            leading_tab()
            inline(lhs); keyword(" = "); inline(line); p(ex.args[2])
        @case Expr(:(=), lhs, Expr(:block, line, rhs)) && if is_line_no(line) end
            leading_tab(); inline(ex)
        @case Expr(:(=), lhs, rhs)
            leading_tab()
            inline(lhs); print(" = "); p(rhs)

        @case Expr(:function, call, body)
            print_function(:function, call, body)
        @case Expr(:macro, call, body)
            print_function(:macro, call, body)

        @case Expr(:macrocall, &(GlobalRef(Core, Symbol("@doc"))), line, doc, code)
            leading_tab()
            p.line && (inline(line); println())
            printstyled("\"\"\"\n", color=c.string)
            for line in eachsplit(doc, '\n')
                tab()
                printstyled(line, color=c.string)
                println()
            end
            tab(); println("\"\"\"")
            tab(); no_first_line_indent() do
                p(code)
            end
        @case Expr(:macrocall, name::Symbol, line, args...)
            leading_tab()
            p.line && (inline(line); print(" "))
            printstyled(name, color=c.macrocall)
            p.state.level += 1
            foreach(args) do arg
                print(" ")
                p(arg)
            end

        @case Expr(:struct, ismutable, head, body)
            stmts = split_body(body)
            leading_tab()
            keyword(ismutable ? "mutable struct" : "struct"); print(" ")
            inline(head); println()
            indent(level=0) do
                print_stmts(stmts)
            end
            println(); tab(); keyword("end")

        @case Expr(:try, try_body, catch_vars, catch_body)
            print_try(try_body)
            print_catch(catch_body, catch_vars)
            println(); tab(); keyword("end")
        @case Expr(:try, try_body, catch_vars, catch_body, finally_body)
            print_try(try_body)
            print_catch(catch_body, catch_vars)
            print_finally(finally_body)
            println(); tab(); keyword("end")
        @case Expr(:try, try_body, catch_vars, catch_body, finally_body, else_body)
            print_try(try_body)
            print_catch(catch_body, catch_vars)
            stmts = split_body(else_body)
            println(); tab(); keyword("else"); println()
            indent() do
                print_stmts(stmts)
            end
            print_finally(finally_body)
            println(); tab(); keyword("end")
        @case Expr(:module, notbare, name, body)
            leading_tab()
            keyword(notbare ? "module " : "baremodule "); inline(name); println()
            stmts = split_body(body)
            indent() do
                print_stmts(stmts)
            end
            println(); tab(); keyword("end")

        @case Expr(:const, code)
            leading_tab()
            keyword("const "); p(code)

        @case _
            inline(ex)
    end
    return
end

print_expr(io::IO, ex; kw...) = Printer(io; kw...)(ex)
print_expr(ex; kw...) = print_expr(stdout, ex; kw...)
