os.loadAPI("funcs.lua")

function refresh(inv)
    term.clear()
    term.setCursorPos(1, 1)
    local y = 1
    for name, item in pairs(inv) do
        if y < 20 then
            local line = funcs.stringifyCount(item.count) .. " / "
            if #item.displayName < 20 then
                line = line .. item.displayName
            else
                line = line .. string.sub(item.displayName, 1, 19)
            end
            term.write(line)
            y = y + 1
            term.setCursorPos(1, y)
        end
    end
    term.setCursorPos(1, 20)
    term.blit(" Search ", colors.white, colors.blue)
    term.blit(" Deposit Last Row ", colors.white, colors.red)
end

-- get list
-- blit / while true wait for input
-- if click
-- if scroll