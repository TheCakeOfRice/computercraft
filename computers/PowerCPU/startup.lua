local funcs = require("funcs")
local vars = require("vars")
local cd = require("_cd_pipeline._cd")

rednet.open(vars.WIRED_MODEM_SIDE)

local generators = {}
for _, name in pairs(peripheral.getNames()) do
    if funcs.startswith(name, vars.GENERATOR_TYPE) then
        print("Found generator "..name)
        local generator = peripheral.wrap(name)
        generator.name = name
        table.insert(generators, generator)
    end
end

local furnaces = {}
for _, name in pairs(peripheral.getNames()) do
    if funcs.startswith(name, vars.FURNACE_TYPE) then
        print("Found furnace "..name)
        local furnace = peripheral.wrap(name)
        furnace.name = name
        table.insert(furnaces, furnace)
    end
end

print("Starting main loop...")
while true do
    -- fill all generators
    for _, generator in pairs(generators) do
        if #generator.list() == 0 then
            funcs.bamboo(64, generator.name)
        end
    end

    -- deposit all furnaces
    local needsDeposit = false
    for _, furnace in pairs(furnaces) do
        if furnace.list()[2] ~= nil then
            furnace.pushItems(vars.DEPOSIT_CHEST, 2)
            needsDeposit = true
        end
    end
    if needsDeposit then
        funcs.callDeposit()
    end

    local _, message = rednet.receive(nil, 10)
    if message then
        if message.method == "gitPull" then
            print("Pulling from GitHub...")
            local pulled = cd.updateFiles("PowerCPU", message.fileMap)
            if pulled then os.reboot() end
        end
    end
end
