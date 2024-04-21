local vars = require("vars")

local funcs = {}

-- API calls
function funcs.inventory()
    rednet.send(vars.STORAGE_CPU, { method="inventory" })
    local _, inv = rednet.receive(nil, 3)

    if not inv then
        return false
    end

    -- converts inventory data into format expected by the iPad GUI
    local guiInv = {}
    for _, item in pairs(inv) do
        guiInv[#guiInv + 1] = item
    end

    -- sorting
    table.sort(guiInv, function (item1, item2) return item1.count > item2.count end )
    
    return guiInv
end

function funcs.get(item, count)
    rednet.send(vars.STORAGE_CPU, { method="get", item=item, count=count })
    local _, message = rednet.receive(nil, 3)
    return message
end

function funcs.depositLastRow()
    rednet.send(vars.STORAGE_CPU, { method="depositLastRow" })
    local _, message = rednet.receive(nil, 3)
    return message
end

function funcs.stringifyCount(count)
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

function funcs.search(inv, searchTerm)
    print("called search")
    -- parsing search terms
    local modTerms = {}
    local itemTerms = {}
    for word in string.gmatch(string.lower(searchTerm), "[^%s]+") do
        -- mod search prefixed by '@'
        if string.sub(word, 1, 1) == "@" and #word > 1 then
            modTerms[#modTerms + 1] = string.sub(word, 2, #word)

        -- item search has no prefix
        else
            itemTerms[#itemTerms + 1] = word
        end
    end

    newInv = {}
    for _, item in ipairs(inv) do
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
            newInv[#newInv + 1] = item
        end
    end

    return newInv
end

return funcs