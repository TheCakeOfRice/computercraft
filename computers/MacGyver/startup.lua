local vars = require("vars")
local protocol = require("protocol")

peripheral.find("modem", rednet.open)
local requestNumber = 0

local function findServer()
    return rednet.lookup(protocol.SERVICE, protocol.DISCOVERY_HOST) or rednet.lookup(protocol.SERVICE)
end

local function call(message, timeout)
    local server = findServer()
    if not server then return nil, "No storage coordinator found" end
    requestNumber = requestNumber + 1
    message.requestId = tostring(os.getComputerID()) .. ":" .. requestNumber
    rednet.send(server, message, protocol.SERVICE)
    local timer = os.startTimer(timeout or 15)
    while true do
        local event, a, response, networkProtocol = os.pullEvent()
        if event == "timer" and a == timer then return nil, "Coordinator timed out" end
        if event == "rednet_message" and a == server and networkProtocol == protocol.SERVICE
            and type(response) == "table" and response.requestId == message.requestId then
            if response.ok then return response.result end
            return nil, response.error
        end
    end
end

local function request(method, fields)
    fields = fields or {}
    fields.kind, fields.method = "request", method
    return call(fields)
end

local function turtleSlot(gridSlot)
    local row = math.floor((gridSlot - 1) / 3)
    local column = (gridSlot - 1) % 3
    return row * 4 + column + 1
end

local function execute(assignment)
    local operation = assignment.operation
    local produced = 0
    for _ = 1, operation.batches do
        for gridSlot, item in ipairs(operation.grid or {}) do
            if item then
                local result, err = request("withdraw", {
                    item = item, count = 1, target = vars.CRAFTING_CHEST, toSlot = gridSlot,
                    jobId = assignment.jobId,
                })
                if not result then return false, err end
                turtle.select(turtleSlot(gridSlot))
                if not turtle.suck(1) then return false, "Could not pull " .. item .. " from staging" end
            end
        end
        turtle.select(1)
        if not turtle.craft() then return false, "Craft failed" end
        for slot = 1, 16 do
            turtle.select(slot)
            local detail = turtle.getItemDetail()
            if detail and detail.name == operation.output then produced = produced + detail.count end
            if turtle.getItemCount() > 0 and not turtle.drop() then return false, "Output staging chest is full" end
        end
        local _, err = request("deposit", { source = vars.CRAFTING_CHEST })
        if err then return false, err end
    end
    if produced ~= operation.expected then
        return false, ("Expected %d %s, produced %d"):format(operation.expected, operation.output, produced)
    end
    return true
end

print("Craft worker starting")
while true do
    local registered, err = call({
        kind = "worker-register", name = os.getComputerLabel() or "craft-worker",
        capabilities = { "crafting_turtle" }, status = "idle", stagingInventory = vars.CRAFTING_CHEST,
    })
    if not registered then printError(err or "Registration failed") sleep(5) else
        local assignment, nextErr = call({ kind = "worker-next" })
        if nextErr then printError(nextErr) sleep(5)
        elseif not assignment then sleep(2)
        else
            local ok, executeErr = execute(assignment)
            call({ kind = "worker-result", jobId = assignment.jobId, ok = ok, error = executeErr })
        end
    end
end
