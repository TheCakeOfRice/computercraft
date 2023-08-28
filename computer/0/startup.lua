os.loadAPI("vars.lua")
os.loadAPI("funcs.lua")

rednet.open("right")

print("Listening for rednet messages...")
while true do
    local cpu, message = rednet.receive(nil, 5)
    if message then
        if message.method == "inventory" then
            rednet.send(cpu, funcs.getInventory())
        elseif message.method == "get" then
            rednet.send(cpu, funcs.sendToPlayer(message.item, message.count))
        elseif message.method == "depositLastRow" then
            rednet.send(cpu, funcs.depositLastRow())
        end
    end

    if redstone.getAnalogInput("top") > 0 then
        print("Depositing items...")
        funcs.deposit()
        print("Listening for rednet messages...")
    end
end