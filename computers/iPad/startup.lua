os.loadAPI("funcs.lua")
os.loadAPI("gui.lua")

rednet.open("back")

-- init state variable
local state = "home"

-- start gui on home screen
gui.drawHome()

-- init variables for "inv" state
local inv = funcs.inventory()
local scroll_y = 1

while true do
    while state == "home" do
        local event, dir, x, y = os.pullEvent()
        if event == "mouse_click" then
            -- inventory was clicked
            if y <= 10 then
                state = "inv"
                inv = funcs.inventory()
                scroll_y = 1
                gui.drawInv(inv, scroll_y)

            -- git pull was clicked
            else
                os.run("gitPull.lua")
            end
        end
    end

    while state == "inv" do
        local event, dir, x, y = os.pullEvent()
        if event == "mouse_click" then
            -- a button was clicked
            if y == 20 then
                -- home was clicked
                if x <= 7 then
                    state = "home"
                    gui.drawHome()

                -- search was clicked
                elseif x >= 8 and x < 18 then
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
