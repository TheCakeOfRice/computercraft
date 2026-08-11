local Config = require("config")

peripheral.find("modem", rednet.open)
local inventories = {}
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.hasType(name, "inventory") then
        local wrapped = peripheral.wrap(name)
        inventories[#inventories + 1] = { name = name, size = wrapped.size() }
    end
end
table.sort(inventories, function(a, b) return a.name < b.name end)

print("CC Storage setup")
print("Connected inventories:")
for index, inventory in ipairs(inventories) do
    print(("%d. %s (%d slots)"):format(index, inventory.name, inventory.size))
end

local function choose(prompt)
    while true do
        write(prompt .. ": ")
        local selected = tonumber(read())
        if selected and inventories[selected] then return inventories[selected].name end
        printError("Enter one of the numbers above")
    end
end

local value = Config.load()
if #inventories < 2 then error("Connect at least a deposit and withdrawal inventory", 0) end
value.depositInventory = choose("Deposit inventory number")
repeat
    value.withdrawalInventory = choose("Withdrawal inventory number")
    if value.withdrawalInventory == value.depositInventory then printError("Choose a different inventory") end
until value.withdrawalInventory ~= value.depositInventory

local monitor = peripheral.find("monitor")
value.monitor = monitor and peripheral.getName(monitor) or nil
write("Service name [main]: ")
local hostname = read()
value.hostname = hostname ~= "" and hostname or "main"
Config.save(value)
print("Configuration saved to " .. Config.path())
