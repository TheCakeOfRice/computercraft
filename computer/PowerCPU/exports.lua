function bamboo(count, targetGenerator)
    rednet.send(vars.STORAGE_CPU, { method="export", item="minecraft:bamboo", count=count, target=targetGenerator })
    local _, message = rednet.receive(nil, 5)
    return message
end