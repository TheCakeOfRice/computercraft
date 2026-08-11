# CC Storage

A CC:Tweaked storage and autocrafting platform for Minecraft. A single storage
computer owns the inventory cache, client API, durable crafting queue, worker
registry, and software cache. Pocket computers and automation workers discover
it through Rednet instead of relying on fixed computer IDs.

## Minimum build

- One advanced computer for the storage/coordinator service.
- A wired modem and cable connecting it to storage inventories.
- A wireless or ender modem when using a remote pocket computer.
- Separate deposit and withdrawal inventories.
- An optional monitor.

APIServer is no longer a required computer. Its responsibilities have moved
into StorageCPU and remain isolated in coordinator modules so they can be split
onto another computer later if scale requires it.

## Install

On the first storage computer, download the small public bootstrap and run it:

```text
wget https://raw.githubusercontent.com/TheCakeOfRice/computercraft/master/install.lua install
install StorageCPU
```

The setup wizard discovers modems and inventories, asks which inventories are
deposit and withdrawal, and stores world-specific configuration in
`/cc-storage/config.json`. Source files contain no computer IDs, peripheral
sides, or GitHub credentials.

Install a pocket or worker with the corresponding role:

```text
install iPad
install MacGyver
install PowerCPU
```

Once the storage server has cached role bundles, an already-downloaded
bootstrap can provision from the Minecraft network without contacting GitHub:

```text
install MacGyver network
```

For a completely zero-download new computer, modpack/server owners may ship
`install.lua` as a custom ROM program. Vanilla CC:Tweaked cannot remotely write
to a blank computer before some bootstrap program is run.

## Operations

Run these on the storage computer:

```text
storage doctor
storage configure
storage rescan
storage jobs
storage craft minecraft:chest 4
storage update
storage rollback
```

`storage update` downloads one generated bundle per role, installs the server
bundle atomically, and caches worker/client bundles for network provisioning.
Only the storage server needs GitHub access.

## Runtime design

- `inventory.lua` discovers generic inventory peripherals, scans with one
  `list()` call per inventory, caches display details, and periodically
  reconciles out-of-band changes.
- `coordinator.lua` persists jobs and reservations under `/cc-storage`.
- `planner.lua` expands recipe dependencies, detects cycles, computes batches,
  and emits operations in dependency order.
- Crafting turtles register the `crafting_turtle` capability and execute one
  assigned operation at a time through a staging chest.
- All messages use the `cc-storage/v1` protocol, request IDs, and Rednet service
  discovery (`main` by default).

See [docs/AUTOCRAFTING.md](docs/AUTOCRAFTING.md) for job and recipe details.

## Development and releases

Run `python3 ci_pipeline/ci.py` before committing a release. It retains the
legacy Contents-API file map for migrations and generates compact JSON bundles
under `releases/`. Each installation needs a manifest request and one bundle
request rather than one API request per file per computer.
