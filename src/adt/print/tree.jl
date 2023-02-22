module Tree

# this is adapted from AbstractTree since
# we need the printing frequently but it kept
# having issues with our case.

struct CharSet
    mid::String
    terminator::String
    skip::String
    dash::String
    trunc::String
    pair::String
end

function CharSet(name::Symbol=:unicode)
    if name == :unicode
        CharSet("├", "└", "│", "─", "⋮", " ⇒ ")
    elseif name == :ascii
        CharSet("+", "\\", "|", "--", "...", " => ")
    else
        throw(ArgumentError("unrecognized dfeault CharSet name: $name"))
    end
end

Base.@kwdef struct Color
    annotation::Symbol = :light_black
end

Base.@kwdef mutable struct State
    depth::Int = 0
    prefix::String = ""
    last::Bool = false
end

struct Printer{IO_t}
    io::IO_t
    charset::CharSet
    max_depth::Int
    color::Color
    state::State
end

function Printer(io::IO_t;
        charset::CharSet = CharSet(:unicode),
        max_depth::Int = 5,
        color::Color = Color(),
        state = State()) where {IO_t}
    return Printer{IO_t}(io, charset, max_depth, color, state)
end

function (p::Printer)(node)
    print(xs...) = Base.print(p.io, xs...)
    println(xs...) = Base.println(p.io, xs...)
    printstyled(xs...; kw...) = Base.printstyled(p.io, xs...; kw...)
    print_annotation(node, annotation) = Tree.print_annotation(p.io, node, annotation; color = p.color.annotation)

    children = Tree.children(node)
    node_str = sprint(Tree.print_node, node, context=IOContext(p.io))
    for (i, line) in enumerate(split(node_str, '\n'))
        i ≠ 1 && print(prefix)
        print(line)
        if !(p.state.last && isempty(children))
            println()
        end
    end

    if p.state.depth > p.max_depth
        println(p.charset.trunc)
        return
    end

    this_print_annotation = should_print_annotation(children)

    s = Iterators.Stateful(
        this_print_annotation ? pairs(children) : children
    )
    while !isempty(s)
        child_prefix = p.state.prefix
        if this_print_annotation
            child, annotation = popfirst!(s)
        else
            child = popfirst!(s)
            annotation = nothing
        end

        print(p.state.prefix)

        if isempty(s)
            print(p.charset.terminator)
            child_prefix *= " " ^ (
                textwidth(p.charset.skip) +
                textwidth(p.charset.dash) + 1
            )

            if p.state.depth > 0 && p.state.last
                is_last_leaf_child = true
            elseif p.state.depth == 0
                is_last_leaf_child = true
            else
                is_last_leaf_child = false
            end
        else
            print(p.charset.mid)
            child_prefix *= p.charset.skip * " " ^ (
                textwidth(p.charset.dash) + 1
            )
            is_last_leaf_child = false
        end

        print(p.charset.dash, ' ')

        if this_print_annotation
            key_str = sprint(Tree.print_annotation, node, annotation)
            print_annotation(node, annotation)
            print(p.charset.pair)

            child_prefix *= " " ^ (
                textwidth(key_str) + textwidth(p.charset.pair)
            )
        end

        p.state.depth += 1
        parent_last = p.state.last
        p.state.last = is_last_leaf_child
        parent_prefix = p.state.prefix
        p.state.prefix = child_prefix
        p(child)
        p.state.depth -= 1
        p.state.prefix = parent_prefix
        p.state.last = parent_last
    end
end

function children(node)
    error("unimplemented children method for $(typeof(node))")
end
function print_node(io::IO, node)
    error("unimplemented print_node method for $(typeof(node))")
end    
function print_annotation(io::IO, node, annotation; kwargs...)
    printstyled(io, annotation; kwargs...)
end

should_print_annotation(ch) = applicable(keys, ch)
should_print_annotation(::AbstractVector) = false
should_print_annotation(::Tuple) = false
should_print_annotation(::Base.Generator) = false

include("tree_inline.jl")

end # module Tree
