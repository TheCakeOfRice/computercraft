os.loadAPI("vars.lua")
os.loadAPI("funcs.lua")

rednet.open(vars.MODEM_SIDE)
print("Listening for rednet messages...")
while true do
    local cpu, message = rednet.receive(nil, 3)
    if message then
        if message.method == "inventory" then
            print("Received 'inventory'.")
            local inv = funcs.getInventory()
            rednet.send(cpu, inv)
        elseif message.method == "get" then
            print("Received 'get'.")
            rednet.send(cpu, funcs.sendToPlayer(message.item, message.count))
        elseif message.method == "export" then
            print("Received 'export'.")
            rednet.send(cpu, funcs.export(message.target, message.item, message.count))
        elseif message.method == "depositLastRow" then
            print("Received 'depositLastRow'.")
            rednet.send(cpu, funcs.depositLastRow())
        end
        print("Listening for rednet messages...")
    end

    if redstone.getAnalogInput("top") > 0 then
        print("Depositing items...")
        funcs.deposit()
        print("Listening for rednet messages...")
    end
end