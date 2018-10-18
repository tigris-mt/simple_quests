local m = simple_quests
m.ohelp = {}

m.ohelp.count = {
    init = function(o)
        o.count = 0
        o.desc_orig = o.description
        o.description = o.description .. (" (%d/%d)"):format(o.count, o.max_count)
        return o
    end,

    add = function(state, name, add)
        local o = state.objectives[name]
        o.count = o.count + add
        o.description = o.desc_orig .. (" (%d/%d)"):format(o.count, o.max_count)
        state:save()
        if o.count >= o.max_count then
            state:objective_done(name)
        end
    end,
}
