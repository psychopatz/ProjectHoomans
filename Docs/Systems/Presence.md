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
- infected corpse reanimation is authority-only: the server invokes the vanilla
  corpse handoff once, clears every PNC identity/control flag and human-NPC
  safeguard, and removes the death marker; clients receive the resulting zombie
  through vanilla replication and never run their own conversion
- all full NPC records are retired at death. `PNC_DeathMarkers` persists only
  UUID, name, death position, corpse token, infection flag, and reanimation
  delay; when the recorded square is loaded and the matching corpse remains
  absent beyond the short finalization grace, the marker is automatically deleted
- `PNC_BodyLifecycle.BuildDebugRoster` merges live/abstract records and compact
  death markers for both local and remote NPC-monitor requests
- local monitor refreshes run the normal throttled body/corpse audit, so
  single-player marker cleanup does not depend on a remote server response
- uninfected corpses remain ordinary engine corpses. PNC does not tick their
  health, inventory, appearance, decomposition, or removal
- every immediate and delayed corpse-finalization path idempotently ensures the
  named identity card on the final vanilla corpse before replication; infected
  and uninfected deaths use the same path
- corpse item mutation is authority-only. PNC uses
  `PsychopatzCore.CorpseItems`, avoids per-item packets during
  `IsoDeadBody` construction, and sends one completed-corpse update after
  identity, worn items, and death-marker metadata are final

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
- `CorpseItems`: PNC inventory/identity policy layered over PsychopatzCore's
  reusable keyed corpse-item injection service
- `CorpseWornItems`: worn-item capture, corpse transfer, and network transmission
- `LiveBodies`: live-body stamping, leases, detachment, and removal transitions
- `Corpses`: live-to-corpse conversion and corpse identity stamping
- `Reanimation`: infection timing, single-spawn guards, vanilla corpse handoff,
  fallback creation, safeguard cleanup, and permanent release from PNC ownership
- `CorpseAudit`: delayed corpse finalization and bounded lightweight-marker supervision
- `Audit`: loaded-world live-body reconciliation and orphan/duplicate cleanup
- `Diagnostics`: read-only lifecycle data for debug surfaces

Callers should depend on the facade methods. New lifecycle behavior belongs in
the narrowest internal module so corpse policy, engine operations, and audit
rules can evolve without growing a central coordinator again.
