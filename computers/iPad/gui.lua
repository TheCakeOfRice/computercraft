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
    term.blit(" Search ", "00000000", "bbbbbbbb")
    term.blit(" Deposit Last Row ", "000000000000000000", "eeeeeeeeeeeeeeeeee")
end

function drawSuccess()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write("       ")
    term.blit(" Success! ", "0000000000", "dddddddddd")
end

function drawFailed()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write("       ")
    term.blit(" Failed ", "00000000", "eeeeeeee")
end

function drawQuantityPrompt()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write(" ")
    term.blit(" Quantity:", "0000000000", "8888888888")
    term.write(" ")
end

function drawSearchPrompt()
    term.setCursorPos(1, 20)
    term.clearLine()
    term.write(" ")
    term.blit(" Search:", "00000000", "bbbbbbbb")
    term.write(" ")
end