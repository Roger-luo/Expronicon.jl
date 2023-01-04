function parse_file(src)
    raw = read(src, String)
    ex = Meta.parse("begin $raw end")
    ex = rm_nothing(ex)
    ex = rm_lineinfo(ex)
    return ex
end

function expand_macro(mod::Module, ex::Expr, options::Options)
    sub = Substitute() do expr
        # TODO: also check modules
        @match expr begin
            Expr(:macrocall, name, line, xs...) => begin
                if name isa GlobalRef
                    string(name.mod) in options.deps || return false
                    name = name.name
                elseif Meta.isexpr(name, :.)
                    string(name.args[1]) in options.deps || return false
                    name = name.args[2]
                    if name.args[2] isa QuoteNode
                        name = name.value
                    end
                end

                name_s = string(name)
                if startswith(name_s, "@")
                    return name_s[2:end] in options.macronames
                else
                    name_s in options.macronames
                end
            end
            _ => false
        end
    end

    ret = sub(ex) do expr
        macroexpand(mod, expr)
    end
    ret = rm_lineinfo(ret)
    ret = rm_nothing(ret)
    return ret
end

function expand_file(mod::Module, src, options::Options)
    ex = parse_file(src)
    ex = expand_macro(mod, ex, options)
    return ex
end
