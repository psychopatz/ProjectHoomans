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
