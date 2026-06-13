-- run me on a new computer to listen for git pull
local cd = require("_cd_pipeline._cd")

pcall(rednet.open, "top")
pcall(rednet.open, "bottom")
pcall(rednet.open, "left")
pcall(rednet.open, "right")
pcall(rednet.open, "front")
pcall(rednet.open, "back")
while true do
    local _, message = rednet.receive(nil, 10)
    if message then
        if message.method == "gitPull" then
            print("Pulling from GitHub...")
            local pulled = cd.updateFiles(os.getComputerLabel(), message.fileMap, message.token)
            
            if os.getComputerLabel() == "APIServer" then
                -- forward pull request
                local cpus = funcs.concat({ peripheral.find("turtle") }, { peripheral.find("computer") })
                for _, cpu in ipairs(cpus) do
                    rednet.send(cpu.getID(), message)
                end

                -- give feedback to initator
                rednet.send(cpu, true)
            end

            if pulled then os.reboot() end
        end
    end
end