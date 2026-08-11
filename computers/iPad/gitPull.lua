-- Compatibility alias for older installations. Updates now use immutable role
-- bundles instead of one GitHub API request per source file.
local branch = ...
local manifest = branch and branch ~= "" and
    ("https://raw.githubusercontent.com/TheCakeOfRice/computercraft/" .. branch .. "/releases/manifest.json") or nil
if fs.exists("install.lua") then
    if manifest then shell.run("install", "iPad", manifest)
    else shell.run("install", "iPad") end
else
    error("install.lua is missing; download the bootstrap installer first", 0)
end
