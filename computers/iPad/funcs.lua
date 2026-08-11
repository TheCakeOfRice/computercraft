local protocol = require("protocol")
local funcs = {}
local nextRequestId = 1

peripheral.find("modem", rednet.open)

local function server()
    local id = rednet.lookup(protocol.SERVICE, protocol.DISCOVERY_HOST)
    if not id then id = rednet.lookup(protocol.SERVICE) end
    return id
end

function funcs.call(method, arguments, timeout)
    local id = server()
    if not id then return nil, "No storage server found" end
    local requestId = tostring(os.getComputerID()) .. ":" .. tostring(nextRequestId)
    nextRequestId = nextRequestId + 1
    local request = arguments or {}
    request.kind, request.method, request.requestId = "request", method, requestId
    rednet.send(id, request, protocol.SERVICE)
    local timer = os.startTimer(timeout or 10)
    while true do
        local event, a, message, networkProtocol = os.pullEvent()
        if event == "timer" and a == timer then return nil, "Request timed out" end
        if event == "rednet_message" and a == id and networkProtocol == protocol.SERVICE
            and type(message) == "table" and message.requestId == requestId then
            if message.ok then return message.result end
            return nil, message.error or "Request failed"
        end
    end
end

function funcs.inventory() return funcs.call("inventory") end
function funcs.get(item, count) return funcs.call("withdraw", { item = item, count = count }) end
function funcs.deposit() return funcs.call("deposit") end
function funcs.craft(item, count) return funcs.call("craft", { item = item, count = count }) end
function funcs.jobs() return funcs.call("jobs") end

function funcs.stringifyCount(count)
    if count < 1000 then return tostring(count) end
    if count < 1000000 then return tostring(math.floor(count / 1000)) .. "k" end
    if count < 1000000000 then return tostring(math.floor(count / 1000000)) .. "m" end
    return tostring(count)
end

function funcs.search(inv, searchTerm)
    local modTerms, itemTerms = {}, {}
    for word in string.gmatch(string.lower(searchTerm), "[^%s]+") do
        if string.sub(word, 1, 1) == "@" and #word > 1 then
            modTerms[#modTerms + 1] = string.sub(word, 2)
        else
            itemTerms[#itemTerms + 1] = word
        end
    end
    local newInv = {}
    for _, item in ipairs(inv or {}) do
        local matches = true
        for _, term in ipairs(modTerms) do
            if not string.find(string.lower(item.mod), term, 1, true) then matches = false end
        end
        for _, term in ipairs(itemTerms) do
            if not string.find(string.lower(item.displayName), term, 1, true) then matches = false end
        end
        if matches then newInv[#newInv + 1] = item end
    end
    return newInv
end

return funcs
