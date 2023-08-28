os.loadAPI("funcs.lua")

function draw(inv, y)
    term.clear()
    for i, item in ipairs(inv) do
        -- only write up to 19 lines
        if i >= y and i < y + 19 then
            -- make sure line is a string of length 26
            local line = funcs.stringifyCount(item.count) .. " / "
            if #item.displayName < 20 then
                line = line .. item.displayName
            else
                line = line .. string.sub(item.displayName, 1, 19)
            end

            -- write line to terminal at relative position
            term.setCursorPos(1, i - y + 1)
            term.write(line)
        end
    end

    -- write buttons
    term.setCursorPos(1, 20)
    term.blit(" Search ", colors.white, colors.blue)
    term.blit(" Deposit Last Row ", colors.white, colors.red)
end

function drawSuccess()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write("       ")
    term.blit(" Success! ", colors.white, colors.green)
end

function drawFailed()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write("       ")
    term.blit(" Failed ", colors.white, colors.red)
end

function drawQuantityPrompt()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write("      ")
    term.blit(" Quantity:", colors.white, colors.gray)
    term.write(" ")
end

function drawSearchPrompt()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write("       ")
    term.blit(" Search:", colors.white, colors.blue)
    term.write(" ")
end