os.loadAPI("exports.lua")
os.loadAPI("vars.lua")

rednet.open(vars.WIRED_MODEM_SIDE)

function string.startswith(str, start)
    return string.sub(str, 1, #start) == start
end

local generators = {}
for _, name in pairs(peripheral.getNames()) do
    if string.startswith(name, vars.GENERATOR_TYPE) then
        print("Found generator "..name)
        local generator = peripheral.wrap(name)
        generator.name = name
        table.insert(generators, generator)
    end
end

print("Starting main loop...")
while true do
    for _, generator in pairs(generators) do
        if #generator.list() == 0 then
            exports.bamboo(64, generator.name)
        end
    end
    os.sleep(10)
end
