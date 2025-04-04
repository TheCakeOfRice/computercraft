local vars = {
    API_SERVER = 3,
    ENDER_MODEM_SIDE = "right",
    WIRED_MODEM_SIDE = "back", -- this connects to the chest network/other cpus
    MONITOR = "top",
    DEPOSIT_CHEST = "minecraft:chest_1", -- should be on left of inventory manager, if using
    WITHDRAWAL_CHEST = "minecraft:chest_0", -- should be on right of inventory manager, if using
    CRAFTING_CHEST = "minecraft:chest_16", -- should be in front of MacGyver the crafty turtle
    INVENTORY_MANAGER = "inventoryManager_0",
    CHEST_TYPES = {
        "minecraft:chest",
        "functionalstorage:spruce_1",
        "sophisticatedstorage:chest",
        "sophisticatedstorage:copper_chest",
        "sophisticatedstorage:iron_chest",
        "sophisticatedstorage:gold_chest",
        "sophisticatedstorage:diamond_chest",
        "sophisticatedstorage:netherite_chest"
    }
}
vars.BLACKLIST = {
    vars.DEPOSIT_CHEST,
    vars.WITHDRAWAL_CHEST,
    vars.CRAFTING_CHEST
}

return vars