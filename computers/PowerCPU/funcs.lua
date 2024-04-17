local vars = require("vars")

local funcs = {}

function funcs.bamboo(count, targetGenerator)
    rednet.send(vars.STORAGE_CPU, { method="export", item="minecraft:bamboo", count=count, target=targetGenerator })
    local _, message = rednet.receive(nil, 5)
    return message
end

function funcs.callDeposit()
    rednet.send(vars.STORAGE_CPU, { method="deposit" })
    local _, message = rednet.receive(nil, 5)
    return message
end

function funcs.startswith(str, start)
    return string.sub(str, 1, #start) == start
end

return funcs