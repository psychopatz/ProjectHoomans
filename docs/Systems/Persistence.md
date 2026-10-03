# Persistence

## Purpose
- `PNC_Persistence` owns save-schema versioning, serialization, hydration, and runtime rehydrate rules.
- `PNC_Registry` delegates all long-lived record writes to this subsystem.

## Owned Data
- versioned per-NPC persisted schema, with exact-version reset semantics
- `PNC_Core_Global.records` directory pointers
- isolated `PNC_NPC_<id>` record tables
- canonical persisted fields only
- nested `identity` payload
- compact `inventory` payload
- sparse, directed `social` relationship and memory payload
- separate `PNC_PlayerCharacters` player-character registry schema v6
- separate `PNC_Factions` organizational/diplomacy/emblem/mobile registry schema v6
- primitive NPC affiliation schema v2, including optional community identity
- separate `PNC_Communities` community/site registry schema v2
- body-part wounds and infection timing, stage, progress, fever, and temperature
- optional NPC `needs` schema V2 for player-owned/recruited individual Needs
- optional mobile-faction state schema V3, including aggregate group Needs
- runtime rebuild defaults after load
- dirty-record tracking and explicit reset diagnostics
- save-time position/stamina snapshots and current-version compaction

## Public Functions
- `PNC.Persistence.SerializeRecord(record)`
- `PNC.Persistence.DeserializeRecord(raw, fallbackID)`
- `PNC.Persistence.LoadAll(serializedRecords)`
- `PNC.Persistence.SaveAll(records)`
- `PNC.Persistence.RebuildRuntime(record)`
- `PNC.Registry.MarkDirty(record, domain)`
- `PNC.Registry.FlushDirty()`
- `PNC.PlayerCharacters.Load()`
- `PNC.PlayerCharacters.Save()`
- `PNC.PlayerCharacters.NormalizeRegistry()`

## Version and Reset Contract

- this unreleased persistence surface intentionally has no migration readers or
  migration writers
- every canonical named ModData root owns an exact schema/layout version
- a missing or empty root is a normal first-run state and is not marked dirty
- an existing root with an older/newer version or malformed shape is discarded
  in memory, replaced with a fresh current-version state, marked dirty, and
  rewritten by the next coordinated save
- reset diagnostics (`LastReset`) are runtime-only and contain the owner,
  reason, source version, target version, and reset timestamp
- nested persisted payloads follow the same owner/version boundary; malformed
  children are dropped and the owning root is dirtied for a clean rewrite
- object, body, corpse, vehicle, and item ModData are projections or leases,
  not canonical global stores. They are versioned where durable and reconciled
  lazily when their owning record/service is accessed; no world-wide scan is
  performed on load or every tick
- only player-owned NPC/colonist records participate in the NPC Needs system;
  unrelated vanilla/player objects are outside this persistence contract

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
- missing Need state is intentionally valid for old saves. Individual state is
  initialized only when existing ownership/recruitment makes it eligible;
  group state is initialized only for an active mobile faction. Need debug
  histories and profiler counters are runtime-only
- player-character identity uses its own Global ModData table and schema.
  Phase 3B adds a UUID-owned primitive social profile to each record
- the player registry's canonical `byUUID` records contain primitives only;
  `byAccount` is a deterministically rebuilt secondary index
- each survivor carries only `PNC_CharacterUUID` and
  `PNC_CharacterIdentityVersion` in player ModData. Runtime player-object and
  UUID bindings are module state and never serialized
- current-version social, affiliation, faction, community, mobile, and player
  registry roots are loaded exactly; unsupported or malformed roots reset to
  their current empty shape and are rebuilt only by current gameplay writes
- full NPC records never persist after death. The registry directory instead
  keeps a minimal `deathMarkers` map with identity, name, position, corpse token,
  infection state, and delay metadata
- a death marker is removed once its recorded square is loaded and the matching
  vanilla corpse is absent
- persistence ModData is server-only and is never broadcast with `ModData.transmit`
- Project Zomboid still writes all named ModData tables to its single global save file
- the registry directory is the only canonical index; isolated NPC rows are
  accepted only when their exact current version and directory identity match
- unreferenced `PNC_NPC_<id>` tables are removed during startup maintenance and
  are never recovered as live records
- failed record serialization or writes remain dirty and retry on a later save

## Deterministic Generated-State Healing

- seed-derived NPC vanilla traits, dynamic traits, and social personality carry
  subsystem generation revisions separate from the root persistence schema
- when a generated revision is stale, the subsystem regenerates from the
  persisted `identitySeed` and `archetypeID`, records the current revision, and
  dirties only that record for lazy rewrite
- authored trait sets, authored personality values, and explicit empty sets are
  never regenerated; generation metadata is not treated as permission to erase
  authored data
- nutrition, needs, health, inventory, relationships, progression, travel,
  conduct, and other mutable state remain untouched by generated-state healing
- adding or changing generated content requires bumping that subsystem's
  generator revision; it does not require an NPC schema migration or a world
  scan
- healing runs during normal record construction/load/access, so existing NPCs
  converge when encountered while CPU and memory cost stay proportional to the
  records already being used

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
