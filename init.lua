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
        local ng = {}
        for k,v in pairs(ps[name].quests) do
            if m.quests[k] then
                setmetatable(v, {__index = m.quest_meta})
                ng[k] = v
            else
                minetest.log("warning", "Discarding obsolete quest for " .. name .. ": " .. k)
            end
        end
        ps[name].quests = ng
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

    superdesc_show = function(self, label)
        local text = label
        text = text .. "\n\n" .. m.quests[self.quest.name].shortdesc
        if self.longdesc then
            text = text .. "\n" .. self.longdesc
        end
        if self.superdesc then
            text = text .. "\n\n" .. self.superdesc
        end
        text = text .. "\n\nObjectives:\n"
        local objectives = {}
        for _,v in pairs(self.objectives) do
            table.insert(objectives, v)
        end
        table.sort(objectives, function(a, b)
            return (not a.complete) or a.description < b.description
        end)
        for _,v in ipairs(objectives) do
            text = text .. "\n - " .. v.description .. " [" .. (v.complete and "complete" or "incomplete").. "]"
        end
        minetest.after(0, minetest.show_formspec, self.quest.player, "simple_quests:superdesc", [[
            size[8, 8]
            textarea[0.1,0;7.9,7;;;]] .. minetest.formspec_escape(text) .. [[]
            button_exit[3.25,7;1.5,1;proceed;Proceed]
        ]])
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
    sq:superdesc_show("Quest begun:")

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
