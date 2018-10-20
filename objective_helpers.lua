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

-- Event registry.
m.ohelp.ereg = {
    dig = function(quest, func)
        minetest.register_on_dignode(function(pos, node, player)
            if player and player:is_player() then
                local name = player:get_player_name()
                local q = m.quest_active(quest, name)
                if q then
                    func(q, pos, node)
                end
            end
        end)
    end,

    place = function(quest, func)
        minetest.register_on_placenode(function(pos, node, player)
            if player and player:is_player() then
                local name = player:get_player_name()
                local q = m.quest_active(quest, name)
                if q then
                    func(q, pos, node)
                end
            end
        end)
    end,
}
