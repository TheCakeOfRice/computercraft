# computercraft

Contains code using the computercraft and advanced peripherals mod APIs for minecraft.  Implements a storage system centered around a computer (StorageCPU) using an inventory manager for player access and an advanced ender pocket computer (iPad) as an interface.

To use the code, you must have vanilla chests connected to StorageCPU using wired modems, and the program will access them as blob storage.  An inventory manager must also be connected to the network, with a vanilla chest on both the left and right (when placing the manager).  These chests control input and output of the system and should not be used for storage.  To use the iPad, connect an ender modem (default right) to the StorageCPU.  Once set up, ensure that the vars files in both the StorageCPU and iPad match the IDs of the peripherals in your network.

Python pre-commits are used to stage GitHub API URLs in ci_pipeline/file_map.json for import using the in-game cd_pipeline.  Access "git pull" from the iPad to pull latest changes from GitHub.
