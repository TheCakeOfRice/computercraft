local vars = require("vars")
local funcs = require("funcs")
local monitor = require("monitor")
local cd = require("_cd_pipeline._cd")

local queue = {}

rednet.open(vars.ENDER_MODEM_SIDE)
print("Listening for rednet messages...")
if monitor then monitor.drawQueue(queue) end
while true do
    local cpu, message = rednet.receive(nil, 60)
    if message then
        if message.method == "pop" then
            local next = funcs.pop(queue)
            if next then
                rednet.send(cpu, next)
                print(" -- executing "..next.method)
                if monitor then monitor.drawQueue(queue) end
            else
                rednet.send(cpu, false)
            end
        elseif message.method == "status" then
            rednet.send(cpu, queue)
        elseif message.method == "gitPull" then
            print("Pulling from GitHub...")
            local pulled = cd.updateFiles("APIServer", message.fileMap)

            -- forward pull request
            local cpus = funcs.concat({ peripheral.find("turtle") }, { peripheral.find("computer") })
            for _, cpu in ipairs(cpus) do
                rednet.send(cpu.getID(), message)
            end

            -- give feedback to initator
            rednet.send(cpu, true)

            if pulled then os.reboot() end
        else
            funcs.enqueue(queue, cpu, message)
            print(" -- queueing "..message.method)
            if monitor then monitor.drawQueue(queue) end
        end
    end
end