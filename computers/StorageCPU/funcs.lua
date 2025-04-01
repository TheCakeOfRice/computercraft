local vars = require("vars")

-- #######
-- Globals
-- #######

local funcs = {}
funcs.chests = {}       -- list of all chest peripherals, after blacklist
funcs.inventory = {}    -- dictionary of items in inventory
funcs.openSlots = {}    -- dictionary of chests : [ free slots ]

-- #######
-- Dependency funcs for startup
-- #######

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

local function append(tbl, val)
    tbl[#tbl + 1] = val
    return tbl
end

-- #######
-- Startup
-- #######

-- build chest list (requires restart to detect new chests)
print("Building chest list...")
for _, type in pairs(vars.CHEST_TYPES) do
    funcs.chests = funcs.concat(funcs.chests, { peripheral.find(type, funcs.ignoreNamedChests) })
end
print("Found " .. tostring(#funcs.chests) .. " storage chests.")

-- build inventory, note open slots
print("Building inventory cache...")
for _, chest in ipairs(funcs.chests) do
    local chestName = peripheral.getName(chest)
    print("...searching "..chestName)
    funcs.openSlots[chestName] = {}

    for slot=1, chest.size() do
        local item = chest.getItemDetail(slot)

        -- slot is empty
        if item == nil then
            append(funcs.openSlots[chestName], slot)

        else
            -- item has already been observed
            if funcs.inventory[item.name] then
                funcs.inventory[item.name].count = funcs.inventory[item.name].count + item.count
                
                -- item has already been observed in this chest
                if funcs.inventory[item.name].locatedAt[chestName] then
                    append(funcs.inventory[item.name].locatedAt[chestName], slot)
                
                -- item has not been observed in this chest
                else
                    funcs.inventory[item.name].locatedAt[chestName] = { slot }
                end
            
            -- first observation of item
            else
                local modName = string.match(item.name, "(.+):")
                local displayName = item.displayName
                funcs.inventory[item.name] = {
                    name = item.name,
                    count = item.count,
                    mod = modName,
                    displayName = displayName,
                    locatedAt = { [chestName] = { slot } }
                }
            end
        end
    end
end

-- #######
-- Core functions
-- #######

-- moves an item from inventory to the withdrawal chest, returns bool if successful
function funcs.withdraw(target, itemName, itemCount, toSlot)
    target = target or vars.WITHDRAWAL_CHEST

    -- sanity check
    if not funcs.inventory[itemName] then
        print("Tried to withdraw "..itemName.." but it doesn't exist in inventory!")
        return false
    end

    local leftToMove = itemCount
    for _, chestName in ipairs(funcs.inventory[itemName].locatedAt) do
        local chest = peripheral.wrap(chestName)
        if leftToMove > 0 then
            for i, slot in ipairs(funcs.inventory[itemName].locatedAt[chestName]) do
                if leftToMove > 0 then
                    local itemAtSlot = chest.getItemDetail(slot)
                    local numToMove = math.min(leftToMove, itemAtSlot.maxCount, itemAtSlot.count)
                    local wasSlotCleared = (numToMove == itemAtSlot.count)

                    local numMoved = chest.pushItems(target, slot, numToMove, toSlot)

                    leftToMove = leftToMove - numMoved

                    -- update inventory with change
                    funcs.inventory[itemName].count = funcs.inventory[itemName].count - numMoved

                    -- add slot to open slot list if it was freed up
                    if wasSlotCleared then
                        funcs.inventory[itemName].locatedAt[chestName][i] = nil
                        append(funcs.openSlots[chestName], slot)
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

-- import from deposit chest, returns bool
function funcs.deposit()
    depositChest = peripheral.wrap(vars.DEPOSIT_CHEST)

    -- loop through deposit chest items
    for fromSlot, _ in pairs(depositChest.list()) do
        local item = depositChest.getItemDetail(fromSlot)
        local numMoved = 0
        local leftToMove = item.count

        -- create item entry if it doesn't exist
        if not funcs.inventory[item.name] then
            local modName = string.match(item.name, "(.+):")
            local displayName = item.displayName
            funcs.inventory[item.name] = {
                name = item.name,
                count = 0,
                mod = modName,
                displayName = displayName,
                locatedAt = {}
            }
        end

        -- find an empty slot and push items there
        for _, chestName in ipairs(funcs.openSlots) do
            if leftToMove > 0 then
                for i, toSlot in ipairs(funcs.openSlots[chestName]) do
                    if leftToMove > 0 then
                        numMoved = numMoved + depositChest.pushItems(chestName, fromSlot, leftToMove, toSlot)

                        leftToMove = leftToMove - numMoved

                        -- update inventory with change
                        funcs.inventory[item.name].count = funcs.inventory[itemName].count + numMoved
                        if not funcs.inventory[item.name].locatedAt[chestName] then
                            funcs.inventory[item.name].locatedAt[chestName] = { toSlot }
                        else
                            append(funcs.inventory[item.name].locatedAt[chestName], toSlot)
                        end

                        -- remove toSlot from open slots list if able
                        if numMoved > 0 then
                            funcs.openSlots[chestName][i] = nil
                        end
                    end
                end
            end
        end

        -- couldn't find enough open slots to finish
        if leftToMove > 0 then
            print("Inventory is full!")
            return false
        end
    end

    return true
end

-- DEPRECATED -- duplicate functionality with withdraw
-- -- returns bool
-- function funcs.export(target, itemName, itemCount, toSlot)
--     -- move items to withdrawal chest
--     if not withdraw(itemName, itemCount, vars.EXPORT_CHEST) then
--         print("funcs.export: Failed withdrawing items!")
--         return false
--     end

--     local numMoved = 0 
--     local leftToMove = itemCount

--     -- add items to target
--     local exportChest = peripheral.wrap(vars.EXPORT_CHEST)
--     for slot, item in pairs(exportChest.list()) do
--         if leftToMove > 0 then
--             if item.name == itemName then
--                 numMoved = numMoved + exportChest.pushItems(target, slot, leftToMove, toSlot)
--                 leftToMove = leftToMove - numMoved
--             end
--         end
--     end
--     if numMoved == itemCount then
--         return true
--     else
--         print("funcs.export: Only exported " .. tostring(numMoved) .. " of " .. tostring(itemCount) .. " items.")
--         return false
--     end
-- end

-- DEPRECATED -- for use with Advanced Peripherals mod
-- -- returns bool
-- function funcs.depositLastRow()
--     -- clear deposit chest first
--     if funcs.deposit() then
--         -- move items from player to deposit chest
--         local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
--         for _, item in pairs(invMgr.getItems()) do
--             if item.slot >= 27 and item.slot <= 35 then
--                 invMgr.removeItemFromPlayer("left", { count=item.count, fromSlot=item.slot })
--             end
--         end
--         -- deposit from deposit chest
--         return funcs.deposit()
--     else
--         return false
--     end
-- end

-- DEPRECATED -- for use with Advanced Peripherals mod
-- -- returns bool
-- function funcs.sendToPlayer(itemName, itemCount)
--     -- move items to withdrawal chest
--     if not withdraw(itemName, itemCount) then
--         print("funcs.sendToPlayer: Failed withdrawing items!")
--         return false
--     end

--     -- add items to player
--     local invMgr = peripheral.wrap(vars.INVENTORY_MANAGER)
--     if not invMgr then
--         print("funcs.sendToPlayer: Inventory manager could not be found!")
--         return false
--     else
--         local numMoved = invMgr.addItemToPlayer("right", { name=itemName, count=itemCount })
--         if numMoved == itemCount then
--             return true
--         else
--             print("funcs.sendToPlayer: Only sent " .. tostring(numMoved) .. " of " .. tostring(itemCount) .. " items.")
--             return false
--         end
--     end
-- end

-- DEPRECATED -- for refresh-based inventory management (non-caching)
-- -- gets all chests as a list of tables
-- function funcs.getChests()
--     local chests = {}
--     for _, type in pairs(vars.CHEST_TYPES) do
--         chests = funcs.concat(chests, { peripheral.find(type, funcs.ignoreNamedChests) })
--     end
--     return chests
-- end

-- DEPRECATED -- for refresh-based inventory management (non-caching)
-- returns a table of name : count values
-- function funcs.getInventory()
--     local inventory = {}
--     local indexMap = {}
--     local chests = funcs.getChests()
--     for _, chest in ipairs(chests) do
--         for slot, item in pairs(chest.list()) do
--             if indexMap[item.name] then
--                 inventory[indexMap[item.name]].count = inventory[indexMap[item.name]].count + item.count
--             else
--                 local modName = string.match(item.name, "(.+):")
--                 -- local displayName = string.match(item.name, ".+:(.+)")
--                 local displayName = chest.getItemDetail(slot).displayName
--                 inventory[#inventory + 1] = { name=item.name, count=item.count, mod=modName, displayName=displayName }
--                 indexMap[item.name] = #inventory
--             end
--         end
--     end

--     -- sort by count
--     table.sort(inventory, function (item1, item2) return item1.count > item2.count end )
--     return inventory
-- end

return funcs