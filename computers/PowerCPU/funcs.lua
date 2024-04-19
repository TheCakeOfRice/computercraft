local vars = require("vars")

local funcs = {}

-- wraps all peripherals of type, plus names
function funcs.getAll(type)
    local periphs = {}
    for _, name in pairs(peripheral.getNames()) do
        if funcs.startswith(name, type) then
            local periph = peripheral.wrap(name)
            periph.name = name
            table.insert(periphs, periph)
        end
    end
    return periphs
end

function funcs.export(item, count, target)
    rednet.send(vars.STORAGE_CPU, { method="export", item=item, count=count, target=target })
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