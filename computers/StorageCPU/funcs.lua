local vars = require("vars")

local funcs = {}

-- filter function
function funcs.ignoreNamedChests(name, _)
    for _, dirty in ipairs(vars.BLACKLIST) do
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

-- finds all chests in the network, blacklist applied (reboot required when adding chests)
local chests = {}
for _, type in ipairs(vars.CHEST_TYPES) do
    chests = funcs.concat(chests, { peripheral.find(type, funcs.ignoreNamedChests) })
end
funcs.chests = chests

-- constructs inventory, a list of tables containing item info
local inventory = {}
for _, chest in ipairs(funcs.chests) do
    local chestName = peripheral.getName(chest)
    for slot, item in pairs(chest.list()) do
        if inventory[item.name] then
            inventory[item.name].count = inventory[item.name].count + item.count
            if inventory[item.name].locatedAt[chestName] then
                inventory[item.name].locatedAt[chestName][#inventory[item.name].locatedAt[chestName] + 1] = slot
            else
                inventory[item.name].locatedAt[chestName] = { slot }
            end
        else
            local modName = string.match(item.name, "(.+):")
            -- local displayName = string.match(item.name, ".+:(.+)")
            local displayName = chest.getItemDetail(slot).displayName
            local locatedAt = { [chestName]={ slot }}
            inventory[item.name] = { name=item.name, count=item.count, mod=modName, displayName=displayName, locatedAt=locatedAt }
        end
    end
end
funcs.inventory = inventory

-- returns bool
local function withdraw(itemName, itemCount)
    local leftToMove = itemCount
    for _, chest in ipairs(funcs.chests) do
        if leftToMove > 0 then
            local chestName = peripheral.getName(chest)
            if funcs.inventory[itemName].locatedAt[chestName] then
                for i, slot in ipairs(funcs.inventory[itemName].locatedAt[chestName]) do
                    local slotCount = chest.getItemDetail(slot).count

                    -- limit number to move to avoid errors
                    local numToMove = math.min(leftToMove, slotCount)

                    local numMoved = chest.pushItems(vars.WITHDRAWAL_CHEST, slot, numToMove)

                    -- update counts
                    funcs.inventory[itemName].count = funcs.inventory[itemName].count - numMoved
                    if slotCount == numMoved then
                        table.remove(funcs.inventory[itemName].locatedAt[chestName], i)
                    end
                    leftToMove = leftToMove - numMoved
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
        local numMoved = invMgr.addItemToPlayer("right", itemCount, nil, itemName)
        if numMoved == itemCount then
            return true
        else
            print("funcs.sendToPlayer: Only sent " .. tostring(numMoved) .. " of expected " .. tostring(itemCount) .. " items.")
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

local function tableContains(tbl, val)
    for _, value in ipairs(tbl) do
        if val == value then
            return true
        end
    end
    return false
end

-- import from deposit chest, returns bool
function funcs.deposit()
    depositChest = peripheral.wrap(vars.DEPOSIT_CHEST)
    for slot, item in pairs(depositChest.list()) do
        local leftToMove = item.count
        for _, chest in ipairs(funcs.chests) do
            if leftToMove > 0 then
                local chestName = peripheral.getName(chest)
                local numMoved = depositChest.pushItems(chestName, slot, item.count)

                -- update counts
                for slot, item in pairs(chest.list()) do
                    if funcs.inventory[item.name] then
                        funcs.inventory[item.name].count = funcs.inventory[item.name].count + numMoved
                        if funcs.inventory[item.name].locatedAt[chestName] then
                            if not tableContains(funcs.inventory[item.name].locatedAt[chestName], slot) then
                                funcs.inventory[item.name].locatedAt[chestName][#funcs.inventory[item.name].locatedAt[chestName] + 1] = slot
                            end
                        else
                            funcs.inventory[item.name].locatedAt[chestName] = { slot }
                        end
                    else
                        local modName = string.match(item.name, "(.+):")
                        -- local displayName = string.match(item.name, ".+:(.+)")
                        local displayName = chest.getItemDetail(slot).displayName
                        local locatedAt = { [chestName]={ slot }}
                        funcs.inventory[item.name] = { name=item.name, count=item.count, mod=modName, displayName=displayName, locatedAt=locatedAt }
                    end
                end
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
                invMgr.removeItemFromPlayerNBT("left", item.count, nil, { fromSlot=item.slot })
            end
        end
        -- deposit from deposit chest
        return funcs.deposit()
    else
        return false
    end
end

return funcs