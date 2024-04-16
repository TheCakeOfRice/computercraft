local vars = require("vars")

-- filter function
function ignoreNamedChests(name, _)
    for _, dirty in pairs(vars.BLACKLIST) do
        if name == dirty then
            return false
        end
    end
    return true
end

-- concatenates tables
function concat(t1, t2)
    for i=1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

-- gets all chests as a list of tables
function getChests()
    local chests = {}
    for _, type in pairs(vars.CHEST_TYPES) do
        chests = concat(chests, { peripheral.find(type, ignoreNamedChests) })
    end
    return chests
end

-- returns a table of name : count values
function getInventory()
    local inventory = {}
    local indexMap = {}
    local chests = getChests()
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
local function withdraw(itemName, itemCount)
    local numMoved = 0 
    local leftToMove = itemCount
    local chests = getChests()
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
    if numMoved == itemCount then
        return true
    else
        print("funcs.withdraw: Only withdrew " .. tostring(numMoved) .. " of " .. tostring(itemCount) .. " items.")
        return false
    end
end

-- returns bool
function sendToPlayer(itemName, itemCount)
    -- move items to withdrawal chest
    if not withdraw(itemName, itemCount) then
        print("funcs.sendToPlayer: Failed withdrawing items!")
        return false
    end

    -- add items to player
    local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
    if not invMgr then
        print("funcs.sendToPlayer: Inventory manager could not be found!")
        return false
    else
        local numMoved = invMgr.addItemToPlayer("right", itemCount, nil, itemName)
        if numMoved == itemCount then
            return true
        else
            print("funcs.sendToPlayer: Only sent " .. tostring(numMoved) .. " of " .. tostring(itemCount) .. " items.")
            return false
        end
    end
end

-- returns bool
function export(target, itemName, itemCount, toSlot)
    -- move items to withdrawal chest
    if not withdraw(itemName, itemCount) then
        print("funcs.export: Failed withdrawing items!")
        return false
    end

    local numMoved = 0 
    local leftToMove = itemCount

    -- add items to target
    local wChest = peripheral.wrap(vars.WITHDRAWAL_CHEST)
    for slot, item in pairs(wChest.list()) do
        if leftToMove > 0 then
            if item.name == itemName then
                numMoved = numMoved + wChest.pushItems(target, slot, leftToMove, toSlot)
                leftToMove = leftToMove - numMoved
            end
        end
    end
    if numMoved == itemCount then
        return true
    else
        print("funcs.export: Only exported " .. tostring(numMoved) .. " of " .. tostring(itemCount) .. " items.")
        return false
    end
end

-- import from deposit chest, returns bool
function deposit()
    depositChest = peripheral.wrap(vars.DEPOSIT_CHEST)
    local chests = getChests()
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