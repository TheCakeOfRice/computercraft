local Config = require("config")
if not Config.exists() then shell.run("setup") end
if not Config.exists() then error("Storage setup was not completed", 0) end

local config = Config.load()
local protocol = require("protocol")
local Inventory = require("inventory")
local Planner = require("planner")
local Coordinator = require("coordinator")
local recipes = require("recipes")
local Monitor = require("monitor")

peripheral.find("modem", rednet.open)
rednet.host(protocol.SERVICE, config.hostname or protocol.DISCOVERY_HOST)

local inventory = Inventory.new(config)
inventory:scan()
local coordinator = Coordinator.new(config, inventory, Planner.new(recipes))
local monitor = Monitor.new(config.monitor)

local function drawMonitor()
    if monitor then
        monitor:draw(inventory:list(coordinator.reservations), inventory:status(), coordinator:listJobs(), coordinator.workers)
    end
end

local function respond(sender, request, ok, result, err)
    rednet.send(sender, protocol.reply(request, ok, result, err), protocol.SERVICE)
end

local handlers = {}

handlers.inventory = function() return inventory:list(coordinator.reservations) end
handlers.status = function()
    return { inventory = inventory:status(), jobs = coordinator:listJobs(), workers = coordinator.workers }
end
handlers.rescan = function() inventory:scan() return inventory:status() end
handlers.deposit = function(request)
    local moved, err = inventory:deposit(request.source)
    if err then return nil, err end
    return { moved = moved }
end
handlers.withdraw = function(request)
    if request.jobId then
        local job = coordinator.jobs[tostring(request.jobId)]
        local held = job and job.reservations and job.reservations[request.item] or 0
        if not job or job.state ~= "DISPATCHED" then return nil, "Job is not dispatched" end
        if held < request.count then return nil, "Job has not reserved enough " .. request.item end
    else
        local key = inventory:findKey(request.item)
        local stored = key and inventory.items[key] and inventory.items[key].count or 0
        local available = stored - (coordinator.reservations[request.item] or 0)
        if available < request.count then return nil, "Only " .. math.max(0, available) .. " unreserved items available" end
    end
    local moved, err = inventory:withdraw(request.target or config.withdrawalInventory, request.item, request.count, request.toSlot)
    if request.jobId and moved > 0 then coordinator:consumeReservation(request.jobId, request.item, moved) end
    if err then return nil, err end
    return { moved = moved }
end
handlers.craft = function(request) return coordinator:createJob(request.item, request.count, request.priority) end
handlers.cancel = function(request) return coordinator:cancel(request.jobId) end
handlers.jobs = function() return coordinator:listJobs() end

print("CC Storage '" .. config.hostname .. "' ready with " .. inventory:status().chests .. " inventories")
drawMonitor()
local reconcileTimer = os.startTimer(config.reconcileSeconds)

while true do
    local event, a, b, c = os.pullEvent()
    if event == "rednet_message" then
        local sender, message, networkProtocol = a, b, c
        if networkProtocol == protocol.PROVISION and type(message) == "table" and message.kind == "provision" then
            local path = "/cc-storage/cache/" .. tostring(message.role) .. ".json"
            if fs.exists(path) then
                local file = fs.open(path, "r")
                local contents = file.readAll()
                file.close()
                rednet.send(sender, { requestId = message.requestId, ok = true, bundle = contents }, protocol.PROVISION)
            else
                rednet.send(sender, { requestId = message.requestId, ok = false, error = "Role is not cached; run storage update" }, protocol.PROVISION)
            end
        elseif networkProtocol == protocol.SERVICE and type(message) == "table" then
            if message.kind == "worker-register" then
                respond(sender, message, true, coordinator:registerWorker(sender, message))
            elseif message.kind == "worker-next" then
                local result, err = coordinator:nextOperation(sender)
                respond(sender, message, err == nil, result, err)
            elseif message.kind == "worker-result" then
                local result, err = coordinator:workerResult(sender, message)
                respond(sender, message, err == nil, result, err)
            elseif message.kind == "request" and handlers[message.method] then
                local ok, result, err = pcall(handlers[message.method], message)
                if not ok then respond(sender, message, false, nil, result)
                elseif result == nil and err then respond(sender, message, false, nil, err)
                else respond(sender, message, true, result) end
                drawMonitor()
            elseif message.kind == "request" then
                respond(sender, message, false, nil, "Unknown method: " .. tostring(message.method))
            end
        end
    elseif event == "timer" and a == reconcileTimer then
        local ok, err = pcall(inventory.scan, inventory)
        if not ok then printError("Inventory reconciliation failed: " .. tostring(err)) end
        drawMonitor()
        reconcileTimer = os.startTimer(config.reconcileSeconds)
    elseif event == "redstone" and redstone.getAnalogInput("top") > 0 then
        local _, err = inventory:deposit()
        if err then printError(err) end
        drawMonitor()
    elseif event == "peripheral" or event == "peripheral_detach" then
        inventory:scan()
        peripheral.find("modem", rednet.open)
        drawMonitor()
    end
end
