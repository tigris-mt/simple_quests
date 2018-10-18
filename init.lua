local m = {}
simple_quests = m

local form = smartfs.create("simple_quests", function(state)
    state:size(8, 8)
end)

smartfs.add_to_inventory(form, "simple_quests.png", "Quests")

minetest.register_chatcommand("quests", {
    description = "Open your quest list",
    func = function(name)
        form:show(name)
    end,
})

