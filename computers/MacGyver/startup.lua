local cd = require("_cd_pipeline/_cd.lua")

rednet.open("bottom")
while true do
    local _, message = rednet.receive(nil, 10)
    if message then
        if message.method == "gitPull" then
            print("Pulling from GitHub...")
            local pulled = cd.updateFiles("MacGyver", message.fileMap)
            if pulled then os.reboot() end
        end
    end
end