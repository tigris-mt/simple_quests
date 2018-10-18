local m = simple_quests

local function focus(state)
    local qs = state.param.quest.state
    local def = m.quests[qs.quest.name]
    state:label(1, 0, "shortdesc", def.shortdesc .. (def.longdesc and (" | " .. def.longdesc) or ""))

    local objectives = {}
    for k,v in pairs(qs.objectives) do
        table.insert(objectives, v)
    end
    table.sort(objectives, function(a, b)
        return (not a.complete) or a.description < b.description
    end)

    local olist = state:listbox(3, 1, 5, 3, "olist", 0, false)
    olist:clearItems()
    for _,v in ipairs(objectives) do
        olist:addItem(v.description .. " [" .. (v.complete and "complete" or "active") .. "]")
    end
end

local qform = smartfs.create("qform", function(state)
    state:size(8, 4)
    focus(state)
    state:button(0, 0, 1, 1, "refresh", "Refresh"):onClick(function(self, state)
        state:show()
    end)
    state:button(0, 1, 1, 1, "back", "Back"):onClick(function(self, state)
        minetest.after(0, state.param.parent.show, state.param.parent, state.location.player)
    end)
end)

local function overview(state)
    state:listbox(1, 0, 6, 4, "qlist", 0, false):onDoubleClick(function(self, state, idx, name)
        minetest.after(0, qform.show, qform, state.location.player, {quest = state.simple_quests_quests[idx], parent = state.def})
    end)

    state.simple_quests_quests = {}

    local s = m.player_state(state.location.player)
    for k,qs in pairs(s.quests) do
        table.insert(state.simple_quests_quests, {name = k, state = qs})
    end

    table.sort(state.simple_quests_quests, function(a, b)
        return (not a.state.done) or a.shortdesc < b.shortdesc
    end)

    local qlist = state:get("qlist")
    qlist:clearItems()

    for _,quest in ipairs(state.simple_quests_quests) do
        local q = m.quests[quest.state.quest.name]
        qlist:addItem(q.shortdesc .. " [" .. (quest.state.done or "active") .. "]")
    end
end

local form = smartfs.create("simple_quests", function(state)
    state:size(8, 4)
    overview(state)
    state:button(0, 0, 1, 1, "refresh", "Refresh"):onClick(function(self, state)
        state:show()
    end)
end)

smartfs.add_to_inventory(form, "simple_quests.png", "Quests")

minetest.register_chatcommand("quests", {
    description = "Open your quest list",
    func = function(name)
        form:show(name)
    end,
})
