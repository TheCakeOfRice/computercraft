os.loadAPI("funcs.lua")

function drawHome()
    term.clear()

    local no_text_line = "                          "
    local white_line = "00000000000000000000000000"
    local red_line = "eeeeeeeeeeeeeeeeeeeeeeeeee"
    local blue_line = "bbbbbbbbbbbbbbbbbbbbbbbbbb"

    for y=1, 20 do
        -- inventory button on top half of screen, white text, red background
        if y == 5 then
            term.blit("        Inventory         ", white_line, red_line)
        elseif y <= 10 then
            term.blit(no_text_line, white_line, red_line)
        
        -- git pull button on bottom half of screen, white text, blue background
        elseif y == 15 then
            term.blit("         Git Pull         ", white_line, blue_line)
        else
            term.blit(no_text_line, white_line, blue_line)
        end
    end
end

function drawInv(inv, y)
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
    term.blit(" Home  ", "0000000", "ddddddd")
    term.blit(" Search  ", "000000000", "bbbbbbbbb")
    term.blit(" Deposit  ", "0000000000", "eeeeeeeeee")
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