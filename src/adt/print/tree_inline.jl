module Inline

Base.@kwdef mutable struct State
    depth::Int = 0
    precedence::Int = 0 # precedence of the parent expression
end

Base.@kwdef struct Color
    delimiter::Symbol = :light_red
    brackets::Vector{Symbol} = [:yellow, :green, :cyan, :magenta, :light_gray, :default, :light_red]
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
    print_annotation(node, annotation) = Inline.print_annotation(p.io, node, annotation)
    print_annotation_suffix(node, annotation) = Inline.print_annotation_suffix(p.io, node, annotation)

    function join(xs, delimiter, should_print_annotation = false)
        for (i, x) in enumerate(xs)
            if should_print_annotation
                child, annotation = x
                print_annotation(node, annotation)
                p(child)
                print_annotation_suffix(node, annotation)
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

print_annotation(io::IO, node, annotation) = error("unimplemented print_annotation method for ($(typeof(node)), $(typeof(annotation)))")
print_annotation_suffix(io::IO, node, annotation) = return

precedence(node) = 1
delimiter(node) = ", "
node_bracket_left(node) = "("
node_bracket_right(node) = ")"

should_print_annotation(ch) = applicable(keys, ch)
should_print_annotation(::AbstractVector) = false
should_print_annotation(::Tuple) = false
should_print_annotation(::Base.Generator) = false

end # module Inline