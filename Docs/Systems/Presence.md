# Presence

## States
- `live`: embodied zombie actor exists
- `abstract`: record only, no embodied actor exists
- `corpse`: dead state

## Guarantees
- abstracting a living NPC removes the live zombie body immediately
- no hidden or parked zombie is kept around for abstract travel
- materialization always spawns a fresh body from authoritative record state
- multiplayer snapshots identify that body primarily by the engine zombie
  online ID; persistent outfit IDs are only a collision-checked fallback and
  must never be treated as unique actor identity

## Current Implementation
- server checks player distance with hysteresis
- `Materialize` uses `addZombiesInOutfit(...)`
- unresolved live snapshots temporarily use a faster client body scan, then
  return to the normal low-frequency scan after binding
- `Abstract` snapshots current position and calls:
  - `removeFromWorld()`
  - `removeFromSquare()`

## Body Lifecycle Ownership

`PNC_BodyLifecycle.lua` is a stable facade. Implementation modules under
`Presence/PNC_BodyLifecycle/` own one lifecycle concern each:

- `State`: record lifecycle state, cleanup notes, audit counters, and ID normalization
- `World`: low-level zombie/corpse removal, combat cleanup, and corpse iteration
- `CorpseItems`: canonical inventory and visual-item materialization
- `CorpseWornItems`: worn-item capture, corpse transfer, and network transmission
- `LiveBodies`: live-body stamping, leases, detachment, and removal transitions
- `Corpses`: live-to-corpse conversion and corpse identity stamping
- `CorpseAudit`: delayed corpse finalization and bounded corpse-record supervision
- `Audit`: loaded-world live-body reconciliation and orphan/duplicate cleanup
- `Diagnostics`: read-only lifecycle data for debug surfaces

Callers should depend on the facade methods. New lifecycle behavior belongs in
the narrowest internal module so corpse policy, engine operations, and audit
rules can evolve without growing a central coordinator again.
