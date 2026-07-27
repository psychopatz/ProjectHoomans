# Persistence

## Purpose
- `PNC_Persistence` owns save-schema versioning, serialization, hydration, and runtime rehydrate rules.
- `PNC_Registry` delegates all long-lived record writes to this subsystem.

## Owned Data
- v8 versioned per-NPC persisted schema
- `PNC_Core_Global.records` directory pointers
- isolated `PNC_NPC_<id>` record tables
- canonical persisted fields only
- nested `identity` payload
- compact `inventory` payload
- body-part wounds and infection timing, stage, progress, fever, and temperature
- runtime rebuild defaults after load
- dirty-record tracking and v4 monolithic-store migration
- save-time position/stamina snapshots and v5-v7 per-record compaction migration

## Public Functions
- `PNC.Persistence.SerializeRecord(record)`
- `PNC.Persistence.DeserializeRecord(raw, fallbackID)`
- `PNC.Persistence.LoadAll(serializedRecords)`
- `PNC.Persistence.SaveAll(records)`
- `PNC.Persistence.RebuildRuntime(record)`
- `PNC.Registry.MarkDirty(record, domain)`
- `PNC.Registry.FlushDirty()`

## Storage Rules
- the global directory never contains full NPC record bodies
- inventory payloads remain unhydrated after load until gameplay or UI needs them
- schema v8 writes body-part health as one common `partBase` plus exceptional
  part overrides. Standard 100-point parts use a number instead of a
  `{ current, max }` table
- health aggregate totals, wound counts, bleeding totals, wall-clock combat
  visibility, revive protection, stamina maximum/state, carry totals, and
  encumbrance are derived instead of treated as authoritative save fields
- stamina persistence contains only a non-full current value; maximum stamina
  is rebuilt from skills and current encumbrance
- non-patrol records do not persist their generated fallback patrol point
- zero skill deltas and zero XP values are omitted
- equipment and inventory summaries are explicitly retained as lazy-hydration
  caches. Inventory item/delta state remains authoritative and repairs those
  caches when hydrated
- continuous live movement and passive stamina recovery update runtime records
  without calling `MarkDirty` every tick. `FlushDirty` compares compact saved
  snapshots and dirties only records whose position or stamina actually
  differs at save time
- records loaded from an older per-NPC schema are accepted, marked
  `schema_migration`, and rewritten as v8 on the next save
- full NPC records never persist after death. The registry directory instead
  keeps a minimal `deathMarkers` map with identity, name, position, corpse token,
  infection state, and delay metadata
- a death marker is removed once its recorded square is loaded and the matching
  vanilla corpse is absent; legacy persisted dead records migrate into this
  compact form during registry load
- persistence ModData is server-only and is never broadcast with `ModData.transmit`
- Project Zomboid still writes all named ModData tables to its single global save file
- v4 migration keeps `NPCs` as the fallback until every expected per-NPC table is written and verified
- failed record serialization or writes remain dirty and retry on a later save

## Scale Contract

- persistence cost must remain `O(N + I)`, where `N` is NPC records and `I` is
  actual inventory delta entries. Runtime targets, path state, spatial
  membership, network interest sets, UI state, and inventory operation logs
  must never enter the save
- 100 persistent NPCs is a supported baseline. This does not promise that 100
  bodies may run full live AI at once; presence, scheduling, spatial indexing,
  and interest replication own that separate runtime budget
- the scheduler processes at most 24 due NPC records per server tick and
  defers overflow; the spatial index performs its loaded player/zombie scan no
  more often than every 100 ms unless stale-ID recovery explicitly forces it
- `tests/pnc_persistence_scale_smoke.lua` creates 100 NPCs with forty acquired
  items each, compact wounds, and deterministic template inventories. Its
  serializer-size proxy must remain below 5 MiB and every compact field must
  round-trip
- `tests/pnc_persistence_v5_smoke.lua` verifies that continuous movement stays
  clean during normal ticks but is captured by the next save snapshot

## Forbidden Responsibilities
- does not materialize live bodies
- does not own targets, path caches, or combat scratch state
- does not build client snapshots
