base64 = require('_cd_pipeline._base64')

local cd = {}

function cd.getGitHubFile(url)
    local response = textutils.unserialiseJSON(http.get(url).readAll())
    print("Got "..tostring(response.name).." from GitHub")
    return response.name, base64.decode(response.content), response.path
end

function cd.updateFiles(label, fileMap)
    if not fileMap[label] then
        print("File map does not contain the label "..tostring(label))
        return false
    end

    -- make directory if it doesn't exist
    pcall(fs.makeDir, "_cd_pipeline")

    -- get each file and update
    for _, url in pairs(fileMap[label]) do
        local filename, content, path = getGitHubFile(url)

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