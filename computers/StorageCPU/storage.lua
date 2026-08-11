local command, a, b = ...
local protocol = require("protocol")
local Config = require("config")

local function call(method, arguments)
    peripheral.find("modem", rednet.open)
    local server = rednet.lookup(protocol.SERVICE, Config.load().hostname) or rednet.lookup(protocol.SERVICE)
    if not server then error("No storage service found", 0) end
    local id = tostring(os.getComputerID()) .. ":cli:" .. os.epoch("utc")
    local message = arguments or {}
    message.kind, message.method, message.requestId = "request", method, id
    rednet.send(server, message, protocol.SERVICE)
    while true do
        local sender, response, responseProtocol = rednet.receive(protocol.SERVICE, 15)
        if not sender then error("Request timed out", 0) end
        if sender == server and responseProtocol == protocol.SERVICE and response.requestId == id then
            if not response.ok then error(response.error, 0) end
            return response.result
        end
    end
end

if command == "configure" then
    shell.run("setup")
elseif command == "doctor" then
    local status = call("status")
    local inv = status.inventory
    print("CC Storage diagnostics")
    print((inv.chests > 0 and "[OK] " or "[!!] ") .. inv.chests .. " storage inventories")
    print(("[OK] %d/%d slots occupied"):format(inv.usedSlots, inv.totalSlots))
    local cfg = Config.load()
    print((peripheral.wrap(cfg.depositInventory) and "[OK] " or "[!!] ") .. "deposit: " .. tostring(cfg.depositInventory))
    print((peripheral.wrap(cfg.withdrawalInventory) and "[OK] " or "[!!] ") .. "withdrawal: " .. tostring(cfg.withdrawalInventory))
    print("[OK] " .. #status.jobs .. " recorded jobs")
    local workers = 0 for _ in pairs(status.workers) do workers = workers + 1 end
    print("[OK] " .. workers .. " registered workers")
elseif command == "rescan" then
    print(textutils.serialise(call("rescan")))
elseif command == "jobs" then
    print(textutils.serialise(call("jobs")))
elseif command == "craft" then
    if not a or not tonumber(b) then error("Usage: storage craft <item> <count>", 0) end
    print(textutils.serialise(call("craft", { item = a, count = tonumber(b) })))
elseif command == "update" then
    local Updater = require("updater")
    local cfg = Config.load()
    local version, err = Updater.update(cfg, "StorageCPU")
    if not version then error(err, 0) end
    for _, role in ipairs({ "iPad", "MacGyver", "PowerCPU" }) do
        local _, cacheErr = Updater.download(cfg, role)
        if cacheErr then printError("Could not cache " .. role .. ": " .. tostring(cacheErr)) end
    end
    print("Updated to " .. version .. "; rebooting")
    os.reboot()
elseif command == "rollback" then
    local ok, err = require("updater").rollback()
    if not ok then error(err, 0) end
    print("Restored the previous release; rebooting")
    os.reboot()
else
    print("Usage: storage <doctor|configure|rescan|jobs|craft|update|rollback>")
end
