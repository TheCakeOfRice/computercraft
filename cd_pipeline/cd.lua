base64 = require("_cd_pipeline._base64")

local cd = {}

function cd.getGitHubFile(url, token)
    local request = {
        url = url,
        method = "GET",
        headers = {
            ["Authorization"] = "Bearer " .. token,
            ["Accept"] = "application/vnd.github+json"
        }
    }
    local response = http.get(request)
    if not response then
        print("Failed to get "..tostring(url))
        return nil
    end
    local body = textutils.unserialiseJSON(response.readAll())
    print("Got "..tostring(body.name).." from GitHub")
    return body.name, base64.decode(body.content), body.path
end

function cd.updateFiles(label, fileMap, token)
    if not fileMap[label] then
        print("File map does not contain the label "..tostring(label))
        return false
    end

    -- make directory if it doesn't exist
    pcall(fs.makeDir, "_cd_pipeline")

    -- get each file and update
    for _, url in pairs(fileMap[label]) do
        local filename, content, path = cd.getGitHubFile(url, token)

        -- check if file is in _cd_pipeline
        local isCDFile = string.find(path, "_cd_pipeline")
        if isCDFile then
            filename = "_cd_pipeline/"..filename
        end

        -- delete and replace file
        pcall(fs.delete, filename)
        local file = fs.open(filename, "w")
        file.write(content)
        file.close()
        print(" -- Updated "..filename)
    end

    return true
end

return cd