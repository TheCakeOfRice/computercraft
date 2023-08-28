--[[

inputs
outputs
io
safety

inputs: track position as object
    strength 1-10 for y axis from starting position outward 
    strength 1-10 for x axis from starting position outward 
        position finder routine
    1 2 3 4
    SHAFT TORCH REDSTONETORCH LEVER
    y = i/contact
    x = contact/i

outputs: 
    reverser
    clutch + y + x //CLUTCH GEARSHIFT

    1st ouput:
        none engaged: clutch active
        1 strength: clutch deactived, y active
        2 strength: redstone onto y to activate x axis
        3 strength: redstone onto y and x to activate z axis
    
    2nd output: reverser

        define values for directions for each axis

    3rd output: sticker
        grab/release box
        assume grab is disengaged upon start
    
]]--
local function sign(x)
    return x>0 and 1 or x<0 and -1 or 0
end

local gantry = {}
local gantryObject = {}

gantry.pulleyWaitTime = 10

gantry.reverserEnums = {}
gantry.reverserEnums["x"] = {}
gantry.reverserEnums["x"]["negative"] = false
gantry.reverserEnums["x"]["positive"] = true

gantry.reverserEnums["y"] = {}
gantry.reverserEnums["y"]["negative"] = true
gantry.reverserEnums["y"]["positive"] = false

gantry.reverserEnums["z"] = {}
gantry.reverserEnums["z"]["negative"] = true
gantry.reverserEnums["z"]["positive"] = false

gantry.xAxisInput = "left"
gantry.yAxisInput = "back"
gantry.reverserOutput = "top"
gantry.axisSelector = "right"
gantry.stickerClicker = "bottom"

function gantryObject:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

function gantry.createGantryObject()
	
	local instance = gantryObject:new()

    instance.x = -1
    instance.y = -1
    instance.clutch = false

    instance.defaultAxis = "clutch"
    instance.activeAxis = "clutch"
    instance.axisTable = {}
    instance.axisTable["clutch"] = 1
    instance.axisTable["y"] = 2
    instance.axisTable["x"] = 3
    instance.axisTable["z"] = 4

    instance.reverserOutput = false

	return instance
end

function gantryObject:isMoving()
    print("active axis: " .. self.activeAxis)
    print("Reverser Status: " .. tostring(self.reverserOutput))
    
    if self.axisTable[self.activeAxis] == 1 then print("clutch engaged") return false end
    return true
end

function gantryObject:setAxis(axisName)
    os.sleep(3)
    self.activeAxis = axisName
    redstone.setAnalogOutput(gantry.axisSelector,self.axisTable[self.activeAxis])
    print("axis set to " .. self.activeAxis)
    os.sleep(3)
end

function gantryObject:setReverser(set)
    self.reverserOutput = set
    if set == true then
        redstone.setAnalogOutput(gantry.reverserOutput, 15)
        print(tostring("Reverser: True"))
    elseif set == false then
        redstone.setAnalogOutput(gantry.reverserOutput, 0)
        print(tostring("Reverser: False"))
    end

    return
end

function gantryObject:getPosition(axis)

    local pos = -1

    return
end

function gantryObject:findPosition()
    local x, y
    print("finding position")
    --z
    self:setAxis("z")
    self:setReverser(gantry.reverserEnums["z"]["negative"])
    os.sleep(10);
    print("rope retracted")

    print("Finding X...")
    --x
    self:setAxis("x")
    self:setReverser(gantry.reverserEnums["x"]["negative"])
    local foundX = false
    local clockTime = os.clock()
    local reversed = false
    while not foundX do
        os.sleep(0.05)
        if redstone.getAnalogInput(gantry.xAxisInput) > 0 then
            x = redstone.getAnalogInput(gantry.xAxisInput)
            foundX = true
        end
        if os.clock() > (clockTime + 10) and not reversed then
            self:setReverser(gantry.reverserEnums["x"]["positive"])
            reversed = true
        end
    end
    print("Gantry X position: "..tostring(redstone.getAnalogInput(gantry.xAxisInput)))

    --y
    print("Finding Y...")
    self:setAxis("y")
    self:setReverser(gantry.reverserEnums["y"]["negative"])
    local foundY = false
    local clockTime = os.clock()
    local reversed = false
    while not foundY do
        os.sleep(0.05)
        if redstone.getAnalogInput(gantry.yAxisInput) > 0 then
            y = redstone.getAnalogInput(gantry.yAxisInput)
            foundY = true
        end
        if os.clock() > (clockTime + 25) and not reversed then
            self:setReverser(gantry.reverserEnums["y"]["positive"])
            reversed = true
        end
    end
    print("Gantry Y position: "..tostring(redstone.getAnalogInput(gantry.yAxisInput)))

    self:setAxis("clutch")

    print("Gantry Position: (" .. tostring(x) .. ", " .. tostring(y) .. ")")

    self.x = x
    self.y = y
    self.clutch = true

    return x, y
end

function gantryObject:moveToPosition(x, y)

    print("Gantry moving to " .. tostring(x) .. ", " .. tostring(y))

    if self.x ~= redstone.getAnalogInput(gantry.xAxisInput) or self.y < redstone.getAnalogInput(gantry.yAxisInput) then
        print("Position Mismatch, finding current position")
        self:findPosition()
    end

    local delta_x, delta_y = x - self.x, y - self.y

    --move to x
        --set reverser

    print(tostring(delta_x))

    self:setAxis("x")
    if sign(delta_x) < 0 then
        self:setReverser(gantry.reverserEnums["x"]["negative"])
    elseif sign(delta_x) > 0 then
        self:setReverser(gantry.reverserEnums["x"]["positive"])
    end
    local foundX = false
    while not foundX do
        os.sleep(0.05)
        if redstone.getAnalogInput(gantry.xAxisInput) == x then
            foundX = true
            print("X pos: ".. tostring(x))
            break
        end
    end

    --move to y
        --set reverser
    self:setAxis("y")
    if sign(delta_y) < 0 then
        self:setReverser(gantry.reverserEnums["y"]["negative"])
    elseif sign(delta_y) > 0 then
        self:setReverser(gantry.reverserEnums["y"]["positive"])
    end
    local foundY = false
    while not foundY do
        os.sleep(0.05)
        if redstone.getAnalogInput(gantry.yAxisInput) == y then
            foundY = true
            print("Y pos: ".. tostring(y))
            break
        end
    end
    self:setAxis("clutch")

    print("Gantry at (" .. tostring(x) .. ", " .. tostring(y) ..")")
    self.x = x
    self.y = y
    return
end

function gantryObject:pulleyProcedure()
    self:setAxis("z")
    print("rope extending")
    self:setReverser(gantry.reverserEnums["z"]["positive"])
    os.sleep(10)
    print("rope extended")
    redstone.setAnalogOutput(gantry.stickerClicker, 15)
    os.sleep(0.25)
    redstone.setAnalogOutput(gantry.stickerClicker, 0)
    print("sticker toggled")
    os.sleep(1)
    self:setReverser(gantry.reverserEnums["z"]["negative"])
    os.sleep(10)
    print("rope retracted")

    self:setAxis("clutch")

    return
end

function gantryObject:task(x1,y1,x2,y2)

    print("Starting task")

    self:moveToPosition(x1,y1)
    self:pulleyProcedure()
    self:moveToPosition(x2,y2)
    self:pulleyProcedure()

    print("ending task")

    return
end

function gantryObject:reset()
    return
end

function gantryObject:loop()
    while true do
        io.write("Pickup Input\nEnter X: ")
        x1 = tonumber(read())
        io.write("\nEnter Y: ")
        y1 = tonumber(read())
        io.write("\nDrop Input\nEnter X: ")
        x2 = tonumber(read())
        io.write("\nEnter Y: ")
        y2 = tonumber(read())
        self:task(x1,y1,x2,y2)
    end
    return
end


gantry.createGantryObject():loop()
