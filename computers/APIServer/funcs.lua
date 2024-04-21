local vars = require("vars")

local funcs = {}

function funcs.concat(t1, t2)
    for i=1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function funcs.tagRawMessage(cpu, message)
    local messageCopy = message

    messageCopy.cpu = cpu

    for level, id in ipairs(vars.PRIORITY_MAP) do
        if id == cpu then
            messageCopy.priority = level
        end
    end

    if not messageCopy.priority then
        messageCopy.priority = #vars.PRIORITY_MAP + 1
    end

    return messageCopy
end

function funcs.enqueue(queue, cpu, message)
    queue[#queue + 1] = funcs.tagRawMessage(cpu, message)
    table.sort(queue, function (m1, m2) return m1.priority < m2.priority end)
end

function funcs.pop(queue)
    if #queue == 0 then
        return nil
    end

    return table.remove(queue, 1)
end

return funcs