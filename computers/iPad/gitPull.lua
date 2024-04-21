local vars = require("vars")
local cd = require("_cd_pipeline._cd")
local env = require("env")

term.clear()

-- get file map
local branch = arg[1] or "master"
local mapURL = "https://"..env.GITHUB_API_KEY.."@api.github.com/repos/TheCakeOfRice/computercraft/contents/ci_pipeline/file_map.json?ref="..tostring(branch)
local _, fileMap = cd.getGitHubFile(mapURL)
fileMap = textutils.unserializeJSON(fileMap)

-- add PAT in URLs
local prefix = "http://"
for cpuName, url in pairs(fileMap) do
    local suffix = string.sub(url, #prefix + 1, #url)
    fileMap[cpuName] = prefix..env.GITHUB_API_KEY.."@"..suffix
end

-- update files on iPad
local pulled = cd.updateFiles("iPad", fileMap)

-- ping APIServer to initate a pull request from each network PC
rednet.open("back")
rednet.send(vars.API_SERVER, { method="gitPull", fileMap=fileMap })
local _, message = rednet.receive(nil, 10)
print(message)

if pulled then os.reboot() end
