function is_line_no(x)
    x isa LineNumberNode && return true
    x isa Expr && x.head == :line && return true
    return false
end

function split_body(body)
    return @match body begin
        Expr(:block, stmts...) => stmts
        _ => (body, )
    end
end

const expr_infix_wide = Set{Symbol}([
    :(=), :(+=), :(-=), :(*=), :(/=), :(\=), :(^=), :(&=), :(|=), :(÷=), :(%=), :(>>>=), :(>>=), :(<<=),
    :(.=), :(.+=), :(.-=), :(.*=), :(./=), :(.\=), :(.^=), :(.&=), :(.|=), :(.÷=), :(.%=), :(.>>>=), :(.>>=), :(.<<=),
    :(&&), :(||), :(<:), :($=), :(⊻=), :(>:), :(-->)])
