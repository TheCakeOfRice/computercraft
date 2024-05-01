local vars = require("vars")

local funcs = {}

-- filter function
function funcs.ignoreNamedChests(name, _)
    for _, dirty in pairs(vars.BLACKLIST) do
        if name == dirty then
            return false
        end
    end
    return true
end

-- concatenates tables
function funcs.concat(t1, t2)
    for i=1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

-- gets all chests as a list of tables
function funcs.getChests()
    local chests = {}
    for _, type in pairs(vars.CHEST_TYPES) do
        chests = funcs.concat(chests, { peripheral.find(type, funcs.ignoreNamedChests) })
    end
    return chests
end

-- returns a table of name : count values
function funcs.getInventory()
    local inventory = {}
    local indexMap = {}
    local chests = funcs.getChests()
    for _, chest in ipairs(chests) do
        for slot, item in pairs(chest.list()) do
            if indexMap[item.name] then
                inventory[indexMap[item.name]].count = inventory[indexMap[item.name]].count + item.count
            else
                local modName = string.match(item.name, "(.+):")
                -- local displayName = string.match(item.name, ".+:(.+)")
                local displayName = chest.getItemDetail(slot).displayName
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
    local leftToMove = itemCount
    local chests = funcs.getChests()
    for _, chest in ipairs(chests) do
        if leftToMove > 0 then
            for slot, item in pairs(chest.list()) do
                if leftToMove > 0 then
                    if item.name == itemName then
                        -- print("Found "..tostring(item.count).." of "..item.name)
                        local numToMove = math.min(leftToMove, chest.getItemDetail(slot).maxCount, item.count)
                        local numMoved = chest.pushItems(vars.WITHDRAWAL_CHEST, slot, numToMove)
                        -- print("...Added "..tostring(numMoved).." to the withdraw chest")
                        leftToMove = leftToMove - numMoved
                    end
                end
            end
        end
    end
    if leftToMove <= 0 then
        return true
    else
        print("funcs.withdraw: Only withdrew " .. tostring(itemCount - leftToMove) .. " of " .. tostring(itemCount) .. " items.")
        return false
    end
end

-- returns bool
function funcs.sendToPlayer(itemName, itemCount)
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
        local numMoved = invMgr.addItemToPlayer("right", { name=itemName, count=itemCount })
        if numMoved == itemCount then
            return true
        else
            print("funcs.sendToPlayer: Only sent " .. tostring(numMoved) .. " of " .. tostring(itemCount) .. " items.")
            return false
        end
    end
end

-- returns bool
function funcs.export(target, itemName, itemCount, toSlot)
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
function funcs.deposit()
    depositChest = peripheral.wrap(vars.DEPOSIT_CHEST)
    local chests = funcs.getChests()
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
function funcs.depositLastRow()
    -- clear deposit chest first
    if funcs.deposit() then
        -- move items from player to deposit chest
        local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
        for _, item in pairs(invMgr.getItems()) do
            if item.slot >= 27 and item.slot <= 35 then
                invMgr.removeItemFromPlayer("left", { count=item.count, fromSlot=item.slot })
            end
        end
        -- deposit from deposit chest
        return funcs.deposit()
    else
        return false
    end
end

return funcs