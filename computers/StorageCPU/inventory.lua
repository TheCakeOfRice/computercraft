local Inventory = {}
Inventory.__index = Inventory

local function append(list, value)
    list[#list + 1] = value
end

local function sortedKeys(map)
    local keys = {}
    for key in pairs(map) do append(keys, key) end
    table.sort(keys)
    return keys
end

function Inventory.new(config)
    return setmetatable({
        config = config,
        chests = {},
        items = {},
        slots = {},
        openSlots = {},
        lastScan = nil,
        ignored = {},
    }, Inventory)
end

function Inventory:isReserved(name)
    if name == self.config.depositInventory or name == self.config.withdrawalInventory then return true end
    if self.ignored[name] then return true end
    for _, ignored in ipairs(self.config.ignoredInventories or {}) do
        if name == ignored then return true end
    end
    return false
end

function Inventory:ignore(name)
    if name then self.ignored[name] = true end
end

function Inventory:discover()
    self.chests = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.hasType(name, "inventory") and not self:isReserved(name) then
            self.chests[name] = peripheral.wrap(name)
        end
    end
end

function Inventory:scan()
    self:discover()
    self.items, self.slots, self.openSlots = {}, {}, {}
    local detailByName = {}

    for _, chestName in ipairs(sortedKeys(self.chests)) do
        local chest = self.chests[chestName]
        local listed = chest.list()
        local occupied = {}
        self.openSlots[chestName] = {}

        for slot, basic in pairs(listed) do
            occupied[slot] = true
            local key = basic.name .. "\0" .. (basic.nbt or "")
            if not self.items[key] then
                local detail = detailByName[key]
                if not detail then
                    detail = chest.getItemDetail(slot) or basic
                    detailByName[key] = detail
                end
                self.items[key] = {
                    key = key,
                    name = basic.name,
                    nbt = basic.nbt,
                    displayName = detail.displayName or basic.name,
                    mod = basic.name:match("^([^:]+):") or "minecraft",
                    count = 0,
                    locations = {},
                }
            end
            self.items[key].count = self.items[key].count + basic.count
            self.items[key].locations[chestName] = self.items[key].locations[chestName] or {}
            append(self.items[key].locations[chestName], { slot = slot, count = basic.count })
            self.slots[chestName .. ":" .. slot] = key
        end

        for slot = 1, chest.size() do
            if not occupied[slot] then append(self.openSlots[chestName], slot) end
        end
    end
    self.lastScan = os.epoch("utc")
end

function Inventory:list(reserved)
    local result = {}
    for key, item in pairs(self.items) do
        local held = reserved and (reserved[key] or reserved[item.name]) or 0
        append(result, {
            key = key,
            name = item.name,
            nbt = item.nbt,
            displayName = item.displayName,
            mod = item.mod,
            count = item.count,
            reserved = held,
            available = math.max(0, item.count - held),
        })
    end
    table.sort(result, function(a, b)
        if a.count == b.count then return a.displayName < b.displayName end
        return a.count > b.count
    end)
    return result
end

function Inventory:findKey(name)
    if self.items[name] then return name end
    for key, item in pairs(self.items) do
        if item.name == name and not item.nbt then return key end
    end
    for key, item in pairs(self.items) do
        if item.name == name then return key end
    end
end

function Inventory:withdraw(target, requested, count, toSlot)
    local key = self:findKey(requested)
    local item = key and self.items[key]
    if not item then return 0, "Item is not in storage" end
    local remaining, movedTotal = count, 0

    for chestName, locations in pairs(item.locations) do
        local chest = self.chests[chestName] or peripheral.wrap(chestName)
        for _, location in ipairs(locations) do
            if remaining <= 0 then break end
            local moved = chest.pushItems(target, location.slot, remaining, toSlot)
            remaining = remaining - moved
            movedTotal = movedTotal + moved
        end
        if remaining <= 0 then break end
    end
    self:scan()
    if remaining > 0 then return movedTotal, "Only moved " .. movedTotal .. " of " .. count end
    return movedTotal
end

function Inventory:deposit(source)
    source = source or self.config.depositInventory
    local input = source and peripheral.wrap(source)
    if not input then return 0, "Deposit inventory is unavailable" end
    local movedTotal = 0

    for fromSlot, sourceItem in pairs(input.list()) do
        local remaining = sourceItem.count

        -- Fill compatible stacks first.
        for _, chestName in ipairs(sortedKeys(self.chests)) do
            local chest = self.chests[chestName]
            for toSlot, targetItem in pairs(chest.list()) do
                if remaining <= 0 then break end
                if targetItem.name == sourceItem.name and targetItem.nbt == sourceItem.nbt then
                    local moved = input.pushItems(chestName, fromSlot, remaining, toSlot)
                    remaining, movedTotal = remaining - moved, movedTotal + moved
                end
            end
            if remaining <= 0 then break end
        end

        -- Then use empty slots.
        for _, chestName in ipairs(sortedKeys(self.chests)) do
            local chest = self.chests[chestName]
            for toSlot = 1, chest.size() do
                if remaining <= 0 then break end
                if chest.list()[toSlot] == nil then
                    local moved = input.pushItems(chestName, fromSlot, remaining, toSlot)
                    remaining, movedTotal = remaining - moved, movedTotal + moved
                end
            end
            if remaining <= 0 then break end
        end
        if remaining > 0 then
            self:scan()
            return movedTotal, "Storage is full; " .. remaining .. " items remain"
        end
    end
    self:scan()
    return movedTotal
end

function Inventory:status()
    local chestCount, used, total = 0, 0, 0
    for _, chest in pairs(self.chests) do
        chestCount = chestCount + 1
        total = total + chest.size()
        for _ in pairs(chest.list()) do used = used + 1 end
    end
    return { chests = chestCount, usedSlots = used, totalSlots = total, lastScan = self.lastScan }
end

return Inventory
