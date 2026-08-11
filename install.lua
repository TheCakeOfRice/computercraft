local args = { ... }
local role = args[1]
local source = args[2] or "https://raw.githubusercontent.com/TheCakeOfRice/computercraft/master/releases/manifest.json"

local roles = { "StorageCPU", "iPad", "MacGyver", "PowerCPU" }
if not role then
    print("CC Storage installer")
    for index, name in ipairs(roles) do print(index .. ". " .. name) end
    repeat
        write("Role: ")
        local choice = tonumber(read())
        role = choice and roles[choice]
    until role
end

local function fetch(url)
    local response, err = http.get(url, { ["User-Agent"] = "cc-storage-installer" })
    if not response then error("Download failed: " .. tostring(err), 0) end
    local body = response.readAll()
    response.close()
    return body
end

local release, bundle
if source == "network" then
    peripheral.find("modem", rednet.open)
    local requestId = tostring(os.getComputerID()) .. ":provision:" .. os.epoch("utc")
    rednet.broadcast({ kind = "provision", role = role, requestId = requestId }, "cc-storage-provision/v1")
    local timer = os.startTimer(15)
    while true do
        local event, _, response, responseProtocol = os.pullEvent()
        if event == "timer" and _ == timer then error("No provisioning server responded", 0) end
        if event == "rednet_message" and responseProtocol == "cc-storage-provision/v1"
            and type(response) == "table" and response.requestId == requestId then
            if not response.ok then error(response.error or "Provisioning failed", 0) end
            bundle = textutils.unserialiseJSON(response.bundle)
            release = { version = bundle and bundle.version or "unknown" }
            break
        end
    end
else
    local manifest = textutils.unserialiseJSON(fetch(source))
    release = manifest and manifest.channels and manifest.channels.stable
    local url = release and release.roles and release.roles[role]
    if not url then error("Manifest has no bundle for " .. tostring(role), 0) end
    bundle = textutils.unserialiseJSON(fetch(url))
end
if not bundle or type(bundle.files) ~= "table" then error("Invalid bundle", 0) end

local stage = "/cc-storage/install-stage"
if fs.exists(stage) then fs.delete(stage) end
fs.makeDir(stage)
for path, contents in pairs(bundle.files) do
    local destination = fs.combine(stage, path)
    fs.makeDir(fs.getDir(destination))
    local file = assert(fs.open(destination, "w"))
    file.write(contents)
    file.close()
end
for path in pairs(bundle.files) do
    local destination = "/" .. path
    fs.makeDir(fs.getDir(destination))
    if fs.exists(destination) then fs.delete(destination) end
    fs.move(fs.combine(stage, path), destination)
end
fs.delete(stage)
fs.makeDir("/cc-storage")
local versionFile = fs.open("/cc-storage/version", "w")
versionFile.write(release.version)
versionFile.close()
print("Installed " .. role .. " " .. release.version)
print("Rebooting...")
os.reboot()
