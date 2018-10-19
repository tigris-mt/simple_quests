local m = simple_quests
local huds = {}

local function update(name)
    local player = minetest.get_player_by_name(name)
    if not player then
        return
    end

    local sorted = m.sort_quests(name, true)

    local text = "QUESTS"

    for _,v in ipairs(sorted) do
        if not v.state.done then
            if v.objective then
                local o = v.state.objectives[v.objective]
                if not o.complete then
                    text = text .. "\n -: " .. o.description .. " [" .. (o.complete and "complete" or "incomplete") .. "]"
                end
            elseif v.text then
                -- Pass
            else
                text = text .. "\n" .. m.quests[v.name].shortdesc
            end
        end
    end

    if huds[name] then
        player:hud_change(huds[name], "text", text)
    else
        huds[name] = player:hud_add{
            hud_elem_type = "text",
            position = {x = 1, y = 1},
            offset = {x = -32, y = -64},
            scale = {x = 1, y = 1},
            alignment = {x = -1, y = -1},
            text = text,
            number = 0xFFFFFF,
        }
    end
end

minetest.register_on_joinplayer(function(player)
    update(player:get_player_name())
end)

minetest.register_on_leaveplayer(function(player)
    huds[player:get_player_name()] = nil
end)

local old = m.change_callback
function m.change_callback(quest, player)
    update(player)
    return old(quest, player)
end
