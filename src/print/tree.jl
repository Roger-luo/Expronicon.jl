module Tree

module Multiline

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
    key::Symbol = :light_black
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
    print_child_annotation(node, child, key) = Multiline.print_child_annotation(p.io, node, child, key)

    children = Multiline.children(node)
    node_str = sprint(Multiline.print_node, node, context=IOContext(p.io))
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
            child, key = popfirst!(s)
        else
            child = popfirst!(s)
            key = nothing
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
            key_str = sprint(Multiline.print_child_annotation, node, child, key)
            print_child_annotation(node, child, key)
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
function print_child_annotation(io::IO, node, child, annotation)
    error("unimplemented print_child_key method for ($(typeof(node)), $(typeof(child)), $(typeof(annotation)))")
end

should_print_annotation(ch) = applicable(keys, ch)
should_print_annotation(::AbstractVector) = false
should_print_annotation(::Tuple) = false
should_print_annotation(::Base.Generator) = false

end # module Multiline


module Inline

Base.@kwdef mutable struct State
    depth::Int = 0
    precedence::Int = 0 # precedence of the parent expression
end

Base.@kwdef struct Color
    delimiter::Symbol = :light_black
    annotation_delim::Symbol = :light_black
    brackets::Vector{Symbol} = [:yellow, :green, :cyan, :red, :magenta, :blue]
end

struct Printer{IO_t <: IO}
    io::IO_t
    color::Color
    state::State
end

function Printer(io::IO; color::Color = Color())
    Printer(io, color, State())
end

function (p::Printer)(node)
    c = p.color
    print(xs...) = Base.print(p.io, xs...)
    printstyled(xs...;kw...) = Base.printstyled(p.io, xs...; kw...)
    print_node(node) = Inline.print_node(p.io, node)
    print_node_suffix(node) = Inline.print_node_suffix(p.io, node)
    print_child_annotation(node, child, annotation) = Inline.print_child_annotation(p.io, node, child, annotation)
    print_child_annotation_suffix(node, child, annotation) = Inline.print_child_annotation_suffix(p.io, node, child, annotation)

    function join(xs, delimiter, should_print_annotation = false)
        for (i, x) in enumerate(xs)
            if should_print_annotation
                child, annotation = x
                print_child_annotation(node, child, annotation)
                p(child)
                print_child_annotation_suffix(node, child, annotation)
            else
                p(x)
            end
            i < length(xs) && printstyled(delimiter; color = c.delimiter)
        end
    end

    function bracket(f, left, right)
        printstyled(left; color = c.brackets[p.state.depth%length(c.brackets) + 1]);
        p.state.depth += 1 
        f()
        p.state.depth -= 1
        printstyled(right; color = c.brackets[p.state.depth%length(c.brackets) + 1])
    end

    children = Inline.children(node)
    this_delim = delimiter(node)
    this_print_annotation = should_print_annotation(children)
    this_precedence = precedence(node)
    parent_precedence = p.state.precedence    

    if this_precedence <= parent_precedence
        bracket(node_bracket_left(node), node_bracket_right(node)) do
            print_node(node)
            p.state.precedence = this_precedence
            join(children, this_delim, this_print_annotation)
            p.state.precedence = parent_precedence
            print_node_suffix(node)
        end
    else
        print_node(node)
        p.state.precedence = this_precedence
        join(children, this_delim, this_print_annotation)
        p.state.precedence = parent_precedence
        print_node_suffix(node)
    end
    return
end

children(node) = error("unimplemented children method for $(typeof(node))")
print_node(io::IO, node) = error("unimplemented print_node method for $(typeof(node))")
print_node_suffix(io::IO, node) = return

print_child_annotation(io::IO, node, child, annotation) = error("unimplemented print_annotation_after method for ($(typeof(node)), $(typeof(child)), $(typeof(annotation)))")
print_child_annotation_suffix(io::IO, node, child, annotation) = return

precedence(node) = 1
delimiter(node) = ", "
node_bracket_left(node) = "("
node_bracket_right(node) = ")"

should_print_annotation(ch) = applicable(keys, ch)
should_print_annotation(::AbstractVector) = false
should_print_annotation(::Tuple) = false
should_print_annotation(::Base.Generator) = false

end # module Inline

end # module Tree
