# Storage roadmap

## Inventory durability

- Add a reconciliation report which shows slot-level cache differences.
- Persist the last known inventory snapshot for crash diagnostics.
- Add configurable reconciliation groups for very large or cold storage.
- Evaluate an RS Bridge adapter as an optional inventory backend.

## Autocrafting

- Add an in-game recipe editor and import more normalized recipes.
- Model reusable tools, container items, byproducts, tags, and alternative recipes.
- Add machine-worker capabilities for furnaces and modded processors.
- Add explicit recovery actions for `WORKER_LOST` jobs.
- Add worker heartbeats, stale-worker detection, and optional redstone status lamps.
- Add staging-inventory assignment to the setup/configuration UI.

## Client experience

- Add craft, job progress, cancellation, and reprioritization screens to iPad.
- Replace blocking text prompts with a consistent windowed UI.
- Display actionable network and inventory errors instead of generic failure states.

## Power monitoring

- Track RF input/output rate and total stored RF.
- Add controlled generator enable/disable actions.

## Security and releases

- Sign release manifests or add a checksum implementation available in CraftOS.
- Add optional message authentication for untrusted multiplayer Rednet networks.
- Publish immutable GitHub Release assets instead of branch-backed development bundles.
