local vars = require("vars")

local m = peripheral.wrap(vars.MONITOR)
if m == nil then return false end

local monitor = {}

local function forceLength(str, len)
    if #str > len then
        return string.sub(str, 1, len)
    elseif #str == len then
        return str
    else
        while #str < len do
            str = str .. " "
        end
        return str
    end
end

function monitor.drawQueue(queue)
    local w, h = m.getSize()
    m.clear()
    if math.floor(w / 2) - 14 > 0 then
        m.setCursorPos(math.floor(w / 2) - 14, 1)
    else
        m.setCursorPos(1, 1)
    end
    m.write("== QUEUE FOR API REQUESTS ==")
    for i, call in ipairs(queue) do
        if i >= 1 and i < h then
            local line = "  - " .. forceLength(call.method, math.floor(w / 5)) .. " FROM " .. tostring(call.cpu)
            if #line > w - math.floor(w / 5) then
                line = string.sub(line, 1, w)
            end

            m.setCursorPos(math.floor(w / 5), i + 1)
            m.write(line)
        end
    end
end

return monitor