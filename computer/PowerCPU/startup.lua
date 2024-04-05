os.loadAPI("exports.lua")
os.loadAPI("vars.lua")

rednet.open(vars.WIRED_MODEM_SIDE)

local generator = peripheral.wrap(vars.GENERATOR)
if not generator then
    print("Generator could not be found!")
end

while true do
    if #generator.list() == 0 then
        exports.bamboo(64)
    end
    os.sleep(10)
end
