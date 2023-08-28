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

function search(inv, searchTerm)
    -- parsing search terms
    local modTerms = {}
    local itemTerms = {}
    for word in string.gmatch(string.lower(searchTerm), "%g+") do
        -- mod search prefixed by '@'
        if word[1] == "@" and #word > 1 then
            table.insert(modTerms, string.sub(word, 2, #word))

        -- item search has no prefix
        else
            table.insert(itemTerms, word)
        end
    end

    newInv = {}
    for name, item in pairs(inv) do
        -- checking for mod match
        local modMatch = true
        for _, modTerm in ipairs(modTerms) do
            if not string.find(string.lower(item.mod), modTerm) then
                modMatch = false
            end
        end

        -- checking for item match
        local itemMatch = true
        for _, itemTerm in ipairs(itemTerms) do
            if not string.find(string.lower(item.displayName), itemTerm) then
                itemMatch = false
            end
        end

        if modMatch and itemMatch then
            newInv[name] = item
        end
    end

    return newInv
end