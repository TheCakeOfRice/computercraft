local config = {}

local PATH = "/cc-storage/config.json"

local defaults = {
    role = "server",
    hostname = "main",
    depositInventory = nil,
    withdrawalInventory = nil,
    monitor = nil,
    reconcileSeconds = 60,
    statePath = "/cc-storage/state.json",
    releaseChannel = "stable",
    updateManifest = "https://raw.githubusercontent.com/TheCakeOfRice/computercraft/master/releases/manifest.json",
    ignoredInventories = {},
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

function config.path()
    return PATH
end

function config.exists()
    return fs.exists(PATH)
end

function config.load()
    local result = copy(defaults)
    if not fs.exists(PATH) then return result end

    local file = assert(fs.open(PATH, "r"))
    local decoded = textutils.unserialiseJSON(file.readAll())
    file.close()
    if type(decoded) ~= "table" then error("Invalid configuration at " .. PATH, 0) end
    for key, value in pairs(decoded) do result[key] = value end
    return result
end

function config.save(value)
    fs.makeDir(fs.getDir(PATH))
    local temporary = PATH .. ".new"
    local file = assert(fs.open(temporary, "w"))
    file.write(textutils.serialiseJSON(value))
    file.close()
    if fs.exists(PATH) then fs.delete(PATH) end
    fs.move(temporary, PATH)
end

return config
