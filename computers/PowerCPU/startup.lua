local funcs = require("funcs")
local vars = require("vars")

peripheral.find("modem", rednet.open)

local generators = funcs.getAll(vars.GENERATOR_TYPE)
local furnaces = funcs.getAll(vars.FURNACE_TYPE)
local placers = funcs.getAll("cyclic:placer")

local sowers = {}
for name, seed in pairs(vars.SOWER_SEED_MAP) do
    local sower = peripheral.wrap(name)
    sower.name = name
    table.insert(sowers, sower)
end

print("Starting main loop...")
while true do
    -- fill all generators
    for _, generator in pairs(generators) do
        if next(generator.peripheral.list()) == nil then
            funcs.callExport("minecraft:blaze_rod", 64, generator.name)
        end
    end

    -- deposit all furnaces
    local needsDeposit = false
    for _, furnace in pairs(furnaces) do
        if furnace.peripheral.list()[2] ~= nil then
            furnace.peripheral.pushItems(vars.DEPOSIT_CHEST, 2)
            needsDeposit = true
        end
    end
    if needsDeposit then
        funcs.callDeposit(vars.DEPOSIT_CHEST)
    end

    -- fill all placers
    for _, placer in pairs(placers) do
        if next(placer.peripheral.list()) == nil then
            funcs.callExport("minecraft:dark_oak_log", 5, placer.name)
        end
    end

    -- fill all sowers
    for _, sower in pairs(sowers) do
        if next(sower.list()) == nil then
            funcs.callExport(vars.SOWER_SEED_MAP[sower.name], 64, sower.name)
        end
    end

    sleep(10)
end
