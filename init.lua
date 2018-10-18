local m = {
    quests = {},
}
simple_quests = m

local storage = minetest.get_mod_storage()
local ps = {}
function m.player_state(name, set)
    if set then
        storage:set_string("player:" .. name, minetest.serialize(set))
    else
        ps[name] = ps[name] or minetest.deserialize(storage:get("player:" .. name)) or {
            quests = {},
        }
        for _,v in pairs(ps[name].quests) do
            setmetatable(v, {__index = m.quest_meta})
        end
        return ps[name]
    end
end

m.quest_meta = {
    set_step = function(self, step, param)
        self.internal.previous = self.step
        self.step = step

        self:save()
    end,

    do_step = function(self, param)
        local done = m.quests[self.quest.name].steps[self.step](self, self.internal.previous, param)
        if done then
            self:do_done(done)
        end

        self:save()
    end,

    do_done = function(self, reason)
        self.done = reason
        m.quests[self.quest.name].done(self, self.done)
        self:alert(self.done)
        self:save()
    end,

    save = function(self)
        m.player_state(self.quest.player, m.player_state(self.quest.player))
    end,

    alert = function(self, text)
        minetest.chat_send_player(self.quest.player, ("[Quest: %s] %s"):format(m.quests[self.quest.name].shortdesc, text))
    end,

    objective = function(self, name, initial)
        local o = initial or {}
        o.description = o.description or "?"
        o.desc_orig = o.desc_orig or o.description
        o.name = name
        o.complete = false
        self.objectives[name] = o

        self:alert("Objective acquired: " .. o.description)
        self:save()
    end,

    objective_done = function(self, name)
        local o = self.objectives[name]
        o.complete = true
        self:alert("Objective complete: " .. o.description)
        self:save()

        local have = false
        for k,v in pairs(self.objectives) do
            have = have or not v.complete
        end

        if not have then
            self:do_step()
        end
    end,
}

function m.quest(quest, name)
    return m.player_state(name).quests[quest]
end

function m.quest_active(quest, name, step)
    local q = m.quest(quest, name)
    if q and not q.done then
        return step and q.step or q
    end
end

function m.give(quest, name)
    local s = m.player_state(name)
    local sq = {
        quest = {
            name = quest,
            player = name,
        },
        done = false,
        internal = {},
        objectives = {},
    }
    s.quests[quest] = sq
    setmetatable(sq, {__index = m.quest_meta})
    local q = m.quests[quest]

    sq:alert("begun")

    q.init(sq)
    sq:set_step(sq.step)
    return sq
end

function m.register(name, def)
    def.shortdesc = def.shortdesc or ""
    def.init = def.init or function(state) end
    def.done = def.done or function(state, reason) end
    def.steps = def.steps or {}

    -- Default steps.
    def.steps.done = function()
        return "complete"
    end
    def.steps.fail = function()
        return "failed"
    end

    def.objectives = def.objectives or {}
    m.quests[name] = def
end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/" .. "ui.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/" .. "objective_helpers.lua")
