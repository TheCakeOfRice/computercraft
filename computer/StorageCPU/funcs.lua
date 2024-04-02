os.loadAPI("vars.lua")

-- filter function
function ignoreNamedChests(name, _)
    if name == vars.DEPOSIT_CHEST or name == vars.WITHDRAWAL_CHEST then
        return false
    else
        return true
    end
end

-- returns a table of name : count values
function getInventory()
    local inventory = {}
    local indexMap = {}
    local chests = { peripheral.find("minecraft:chest", ignoreNamedChests), peripheral.find("functionalstorage:spruce_1") }
    for _, chest in ipairs(chests) do
        for _, item in pairs(chest.list()) do
            if indexMap[item.name] then
                inventory[indexMap[item.name]].count = inventory[indexMap[item.name]].count + item.count
            else
                local modName = string.match(item.name, "(.+):")
                local displayName = string.match(item.name, ".+:(.+)")
                inventory[#inventory + 1] = { name=item.name, count=item.count, mod=modName, displayName=displayName }
                indexMap[item.name] = #inventory
            end
        end
    end

    -- sort by count
    table.sort(inventory, function (item1, item2) return item1.count > item2.count end )
    return inventory
end

-- returns bool
function sendToPlayer(itemName, itemCount)
    -- move items to withdrawal chest
    local numMoved = 0 
    local leftToMove = itemCount
    local chests = { peripheral.find("minecraft:chest", ignoreNamedChests), peripheral.find("functionalstorage:spruce_1") }
    for _, chest in ipairs(chests) do
        if leftToMove > 0 then
            for slot, item in pairs(chest.list()) do
                if leftToMove > 0 then
                    if item.name == itemName then
                        numMoved = numMoved + chest.pushItems(vars.WITHDRAWAL_CHEST, slot, leftToMove)
                        leftToMove = leftToMove - numMoved
                    end
                end
            end
        end
    end
    -- add items to player
    local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
    if not invMgr then
        return false
    else
        return invMgr.addItemToPlayer("right", itemCount, nil, itemName) == itemCount
    end
end

-- import from deposit chest, returns bool
function deposit()
    depositChest = peripheral.wrap(vars.DEPOSIT_CHEST)
    local chests = { peripheral.find("minecraft:chest", ignoreNamedChests), peripheral.find("functionalstorage:spruce_1") }
    for slot, item in pairs(depositChest.list()) do
        local numMoved = 0 
        local leftToMove = item.count
        for _, chest in ipairs(chests) do
            if leftToMove > 0 then
                numMoved = numMoved + depositChest.pushItems(peripheral.getName(chest), slot, leftToMove)
                leftToMove = leftToMove - numMoved
            end
        end
        if leftToMove > 0 then
            print("Inventory is full!")
            return false
        end
    end
    return true
end

-- returns bool
function depositLastRow()
    -- clear deposit chest first
    if deposit() then
        -- move items from player to deposit chest
        local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
        for _, item in pairs(invMgr.getItems()) do
            if item.slot >= 27 and item.slot <= 35 then
                invMgr.removeItemFromPlayerNBT("left", item.count, nil, { fromSlot=item.slot })
            end
        end
        -- deposit from deposit chest
        return deposit()
    else
        return false
    end
end