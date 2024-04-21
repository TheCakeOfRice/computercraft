local funcs = require("funcs")
local vars = require("vars")
local cd = require("_cd_pipeline._cd")

rednet.open(vars.WIRED_MODEM_SIDE)
while true do
    rednet.send(vars.API_SERVER, { method="pop" })
    local _, message = rednet.receive(nil, 3)
    if message then
        if message.method == "inventory" then
            print("Received 'inventory'.")
            local inv = funcs.getInventory()
            rednet.send(message.cpu, inv)
        elseif message.method == "get" then
            print("Received 'get "..message.item.." "..tostring(message.count).."'.")
            rednet.send(message.cpu, funcs.sendToPlayer(message.item, message.count))
        elseif message.method == "export" then
            print("Received 'export "..message.item.." "..tostring(message.count).."'.")
            rednet.send(message.cpu, funcs.export(message.target, message.item, message.count, message.toSlot))
        elseif message.method == "depositLastRow" then
            print("Received 'depositLastRow'.")
            rednet.send(message.cpu, funcs.depositLastRow())
        elseif message.method == "deposit" then
            print("Received 'deposit'.")
            rednet.send(message.cpu, funcs.deposit())
        elseif message.method == "gitPull" then
            print("Pulling from GitHub...")
            local pulled = cd.updateFiles("StorageCPU", message.fileMap)
            if pulled then os.reboot() end
        end
    end

    if redstone.getAnalogInput("top") > 0 then
        print("Depositing items...")
        funcs.deposit()
    end
end