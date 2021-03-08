
"""
    obtain_const_or_stmt(@nospecialize(x), ci::CodeInfo) -> (value/stmt, type)

Return the value or the statement of given object. If it's `SSAValue`
return the corresponding value or statement and its type. If the `CodeInfo`
is not inferred yet, type will be nothing.
"""
function obtain_const_or_stmt(@nospecialize(x), ci::CodeInfo)
    if x isa SSAValue
        stmt = ci.code[x.id]
        if ci.ssavaluetypes isa Int
            # CI is not inferenced yet
            return stmt, nothing
        else
            typ = ci.ssavaluetypes[x.id]
        end

        if typ isa Const
            return typ.val, typeof(typ.val)
        else
            return stmt, widenconst(typ)
        end
    elseif x isa QuoteNode
        return x.value, typeof(x.value)
    elseif x isa Const
        return x.val, typeof(x.val)
    elseif x isa GlobalRef
        if isdefined(x.mod, x.name) && isconst(x.mod, x.name)
            val = getfield(x.mod, x.name)
        else
            # TODO: move this to parsing time
            throw(UndefVarError(x.name))
        end

        return val, typeof(val)
    else
        # special value
        return x, typeof(x)
    end
end

"""
    obtain_const(x, ci::CodeInfo)

Return the corresponding constant value of `x`, when `x` is
a `SSAValue`, return the corresponding value of `x`. User should
make sure `x` is actually a constant, or the return value can be
a statement.
"""
obtain_const(@nospecialize(x), ci::CodeInfo) = obtain_const_or_stmt(x, ci)[1]

struct NewCodeInfo
    src::CodeInfo
    code::Vector{Any}
    nvariables::Int
    codelocs::Vector{Int32}
    newslots::Dict{Int,Symbol}
    slotnames::Vector{Symbol}
    changemap::Vector{Int}
    slotmap::Vector{Int}

    function NewCodeInfo(ci::CodeInfo, nargs::Int)
        code = []
        codelocs = Int32[]
        newslots = Dict{Int,Symbol}()
        slotnames = copy(ci.slotnames)
        changemap = fill(0, length(ci.code))
        slotmap = fill(0, length(ci.slotnames))
        new(ci, code, nargs + 1, codelocs, newslots, slotnames, changemap, slotmap)
    end
end

source_slot(ci::NewCodeInfo, i::Int) = Core.SlotNumber(i + ci.slotmap[i])

function slot(ci::NewCodeInfo, name::Symbol)
    return Core.SlotNumber(findfirst(isequal(name), ci.slotnames))
end

function insert_slot!(ci::NewCodeInfo, v::Int, slot::Symbol)
    ci.newslots[v] = slot
    insert!(ci.slotnames, v, slot)
    prev = length(filter(x -> x < v, keys(ci.newslots)))
    for k in v-prev:length(ci.slotmap)
        ci.slotmap[k] += 1
    end
    return ci
end

function push_stmt!(ci::NewCodeInfo, stmt, codeloc::Int32 = Int32(1))
    push!(ci.code, stmt)
    push!(ci.codelocs, codeloc)
    return ci
end

function insert_stmt!(ci::NewCodeInfo, v::Int, stmt)
    push_stmt!(ci, stmt, ci.src.codelocs[v])
    ci.changemap[v] += 1
    return NewSSAValue(length(ci.code))
end

function update_slots(e, slotmap)
    if e isa Core.SlotNumber
        return Core.SlotNumber(e.id + slotmap[e.id])
    elseif e isa Expr
        return Expr(e.head, map(x -> update_slots(x, slotmap), e.args)...)
    elseif e isa Core.NewvarNode
        return Core.NewvarNode(Core.SlotNumber(e.slot.id + slotmap[e.slot.id]))
    else
        return e
    end
end

function finish(ci::NewCodeInfo)
    Core.Compiler.renumber_ir_elements!(ci.code, ci.changemap)
    replace_new_ssavalue!(ci.code)
    new_ci = copy(ci.src)
    new_ci.code = ci.code
    new_ci.codelocs = ci.codelocs
    new_ci.slotnames = ci.slotnames
    new_ci.slotflags = [0x00 for _ in new_ci.slotnames]
    new_ci.inferred = false
    new_ci.inlineable = true
    new_ci.ssavaluetypes = length(ci.code)
    return new_ci
end

function _replace_new_ssavalue(e)
    if e isa NewSSAValue
        return SSAValue(e.id)
    elseif e isa Expr
        return Expr(e.head, map(_replace_new_ssavalue, e.args)...)
    elseif e isa Core.GotoIfNot
        cond = e.cond
        if cond isa NewSSAValue
            cond = SSAValue(cond.id)
        end
        return Core.GotoIfNot(cond, e.dest)
    elseif e isa Core.ReturnNode && isdefined(e, :val) && isa(e.val, NewSSAValue)
        return Core.ReturnNode(SSAValue(e.val.id))
    else
        return e
    end
end

function replace_new_ssavalue!(code::Vector)
    for idx in 1:length(code)
        code[idx] = _replace_new_ssavalue(code[idx])
    end
    return code
end
