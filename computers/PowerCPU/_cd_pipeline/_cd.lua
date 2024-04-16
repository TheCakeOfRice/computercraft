base64 = require('base64')

function getGitHubFile(url)
    local response = textutils.unserialiseJSON(http.get(url).readAll())
    print("Got "..tostring(response.name).." from GitHub")
    return response.name, base64.decode(response.content)
end

function updateFiles(label, fileMap)
    if not fileMap[label] then
        print("File map does not contain the label "..tostring(label))
        return false
    end

    for _, url in pairs(fileMap[label]) do
        local filename, content = getGitHubFile(url)
        pcall(fs.delete, filename)
        local file = fs.open(filename, "w")
        file.write(content)
        file.close()
        print("Updated "..filename)
    end

    return true
end