local m = simple_quests

function m.sort_quests(player, selected)
    local ret = {}
    local staging = {}

    local s = m.player_state(player)
    for k,qs in pairs(s.quests) do
        table.insert(staging, {name = k, state = qs})
    end

    table.sort(staging, function(a, b)
        if a.state.done ~= b.state.done then
            return not a.state.done
        end
        return a.state.gametime > b.state.gametime
    end)

    for _,v in ipairs(staging) do
        table.insert(ret, v)
        if v.name == selected or selected == true then
            if v.state.longdesc then
                table.insert(ret, {name = v.name, state = v.state, text = v.state.longdesc})
            end

            local objectives = {}
            for k,_ in pairs(v.state.objectives) do
                table.insert(objectives, k)
            end
            table.sort(objectives, function(a, b)
                local a, b = v.state.objectives[a], v.state.objectives[b]
                if a.complete ~= b.complete then
                    return not a.complete
                end
                return a.gametime > b.gametime
            end)
            for _,ov in ipairs(objectives) do
                table.insert(ret, {name = v.name, state = v.state, objective = ov})
            end
        end
    end

    return ret
end

local function update(state)
    state.simple_quests_quests = {}
    state.simple_quests_quests = m.sort_quests(state.location.player, state.simple_quests_selected)

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
    state:size(8, 8)
    local qlist = state:listbox(1, 0.25, 6, 8, "qlist", 0, false)
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

smartfs.add_to_inventory(form, "simple_quests.png", "Quests", false)

minetest.register_chatcommand("quests", {
    description = "Open your quest list",
    func = function(name)
        form:show(name)
    end,
})
