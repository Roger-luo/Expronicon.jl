module CLI

using ..ZhanKai: Options, expand
using Configurations: from_toml
using Comonicon: @cast, @main
using TerminalLoggers: TerminalLogger

"""
Expand a project with ZhanKai.

# Args

- `path::String`: the path to the project to be expanded.
"""
@main function zhan(path::String = pwd())
    Base.with_logger(TerminalLogger()) do
        cd(dirname(Base.current_project(path))) do
            isfile("ZhanKai.toml") || error("expect ZhanKai.toml in current project")
            option = from_toml(Options, "ZhanKai.toml")
            m_sym = Symbol(option.project_name)
            m = Base.eval(Main, Expr(:toplevel, :(using $(m_sym);$(m_sym))))
            expand(m, option)
        end
    end # with_logger
end

end # module