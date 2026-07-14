# Inventory

## Purpose
- `PNC_Inventory` owns the player-like NPC inventory tree: hands, worn items, attachments, carried containers, and nested bag contents.
- abstract NPC simulation reads compact carry summaries instead of walking the full container tree every tick.

## Owned Data
- `inventory.revision`
- `inventory.equipped`
- `inventory.worn`
- `inventory.attached`
- `inventory.items`
- `inventory.containers`
- template-plus-delta persistence state for recruited and unrecruited NPCs
- stable semantic template keys and generator revision
- derived carry caches such as used and remaining weight
- revision-bound summaries that do not require full inventory hydration

## Public Functions
- `PNC.Inventory.CreateFromTemplate(record)`
- `PNC.Inventory.EnsureRecordInventory(record)`
- `PNC.Inventory.ApplyDelta(record, ops, reason)`
- `PNC.Inventory.GetWeightState(record)`
- `PNC.Inventory.BuildSummaryPayload(record)`
- `PNC.Inventory.BuildFullPayload(record)`
- `PNC.Inventory.BuildDeltaPayload(record, sinceRevision)`
- `PNC.Inventory.Serialize(record)`
- `PNC.Inventory.Deserialize(record, rawInventory)`

## Module Layout
- `PNC_Inventory.lua` is the stable subsystem facade and load-order entry point.
- `PNC_Inventory_Model.lua` loads focused model modules for runtime/revision state,
  container membership, and item/carry-cache mechanics.
- `PNC_Inventory_Templates.lua` owns deterministic template generation.
- `PNC_Inventory_Equipment.lua` loads record hydration and legacy equipment-sync modules.
- `PNC_Inventory_Mutations.lua` validates and records inventory operations.
- `PNC_Inventory_Payloads.lua` builds summary, full, and incremental network payloads.
- `PNC_Inventory_Persistence.lua` owns the public serializer/hydrator and delegates
  template-delta encoding and replay to its delta codec.

Implementation modules communicate through `PNC.Inventory.Internal`; consumers should
continue to call only the public `PNC.Inventory` functions.

## Forbidden Responsibilities
- does not own persistence schema migration
- does not broadcast packets directly
- does not decide AI jobs
- does not materialize world items on its own

## Load-Order Contract
- skill-derived carry capacity resolves `PNC.Skills` when inventory creation runs, because inventory is loaded before the skills subsystem during shared bootstrap
- do not capture later-loaded collaborators in file-local variables at module load time
- generator updates rebase the current template and replay valid semantic deltas
