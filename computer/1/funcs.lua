os.loadAPI("vars.lua")

-- API calls
function inventory()
    rednet.send(vars.STORAGE_CPU, { method="inventory" })
    local _, message = rednet.receive(nil, 5)
    return message
end

function get(item, count)
    rednet.send(vars.STORAGE_CPU, { method="get", item=item, count=count })
    local _, message = rednet.receive(nil, 5)
    return message
end

function depositLastRow()
    rednet.send(vars.STORAGE_CPU, { method="depositLastRow" })
    local _, message = rednet.receive(nil, 5)
    return message
end

function stringifyCount(count)
    local str = ""
    if count < 1000 then
        str = tostring(count)
    elseif count < 1000000 then
        str = tostring(math.floor(count / 1000)) .. "k"
    elseif count < 1000000000 then
        str = tostring(math.floor(count / 1000000)) .. "m"
    end
    for i=1, 4 - #str do
        str = str .. " "
    end
    return str
end