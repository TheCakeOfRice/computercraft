function bamboo(count)
    rednet.send(vars.STORAGE_CPU, { method="export", item="minecraft:bamboo", count=count, target=vars.GENERATOR })
    local _, message = rednet.receive(nil, 5)
    return message
end