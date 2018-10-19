local m = simple_quests

local function update(state)
    state.simple_quests_quests = {}
    local staging = {}

    local s = m.player_state(state.location.player)
    for k,qs in pairs(s.quests) do
        table.insert(staging, {name = k, state = qs})
    end

    table.sort(staging, function(a, b)
        if not a.state.done and b.state.done then
            return true
        elseif a.state.done and not b.state.done then
            return false
        end
        return m.quests[a.name].shortdesc <= m.quests[b.name].shortdesc
    end)

    for _,v in ipairs(staging) do
        table.insert(state.simple_quests_quests, v)
        if v.name == state.simple_quests_selected then
            if v.state.longdesc then
                table.insert(state.simple_quests_quests, {name = v.name, state = v.state, text = v.state.longdesc})
            end

            local objectives = {}
            for k,_ in pairs(v.state.objectives) do
                table.insert(objectives, k)
            end
            table.sort(objectives, function(a, b)
                local a, b = v.state.objectives[a], v.state.objectives[b]
                if not a.complete and b.complete then
                    return true
                elseif a.complete and not b.complete then
                    return false
                end
                return a.description < b.description
            end)
            for _,ov in ipairs(objectives) do
                table.insert(state.simple_quests_quests, {name = v.name, state = v.state, objective = ov})
            end
        end
    end

    local qlist = state:get("qlist")
    qlist:clearItems()

    for _,quest in ipairs(state.simple_quests_quests) do
        local q = m.quests[quest.state.quest.name]
        if q then
            if quest.objective then
                local o = quest.state.objectives[quest.objective]
                qlist:addItem(" -Objective: " .. o.description .. " [" .. (o.complete and "complete" or "incomplete") .. "]")
            elseif quest.text then
                qlist:addItem(" -Info: " .. quest.text)
            else
                qlist:addItem(q.shortdesc .. " [" .. (quest.state.done or "active") .. "]")
            end
        end
    end
end

local form = smartfs.create("simple_quests", function(state)
    state:size(8, 4)
    local qlist = state:listbox(1, 0.25, 6, 4, "qlist", 0, false)
    qlist:onClick(function(self, state, idx, name)
        if state.simple_quests_quests[idx] then
            state.simple_quests_selected = state.simple_quests_quests[idx].name
        end
        update(state)
    end)
    qlist:onDoubleClick(function(self, state, idx, name)
        if state.simple_quests_quests[idx] then
            state.simple_quests_quests[idx].state:superdesc_show("Quest information:")
        end
    end)
    update(state)
    state:label(0, -0.25, "label", "Single tap on quest to expand; double for full description.")
    state:button(0, 0.25, 1, 1, "refresh", "Refresh"):onClick(function(self, state)
        update(state)
    end)
end)

smartfs.add_to_inventory(form, "simple_quests.png", "Quests")

minetest.register_chatcommand("quests", {
    description = "Open your quest list",
    func = function(name)
        form:show(name)
    end,
})
