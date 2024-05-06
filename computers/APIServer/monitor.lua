local vars = require("vars")

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
    local m = peripheral.wrap(vars.MONITOR_SIDE)
    local w, h = m.getSize()
    m.clear()
    m.setCursorPos(1, 1)
    m.write("== QUEUE FOR API REQUESTS ==")
    for i, call in ipairs(queue) do
        if i >= 1 and i < h then
            local line = "  - " .. forceLength(call.method, 10) .. " FROM " .. tostring(call.cpu)
            if #line > w then
                line = string.sub(line, 1, w)
            end

            m.setCursorPos(1, i + 1)
            m.write(line)
        end
    end
end

return monitor