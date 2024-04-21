local vars = require("vars")
local recipes = require("recipes")

for i=1, 9 do
    if recipes.CHEST[i] then
        rednet.send(vars.API_SERVER, { method="export", item=recipes.CHEST[i], count=1, target=vars.CRAFTING_CHEST, toSlot=i })
        local _, message = rednet.receive(nil, 5)
        print(tostring(i)..": "..tostring(message))

        if i < 4 then
            turtle.select(i)
        elseif i < 7 then
            turtle.select(i + 1)
        else
            turtle.select(i + 2)
        end
        turtle.suck()
    end
end

turtle.select(1)
turtle.craft()