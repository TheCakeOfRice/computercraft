os.loadAPI("vars.lua")
os.loadAPI("funcs.lua")

rednet.open(vars.WIRED_MODEM_SIDE)
rednet.open(vars.ENDER_MODEM_SIDE)
print("Listening for rednet messages...")
while true do
    local cpu, message = rednet.receive(nil, 3)
    if message then
        if message.method == "inventory" then
            print("Received 'inventory'.")
            local inv = funcs.getInventory()
            rednet.send(cpu, inv)
        elseif message.method == "get" then
            print("Received 'get "..message.item.." "..tostring(message.count).."'.")
            rednet.send(cpu, funcs.sendToPlayer(message.item, message.count))
        elseif message.method == "export" then
            print("Received 'export "..message.item.." "..tostring(message.count).."'.")
            rednet.send(cpu, funcs.export(message.target, message.item, message.count, message.toSlot))
        elseif message.method == "depositLastRow" then
            print("Received 'depositLastRow'.")
            rednet.send(cpu, funcs.depositLastRow())
        elseif message.method == "deposit" then
            print("Received 'deposit'.")
            rednet.send(cpu, funcs.deposit())
        elseif message.method == "gitPull" then
            print("Pulling from GitHub...")
            local pulled = message.updateFiles("StorageCPU", message.fileMap)
            local cpus = funcs.concat({ peripheral.find("turtle") }, { peripheral.find("computer") })
            for _, cpu in pairs(cpus) do
                rednet.send(cpu.getID(), message)
            end
            rednet.send(cpu, true)
            if pulled then os.reboot() end
        end
    end

    if redstone.getAnalogInput("top") > 0 then
        print("Depositing items...")
        funcs.deposit()
    end
end