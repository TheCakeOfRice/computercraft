local Coordinator = {}
Coordinator.__index = Coordinator

local function atomicWrite(path, value)
    fs.makeDir(fs.getDir(path))
    local temporary = path .. ".new"
    local file = assert(fs.open(temporary, "w"))
    file.write(textutils.serialiseJSON(value))
    file.close()
    if fs.exists(path) then fs.delete(path) end
    fs.move(temporary, path)
end

function Coordinator.new(config, inventory, planner)
    local self = setmetatable({
        config = config,
        inventory = inventory,
        planner = planner,
        jobs = {}, workers = {}, reservations = {}, nextJobId = 1,
    }, Coordinator)
    self:load()
    return self
end

function Coordinator:load()
    if not fs.exists(self.config.statePath) then return end
    local file = assert(fs.open(self.config.statePath, "r"))
    local state = textutils.unserialiseJSON(file.readAll())
    file.close()
    if type(state) == "table" then
        self.jobs = state.jobs or {}
        self.reservations = state.reservations or {}
        self.nextJobId = state.nextJobId or 1
        for _, job in pairs(self.jobs) do
            if job.state == "DISPATCHED" then
                job.state = "WORKER_LOST"
                job.error = "Coordinator restarted while operation was dispatched"
            end
        end
    end
end

function Coordinator:save()
    atomicWrite(self.config.statePath, {
        jobs = self.jobs, reservations = self.reservations, nextJobId = self.nextJobId,
    })
end

function Coordinator:available()
    local result = {}
    for _, item in ipairs(self.inventory:list()) do
        result[item.name] = (result[item.name] or 0) + item.count
    end
    for item, amount in pairs(self.reservations) do
        result[item] = math.max(0, (result[item] or 0) - amount)
    end
    return result
end

function Coordinator:createJob(item, count, priority)
    local plan, err = self.planner:plan(item, count, self:available())
    if not plan then return nil, err end
    local id = tostring(self.nextJobId)
    self.nextJobId = self.nextJobId + 1
    local job = {
        id = id, item = item, count = count, priority = priority or 100,
        state = #plan.operations == 0 and "COMPLETE" or "READY",
        operations = plan.operations, operation = 1, reservations = plan.reservations,
        createdAt = os.epoch("utc"), updatedAt = os.epoch("utc"),
    }
    self.jobs[id] = job
    if job.state ~= "COMPLETE" then
        for key, amount in pairs(plan.reservations) do self.reservations[key] = (self.reservations[key] or 0) + amount end
    else
        job.reservations = {}
    end
    self:save()
    return job
end

function Coordinator:cancel(id)
    local job = self.jobs[tostring(id)]
    if not job then return nil, "Unknown job" end
    if job.state == "COMPLETE" then return nil, "Completed jobs cannot be cancelled" end
    if job.state == "DISPATCHED" then return nil, "Wait for the dispatched worker before cancelling" end
    job.state, job.updatedAt = "CANCELLED", os.epoch("utc")
    for key, amount in pairs(job.reservations or {}) do
        self.reservations[key] = math.max(0, (self.reservations[key] or 0) - amount)
    end
    self:save()
    return job
end

function Coordinator:registerWorker(sender, message)
    self.workers[tostring(sender)] = {
        id = sender, name = message.name or ("worker-" .. sender),
        capabilities = message.capabilities or {}, status = message.status or "idle",
        lastSeen = os.epoch("utc"),
    }
    if message.stagingInventory then
        self.inventory:ignore(message.stagingInventory)
        self.inventory:scan()
    end
    return self.workers[tostring(sender)]
end

function Coordinator:workerResult(sender, message)
    local job = self.jobs[tostring(message.jobId)]
    if not job then return nil, "Unknown job" end
    if job.state ~= "DISPATCHED" or job.worker ~= sender then return nil, "Worker does not own this operation" end
    if message.ok then
        job.operation = job.operation + 1
        if job.operation > #job.operations then
            job.state = "COMPLETE"
            for item, amount in pairs(job.reservations or {}) do
                self.reservations[item] = math.max(0, (self.reservations[item] or 0) - amount)
            end
            job.reservations = {}
        else job.state = "READY" end
    else
        job.state = "WORKER_LOST"
        job.error = message.error or "Worker reported failure"
    end
    job.updatedAt = os.epoch("utc")
    local worker = self.workers[tostring(sender)]
    if worker then worker.status, worker.lastSeen = "idle", os.epoch("utc") end
    self.inventory:scan()
    self:save()
    return job
end

function Coordinator:consumeReservation(jobId, item, count)
    local job = self.jobs[tostring(jobId)]
    if not job or job.state ~= "DISPATCHED" then return nil, "Job is not dispatched" end
    local held = (job.reservations or {})[item] or 0
    if held < count then return nil, "Job has not reserved enough " .. item end
    job.reservations[item] = held - count
    self.reservations[item] = math.max(0, (self.reservations[item] or 0) - count)
    self:save()
    return true
end

function Coordinator:nextOperation(sender)
    local worker = self.workers[tostring(sender)]
    if not worker then return nil, "Worker is not registered" end
    local supported = {}
    for _, capability in ipairs(worker.capabilities) do supported[capability] = true end
    local candidates = {}
    for _, job in pairs(self.jobs) do
        local operation = job.operations[job.operation]
        if (job.state == "READY" or job.state == "WAITING_FOR_INGREDIENTS") and operation and supported[operation.capability] then
            candidates[#candidates + 1] = job
        end
    end
    table.sort(candidates, function(a, b)
        if a.priority == b.priority then return a.createdAt < b.createdAt end
        return a.priority < b.priority
    end)
    local job = candidates[1]
    if not job then return nil end
    job.state, job.worker, job.updatedAt = "DISPATCHED", sender, os.epoch("utc")
    worker.status = "busy"
    self:save()
    return { jobId = job.id, index = job.operation, operation = job.operations[job.operation] }
end

function Coordinator:listJobs()
    local result = {}
    for _, job in pairs(self.jobs) do result[#result + 1] = job end
    table.sort(result, function(a, b) return a.createdAt > b.createdAt end)
    return result
end

return Coordinator
