local vars = require("vars")

local monitor = {}

local function stringifyCount(count)
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

function monitor.drawInv(inv)
    local m = peripheral.wrap(vars.MONITOR)
    local w, h = m.getSize()
    m.clear()
    for i, item in ipairs(inv) do
        -- only write up to h lines
        if i >= 1 and i < h then
            -- make sure line is a string of length w or less
            local line = stringifyCount(item.count) .. " / "
            if #item.displayName < w - 7 then
                line = line .. item.displayName
            else
                line = line .. string.sub(item.displayName, 1, w - 7)
            end

            -- write line to monitor at relative position
            m.setCursorPos(1, i)
            m.write(line)
        end
    end
end

return monitor