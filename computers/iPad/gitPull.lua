os.loadAPI("vars.lua")
base64 = require('base64')

term.clear()

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

-- get file map
local branch = arg[1] or "mulungus-server"
local mapURL = "https://api.github.com/repos/TheCakeOfRice/computercraft/contents/ci_pipeline/file_map.json?ref="..tostring(branch)
local _, fileMap = getGitHubFile(mapURL)
fileMap = textutils.unserializeJSON(fileMap)

-- update files on iPad
local pulled = updateFiles("iPad", fileMap)

-- ping StorageCPU to initate a pull request from each network PC
rednet.open("back")
rednet.send(vars.STORAGE_CPU, { method="gitPull", fileMap=fileMap, updateFiles=updateFiles })
local _, message = rednet.receive(nil, 10)
print(message)

if pulled then os.reboot() end
