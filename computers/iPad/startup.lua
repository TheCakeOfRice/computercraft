local funcs = require("funcs")
local gui = require("gui")

rednet.open("back")

-- init state variable
local state = "home"

-- init variables for "inv" state
local inv = {}
local scroll_y = 1

while true do
    if state == "home" then
        gui.drawHome()
        local event, dir, x, y = os.pullEvent()
        if event == "mouse_click" then
            -- inventory was clicked
            if y <= 10 then
                inv = funcs.inventory()
                if inv then
                    state = "inv"
                    scroll_y = 1
                    gui.drawInv(inv, scroll_y)
                else
                    gui.drawFailed()
                end

            -- git pull was clicked
            else
                shell.run("gitPull")
            end
        end

    elseif state == "inv" then
        local event, dir, x, y = os.pullEvent()
        if event == "mouse_click" then
            -- a button was clicked
            if y == 20 then
                -- home was clicked
                if x <= 7 then
                    state = "home"

                -- search was clicked
                elseif x >= 8 and x < 17 then
                    gui.drawSearchPrompt()
                    local searchTerm = read()
                    inv = funcs.inventory()
                    inv = funcs.search(inv, searchTerm)
                    scroll_y = 1

                -- deposit was clicked
                else
                    if funcs.depositLastRow() then
                        gui.drawSuccess()
                    else
                        gui.drawFailed()
                    end

                    -- update inventory
                    inv = funcs.inventory()
                end
            
            -- an item was clicked
            else
                if inv[scroll_y + y - 1] then
                    -- get user input for quantity
                    gui.drawQuantityPrompt()
                    local count = tonumber(read())

                    -- request items
                    if funcs.get(inv[scroll_y + y - 1].name, count) then
                        gui.drawSuccess()
                    else
                        gui.drawFailed()
                    end

                    -- update inventory
                    inv = funcs.inventory()
                end
            end

            -- re-draw
            gui.drawInv(inv, scroll_y)

        elseif event == "mouse_scroll" then
            -- update scroll variable
            scroll_y = scroll_y + dir
            scroll_y = math.min(scroll_y, #inv - 18)
            scroll_y = math.max(scroll_y, 1)

            -- re-draw
            gui.drawInv(inv, scroll_y)
        end
    end
end
