local Planner = {}
Planner.__index = Planner

function Planner.new(recipes)
    return setmetatable({ recipes = recipes }, Planner)
end

function Planner:plan(item, count, available)
    local operations, claims, visiting = {}, {}, {}

    local function consume(name, amount)
        local have = math.max(0, (available[name] or 0) - (claims[name] or 0))
        local fromStorage = math.min(have, amount)
        claims[name] = (claims[name] or 0) + fromStorage
        local missing = amount - fromStorage
        if missing <= 0 then return true end

        local recipe = self.recipes[name]
        if not recipe then return false, "Missing " .. missing .. " x " .. name end
        if visiting[name] then return false, "Recipe cycle involving " .. name end
        visiting[name] = true

        local batches = math.ceil(missing / recipe.output.count)
        for ingredient, perBatch in pairs(recipe.ingredients) do
            local ok, err = consume(ingredient, perBatch * batches)
            if not ok then visiting[name] = nil return false, err end
        end
        operations[#operations + 1] = {
            recipe = recipe.id,
            capability = recipe.capability,
            batches = batches,
            output = recipe.output.name,
            expected = recipe.output.count * batches,
            grid = recipe.grid,
            ingredients = recipe.ingredients,
        }
        -- Reserve the future output too. This prevents another request from
        -- consuming an intermediate after it is deposited but before its
        -- dependent operation claims it.
        claims[name] = (claims[name] or 0) + missing
        visiting[name] = nil
        return true
    end

    local ok, err = consume(item, count)
    if not ok then return nil, err end
    return { item = item, count = count, operations = operations, reservations = claims }
end

return Planner
