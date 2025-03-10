local breakpoint = false
while true and (not breakpoint) do
    -- CHECK FUEL
    if turtle.getFuelLevel() < 15 then
        breakpoint = true
        print("Out of fuel!")
    end

    -- PURGE INVENTORY
    turtle.turnRight()
    for i = 1, 16 do
        turtle.select(i)
        local itemExists = turtle.getItemDetail()
        local dropped = turtle.drop()
        if (not dropped) and (itemExists ~= nil) then
            breakpoint = true
            print("Chest is full!")
        end
    end
    turtle.turnLeft()

    -- GRAB AND PLACE SAPLING
    local somethingThere = turtle.inspect()
    if not somethingThere then
        turtle.turnLeft()
        local gotSapling = turtle.suck(1)
        turtle.turnRight()
        if gotSapling then
            turtle.place()
        else
            breakpoint = true
            print("Out of saplings!")
        end
    end

    -- GRAB AND PLACE BONE MEAL
    turtle.select(1)
    local somethingThere, thing = turtle.inspect()
    if somethingThere then
        local saplingThere = (thing.name == "minecraft:birch_sapling")
        while saplingThere and (not breakpoint) do
            local bonemeal = turtle.getItemDetail()
            if bonemeal ~= nil then
                if bonemeal.name == "minecraft:bone_meal" then
                    turtle.place()
                else
                    print("Foreign object found in slot 1!")
                end
            else
                local gotBonemeal = turtle.suckDown(1)
                if not gotBonemeal then
                    breakpoint = true
                    print("Out of bone meal!")
                end
            end
            local somethingThere, thing = turtle.inspect()
            if somethingThere then
                saplingThere = (thing.name == "minecraft:birch_sapling")
            else
                saplingThere = false
            end
        end
    end

    -- CHOP
    local somethingThere, thing = turtle.inspect()
    if somethingThere then
        if thing.name == "minecraft:birch_log" then
            turtle.dig()
            turtle.forward()
            for i = 1, 6 do
                turtle.digUp()
                if i ~= 6 then
                    turtle.up()
                end
            end
            for i = 1, 5 do
                turtle.down()
            end
            turtle.turnLeft()
            turtle.turnLeft()
            turtle.forward()
            turtle.turnLeft()
            turtle.turnLeft()
        end
    end
end