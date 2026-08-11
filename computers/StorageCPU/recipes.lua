return {
    ["minecraft:spruce_planks"] = {
        id = "minecraft:spruce_planks/from_log",
        type = "shaped",
        output = { name = "minecraft:spruce_planks", count = 4 },
        ingredients = { ["minecraft:spruce_log"] = 1 },
        grid = {
            "minecraft:spruce_log", false, false,
            false, false, false,
            false, false, false,
        },
        capability = "crafting_turtle",
    },
    ["minecraft:chest"] = {
        id = "minecraft:chest",
        type = "shaped",
        output = { name = "minecraft:chest", count = 1 },
        ingredients = { ["minecraft:spruce_planks"] = 8 },
        grid = {
            "minecraft:spruce_planks", "minecraft:spruce_planks", "minecraft:spruce_planks",
            "minecraft:spruce_planks", false, "minecraft:spruce_planks",
            "minecraft:spruce_planks", "minecraft:spruce_planks", "minecraft:spruce_planks",
        },
        capability = "crafting_turtle",
    },
}
