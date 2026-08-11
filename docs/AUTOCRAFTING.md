# Autocrafting architecture

## Planning

Recipes are normalized records keyed by their output item. The planner expands
a requested item backward, consumes unreserved physical inventory first, and
then schedules recipes for the missing quantity. Operations are appended after
their dependencies, producing an execution-ready topological order. A visiting
set rejects recipe cycles.

Recipe records contain separate aggregated `ingredients` for planning and a
nine-entry `grid` for shaped turtle execution. Empty shaped slots use `false`,
never `nil`, so the Lua sequence remains dense.

## Reservations and jobs

Creating a job reserves the physical ingredients selected by its plan. Other
plans subtract these reservations before deciding that an item is available.
Jobs and reservations are written atomically to `/cc-storage/state.json`.

Current states are:

- `READY`: an operation may be claimed by a capable worker.
- `DISPATCHED`: a worker owns the current operation.
- `COMPLETE`: every operation succeeded.
- `WORKER_LOST`: execution failed and requires inspection/recovery.
- `CANCELLED`: the user cancelled the job and its reservations were released.

The state model deliberately exposes failure instead of automatically retrying
inventory movement, which could duplicate or lose items after an ambiguous
worker disconnect.

## Workers

A worker registers a name and capability list, polls for one compatible
operation, stages exact ingredients, executes each batch, deposits output, and
reports success or failure with the job ID. The coordinator is the only owner
of dependency planning and queue priority.

Each crafty turtle should have a dedicated chest in front of it. Its configured
`CRAFTING_CHEST` must refer to that peripheral. For reliable multi-worker use,
staging inventories should not also be used as general storage.

## Extending recipes

Machine processing recipes should follow the same record shape, substituting a
machine capability and explicit inputs/outputs. Alternative recipes should be
selected explicitly at first; automatic tag substitution and cost optimization
should be added only after container items, tools, and byproducts are modeled.
