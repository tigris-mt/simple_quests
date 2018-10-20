local m = simple_quests
minetest.register_chatcommand("sq_give", {
    description = "Give yourself a quest.",
    params = "<quest>",
    privs = {quest_debug = true},
    func = function(name, quest)
        if not m.quests[quest] then
            minetest.chat_send_player(name, "Invalid quest name.")
            return
        end
        m.give(quest, name)
    end,
})

minetest.register_chatcommand("sq_oc", {
    description = "Set an objective as completed.",
    params = "<quest> <objective>",
    privs = {quest_debug = true},
    func = function(name, param)
        local quest, objective = param:match("(%S+)%s*(%S+)")
        if not m.quest_active(quest, name) then
            minetest.chat_send_player(name, "You don't have that active quest name.")
            return
        end
        local q = m.quest(quest, name)
        local function d(objective)
            if q.objectives[objective] and not q.objectives[objective].complete then
                q:objective_done(objective)
            end
        end
        -- Force all current objectives complete.
        if objective == "*" then
            local l = {}
            for objective in pairs(q.objectives) do
                table.insert(l, objective)
            end
            for _,objective in ipairs(l) do
                d(objective)
            end
        else
            d(objective)
        end
    end,
})

minetest.register_chatcommand("sq_done", {
    description = "Complete a quest.",
    params = "<quest>",
    privs = {quest_debug = true},
    func = function(name, quest)
        if not m.quest_active(quest, name) then
            minetest.chat_send_player(name, "You don't have that active quest name.")
            return
        end
        m.quest(quest, name):do_done("complete")
    end,
})
