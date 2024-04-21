local vars = {
    API_SERVER = 16,
    WIRED_MODEM_SIDE = "back", -- this connects to the chest network/other cpus
    DEPOSIT_CHEST = "minecraft:chest_11", -- should be on left of inventory manager
    WITHDRAWAL_CHEST = "minecraft:chest_10", -- should be on right of inventory manager
    CRAFTING_CHEST = "minecraft:chest_16", -- should be in front of MacGyver the crafty turtle
    INVENTORY_MANAGER = "inventoryManager_1",
    CHEST_TYPES = {
        "minecraft:chest",
        "functionalstorage:spruce_1"
    }
}
vars.BLACKLIST = {
    vars.DEPOSIT_CHEST,
    vars.WITHDRAWAL_CHEST,
    vars.CRAFTING_CHEST,
    "minecraft:chest_30", -- wheat seed sower
    "minecraft:chest_31", -- tomato seed sower
    "minecraft:chest_32", -- onion sower
    "minecraft:chest_33" -- cabbage seed sower
}

return vars