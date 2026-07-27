# Persistence

## Purpose
- `PNC_Persistence` owns save-schema versioning, serialization, hydration, and runtime rehydrate rules.
- `PNC_Registry` delegates all long-lived record writes to this subsystem.

## Owned Data
- v5 versioned per-NPC persisted schema
- `PNC_Core_Global.records` directory pointers
- isolated `PNC_NPC_<id>` record tables
- canonical persisted fields only
- nested `identity` payload
- compact `inventory` payload
- body-part wounds and infection timing, stage, progress, fever, and temperature
- runtime rebuild defaults after load
- dirty-record tracking and v4 monolithic-store migration

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
- full NPC records never persist after death. The registry directory instead
  keeps a minimal `deathMarkers` map with identity, name, position, corpse token,
  infection state, and delay metadata
- a death marker is removed once its recorded square is loaded and the matching
  vanilla corpse is absent; legacy persisted dead records migrate into this
  compact form during registry load
- persistence ModData is server-only and is never broadcast with `ModData.transmit`
- Project Zomboid still writes all named ModData tables to its single global save file
- v4 migration keeps `NPCs` as the fallback until every expected v5 table is written and verified
- failed record serialization or writes remain dirty and retry on a later save

## Forbidden Responsibilities
- does not materialize live bodies
- does not own targets, path caches, or combat scratch state
- does not build client snapshots
