local vars = {
    IPAD = 0,
    WIRED_MODEM_SIDE = "back", -- this connects to the chest network/other cpus
    ENDER_MODEM_SIDE = "right", -- wireless modem or ender modem
    DEPOSIT_CHEST = "minecraft:chest_11", -- should be on left of inventory manager
    WITHDRAWAL_CHEST = "minecraft:chest_10", -- should be on right of inventory manager
    CRAFTING_CHEST = "minecraft:chest_16", -- should be in front of MacGyver the crafty turtle
    INVENTORY_MANAGER = "inventoryManager_1",
    BLACKLIST = {
        DEPOSIT_CHEST,
        WITHDRAWAL_CHEST,
        CRAFTING_CHEST
    },
    CHEST_TYPES = {
        "minecraft:chest",
        "functionalstorage:spruce_1"
    }
}

return vars