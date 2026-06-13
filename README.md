# Intro
Contains code using the computercraft API for minecraft.  Implements a storage system centered around a computer (StorageCPU) and an advanced ender pocket computer (iPad) as an interface.

Python pre-commits are used to stage GitHub API URLs in ci_pipeline/file_map.json for import using the in-game cd_pipeline.  Access "git pull" from the iPad to pull latest changes from GitHub.

# Minimum requirements
- Advanced Ender Pocket Computer -- labeled *iPad*
- Two computers -- labeled *StorageCPU* and *APIServer*
- Two ender modems -- one for each computer
- Networking cable and modems to connect the computers to chests
- One reserved chest which will be used as a player interface -- *recommended: ender chest*
- A disk drive

# Setup
To jump-start your system, you need to upload a few files to Pastebin and then `pastebin get` them on your iPad.
- `~/gitPull.lua`
- `~/_cd_pipeline/_base64.lua`
- `~/_cd_pipeline/_cd.lua`

You will also need to create a file `~/env.lua` which contains a GitHub personal access token, for use as a GitHub API key.
<blockquote>
local env = {
    GITHUB_API_KEY = "your_token_here"
}

return env
</blockquote>

On your working branch, make sure that your `vars.lua` files accurately represent ids for your in-game setup, or else connections between computers will not work.

You then can begin downloading source files from GitHub.  This is completed in a two-step pull process:
1. Run `gitPull <branchname>` from your iPad terminal.  This will download all iPad source files, including `~/cd_catalyst.lua`.
2. Use your disk drive to `cp disk/_cd_pipeline .` and `cp disk/cd_catalyst.lua .` on all other computers in your network that need to pull files from GitHub.  Run `cd_catalyst` to start listening for requests.
3. Run `gitPull` from your iPad terminal again.  This will forward the pull message to APIServer, which is listening for this event as a result of `cd_catalyst`.
4. APIServer will forward the message to all computers and turtles in the network, triggering setup.