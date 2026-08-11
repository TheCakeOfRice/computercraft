local Monitor = {}
Monitor.__index = Monitor

function Monitor.new(name)
    local wrapped = name and peripheral.wrap(name) or peripheral.find("monitor")
    if not wrapped then return nil end
    return setmetatable({ peripheral = wrapped }, Monitor)
end

local function count(value)
    if value < 1000 then return tostring(value) end
    if value < 1000000 then return tostring(math.floor(value / 1000)) .. "k" end
    if value < 1000000000 then return tostring(math.floor(value / 1000000)) .. "m" end
    return tostring(math.floor(value / 1000000000)) .. "b"
end

function Monitor:draw(items, status, jobs, workers)
    local screen = self.peripheral
    local width, height = screen.getSize()
    screen.setBackgroundColor(colors.black)
    screen.setTextColor(colors.white)
    screen.clear()
    screen.setCursorPos(1, 1)
    screen.write(("CC Storage: %d/%d slots"):format(status.usedSlots, status.totalSlots))
    local line = 2
    for _, item in ipairs(items) do
        if line > height - 1 then break end
        screen.setCursorPos(1, line)
        local text = count(item.available) .. " " .. item.displayName
        screen.write(text:sub(1, width))
        line = line + 1
    end
    local active, workerCount = 0, 0
    for _, job in ipairs(jobs) do if job.state ~= "COMPLETE" and job.state ~= "CANCELLED" then active = active + 1 end end
    for _ in pairs(workers) do workerCount = workerCount + 1 end
    screen.setCursorPos(1, height)
    screen.write(("Jobs:%d Workers:%d"):format(active, workerCount):sub(1, width))
end

return Monitor
