"""
    @use <name>: <variant>
    @use <name>: <variant>, <variant>, ...
    @use <name>: *

Import the variant of a ADT into current namespace.

```julia
@use Message: Write
```

!!! tips
    This macro does not create a constant binding so that you can
    use it inside a function, if you wish to use this macro in the
    global scope, use `@const_use` instead.
"""
macro use(expr)
    esc(use_m(__module__, expr))
end

"""
    @const_use <name>: <variant>
    @const_use <name>: <variant>, <variant>, ...
    @const_use <name>: *

Import the variant of a ADT into current namespace.

```julia
@const_use Message: Write
```
"""
macro const_use(expr)
    esc(const_use_m(__module__, expr))
end

"""
    @export_use <name>: <variant>

Import the variant of a ADT into current namespace,
and export it.
    
```julia
@export_use Message: Write
```
"""
macro export_use(expr)
    esc(export_use_m(__module__, expr))
end

function variant_names_to_bind(mod::Module, expr::Expr)
    return @match expr begin
        :($(name::Symbol):*) => begin
            isdefined(mod, name) || throw(UndefVarError(name))
            (name, variant_typename.(
                variants(getproperty(mod, name))
            ))
        end
        :($(name::Symbol):$(variant::Symbol)) || :($(name::Symbol).$(variant::Symbol)) => (name, (variant, ))
        Expr(:tuple, :($(name::Symbol):$(variant::Symbol)), xs...) => (name, (variant, xs...))
        _ => throw(ArgumentError("expect @const_use <name>: <variant> or @const_use <name>: *"))
    end
end

function assert_defined(mod::Module, variants)
    for variant in variants
        isdefined(mod, variant) && error("cannot import $variant: it already exists")
    end
end

# NOTE: dont assert here because new variables are
#       expected to shadow the previous definition
function use_m(mod::Module, expr::Expr)
    name, variants = variant_names_to_bind(mod, expr)
    return expr_map(variants) do variant_name
        :($variant_name = $name.$variant_name)
    end
end

function const_use_m(mod::Module, expr::Expr)
    name, variants = variant_names_to_bind(mod, expr)
    assert_defined(mod, variants)
    return expr_map(variants) do variant_name
        :(const $variant_name = $name.$variant_name)
    end
end

function export_use_m(mod::Module, expr::Expr)
    name, variants = variant_names_to_bind(mod, expr)
    assert_defined(mod, variants)
    body = expr_map(variants) do variant_name
        quote
            export $variant_name
            const $variant_name = $name.$variant_name
        end
    end
    return quote
        export $name
        $body
    end
end
