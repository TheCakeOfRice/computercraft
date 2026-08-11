local Updater = {}

local function get(url)
    local response, err = http.get(url, { ["User-Agent"] = "cc-storage-updater" })
    if not response then return nil, err end
    local body = response.readAll()
    response.close()
    return body
end

local function writeAtomic(path, contents)
    fs.makeDir(fs.getDir(path))
    local temporary = path .. ".new"
    local file = assert(fs.open(temporary, "w"))
    file.write(contents)
    file.close()
    if fs.exists(path) then fs.delete(path) end
    fs.move(temporary, path)
end

local function installBundle(bundle)
    if type(bundle) ~= "table" or type(bundle.files) ~= "table" then return nil, "Invalid release bundle" end
    local stage = "/cc-storage/update-stage"
    local backup = "/cc-storage/update-backup"
    if fs.exists(stage) then fs.delete(stage) end
    if fs.exists(backup) then fs.delete(backup) end
    fs.makeDir(stage)
    fs.makeDir(backup)
    for path, contents in pairs(bundle.files) do
        local destination = fs.combine(stage, path)
        fs.makeDir(fs.getDir(destination))
        local file = assert(fs.open(destination, "w"))
        file.write(contents)
        file.close()
    end
    local replaced = {}
    local ok, err = pcall(function()
        for path in pairs(bundle.files) do
            local staged, destination = fs.combine(stage, path), "/" .. path
            local previous = fs.combine(backup, path)
            fs.makeDir(fs.getDir(destination))
            if fs.exists(destination) then
                fs.makeDir(fs.getDir(previous))
                fs.copy(destination, previous)
                fs.delete(destination)
            end
            fs.move(staged, destination)
            replaced[#replaced + 1] = path
        end
    end)
    fs.delete(stage)
    if not ok then
        for _, path in ipairs(replaced) do
            local destination, previous = "/" .. path, fs.combine(backup, path)
            if fs.exists(destination) then fs.delete(destination) end
            if fs.exists(previous) then fs.copy(previous, destination) end
        end
        return nil, err
    end
    return true
end

function Updater.download(config, role)
    local manifestText, err = get(config.updateManifest)
    if not manifestText then return nil, err end
    local manifest = textutils.unserialiseJSON(manifestText)
    local release = manifest and manifest.channels and manifest.channels[config.releaseChannel]
    local bundleUrl = release and release.roles and release.roles[role]
    if not bundleUrl then return nil, "No " .. role .. " bundle in update manifest" end
    local bundleText, bundleErr = get(bundleUrl)
    if not bundleText then return nil, bundleErr end
    local bundle = textutils.unserialiseJSON(bundleText)
    if not bundle then return nil, "Could not decode update bundle" end
    fs.makeDir("/cc-storage/cache")
    writeAtomic("/cc-storage/cache/" .. role .. ".json", bundleText)
    return bundle, release.version
end

function Updater.update(config, role)
    local bundle, version = Updater.download(config, role)
    if not bundle then return nil, version end
    local ok, err = installBundle(bundle)
    if not ok then return nil, err end
    writeAtomic("/cc-storage/version", tostring(version))
    return version
end

function Updater.installBundle(bundle)
    return installBundle(bundle)
end

function Updater.rollback()
    local backup = "/cc-storage/update-backup"
    if not fs.exists(backup) then return nil, "No update backup exists" end
    local function restore(directory, prefix)
        for _, name in ipairs(fs.list(directory)) do
            local source = fs.combine(directory, name)
            local relative = prefix == "" and name or fs.combine(prefix, name)
            if fs.isDir(source) then restore(source, relative)
            else
                local destination = "/" .. relative
                fs.makeDir(fs.getDir(destination))
                if fs.exists(destination) then fs.delete(destination) end
                fs.copy(source, destination)
            end
        end
    end
    restore(backup, "")
    return true
end

return Updater
