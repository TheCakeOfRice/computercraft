# computercraft

Contains code using the computercraft and advanced peripherals mod APIs for minecraft.  Implements a storage system centered around a computer (StorageCPU) using an inventory manager for player access and an advanced ender pocket computer (iPad) as an interface.

To use the code, you must have vanilla chests connected to StorageCPU using wired modems, and the program will access them as blob storage.  An inventory manager must also be connected to the network, with a vanilla chest on both the left and right (when placing the manager).  These chests control input and output of the system and should not be used for storage.  To use the iPad, connect an ender modem (default right) to the StorageCPU.  Once set up, ensure that the vars files in both the StorageCPU and iPad match the IDs of the peripherals in your network.

## Current pastebins (9/10/23):
### StorageCPU
* vars.lua - https://pastebin.com/zVQSpqsr
* funcs.lua - https://pastebin.com/2id6xpGG
* startup.lua - https://pastebin.com/VM8i5rYJ

### iPad
* vars.lua - https://pastebin.com/h7d4E4hJ
* funcs.lua - https://pastebin.com/AC2y8awj
* startup.lua - https://pastebin.com/0pU0iU2v
* gui.lua - https://pastebin.com/YJZDEpTe
