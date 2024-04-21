local vars = require("vars")
local cd = require("_cd_pipeline._cd")

term.clear()

-- get file map
local branch = arg[1] or "master"
local mapURL = "https://api.github.com/repos/TheCakeOfRice/computercraft/contents/ci_pipeline/file_map.json?ref="..tostring(branch)
local _, fileMap = cd.getGitHubFile(mapURL)
fileMap = textutils.unserializeJSON(fileMap)

-- update files on iPad
local pulled = cd.updateFiles("iPad", fileMap)

-- ping StorageCPU to initate a pull request from each network PC
rednet.open("back")
rednet.send(vars.STORAGE_CPU, { method="gitPull", fileMap=fileMap })
local _, message = rednet.receive(nil, 10)
print(message)

if pulled then os.reboot() end
