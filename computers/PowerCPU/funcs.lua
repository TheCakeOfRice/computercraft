local protocol = require("protocol")
local funcs, requestNumber = {}, 0

function funcs.getAll(peripheralType)
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.hasType(name, peripheralType) or name:sub(1, #peripheralType) == peripheralType then
            result[#result + 1] = { name = name, peripheral = peripheral.wrap(name) }
        end
    end
    return result
end

function funcs.call(method, arguments)
    local server = rednet.lookup(protocol.SERVICE, protocol.DISCOVERY_HOST) or rednet.lookup(protocol.SERVICE)
    if not server then return nil, "No storage coordinator found" end
    requestNumber = requestNumber + 1
    local message = arguments or {}
    message.kind, message.method = "request", method
    message.requestId = tostring(os.getComputerID()) .. ":" .. requestNumber
    rednet.send(server, message, protocol.SERVICE)
    local timer = os.startTimer(10)
    while true do
        local event, a, response, networkProtocol = os.pullEvent()
        if event == "timer" and a == timer then return nil, "Request timed out" end
        if event == "rednet_message" and a == server and networkProtocol == protocol.SERVICE
            and response.requestId == message.requestId then
            if response.ok then return response.result end
            return nil, response.error
        end
    end
end

function funcs.callExport(item, count, target)
    return funcs.call("withdraw", { item = item, count = count, target = target })
end

function funcs.callDeposit(source)
    return funcs.call("deposit", { source = source })
end

return funcs
