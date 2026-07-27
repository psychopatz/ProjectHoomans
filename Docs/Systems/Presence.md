# Presence

## States
- `live`: embodied zombie actor exists
- `abstract`: record only, no embodied actor exists
- `corpse`: dead state

## Guarantees
- abstracting a living NPC removes the live zombie body immediately
- no hidden or parked zombie is kept around for abstract travel
- materialization always spawns a fresh body from authoritative record state
- every fresh live body starts from the engine's `Naked` outfit, then PNC
  reapplies the identity-seeded human appearance and record-owned equipment.
  `Naked` is a disposable shell baseline, not the NPC's final visible outfit
- persistence stores only a compact previous body-instance hint. On launch the
  authority runs all required shell-cleanup passes synchronously from both
  `OnServerStarted` and `OnGameStart` before materialization is allowed;
  it removes old UUID/lease-tagged bodies and naked legacy shells that match an
  abstract record's saved position or body hint, then spawns one fresh body
- an early `OnZombieUpdate` interceptor handles any shell exposed between world
  loading callbacks. A matched shell receives no-teeth, no-target, useless, and
  no-lunge flags directly before it is removed, including legacy naked shells
  that lost all PNC modData
- replacement materialization waits only 50 ms after a repaired shell. The
  previous multi-tick startup delay is no longer part of the normal path
- naked cleanup is deliberately identity/position constrained. PNC does not
  delete unrelated naked vanilla zombies elsewhere in the world
- materialization performs the same record-local cleanup immediately before
  spawning. This covers distant cells that stream in after the startup passes
- steady-state materialization preflight combines the small lifecycle-candidate
  census with a local 3.5-tile spatial zombie query; materializing several NPCs
  no longer multiplies a full loaded-zombie scan per NPC
- stale removals replicate through an instance-specific `RemoveBody` command
  sent to every connected player. Remote clients also retain exactly one
  canonical online-ID/lease/instance body per NPC snapshot and prune older
  local duplicates; record removal remains a separate command
- every live-body maintenance lane reapplies `isUseless`, clears vanilla
  target/aggro, removes teeth, applies the `NotAZombie` descriptor voice prefix,
  and performs Bandits-compatible suppression of all six Build 42 male/female
  zombie voice channels. The recurring pass stops only zombie vocals, so
  intentional firearm, melee, door, and treatment sounds remain audible
- human safety is enforced from `OnZombieUpdate`, before the remainder of
  vanilla zombie AI, as well as from client/server world-ready scans. This
  closes the relog window where a persisted body could update before registry
  reconciliation. The authority audit also neutralizes each recognized body
  before accepting, rebinding, or removing its lease
- legacy bodies remain recognizable through current modData plus the older
  `PNCLive`/`PNCActor` variables. Infected corpse reanimation clears those
  variables and explicitly restores `isUseless=false` and teeth before vanilla
  takes ownership, so released zombies are not caught by the human safeguard
- client replicas correct vanilla `IsoPlayer.updateLOS` when its zombie set
  contains managed human NPC bodies. PNC uses the supported `Stats` API for
  visible/chasing counters and, because Build 42 has no very-close-counter
  setter, performs a synchronous second LOS pass with only managed bodies
  temporarily excluded through the engine's grapple-only LOS flag. The flag is
  restored before the callback returns and is never persisted or replicated
- the corrected counters feed vanilla sleep unchanged, so a nearby PNC human
  no longer produces `IGUI_Sleep_NotSafe` or wakes a sleeping player as a
  zombie. A dedicated client patch refreshes those counters immediately before
  the vanilla sleep handler; any ordinary zombie remains counted and still
  blocks sleep
- single-player fast-forward intent is sampled by `OnPlayerUpdate` immediately
  before vanilla LOS and checked by `OnTick` after the world update. If a
  temporary filtered recount proves that only managed bodies caused the reset,
  PNC invokes the unmodified vanilla speed-control method; it never replaces a
  Java-owned UI method. Player interruptions and ordinary zombies still cancel
  time acceleration normally
- human-body maintenance clears any leaked grapple-only flag from older saves,
  recovering the NPC's standing posture; the flag exists only during the
  synchronous filtered LOS recount and cannot reach NPC update or replication
- while the AI debug overlay is enabled, the safeguard emits cadence-bounded
  `human_safeguard` counter decisions and one `sleep_gate` line per sleep
  attempt with visible/chasing/very-close counters before and after correction
  plus the remaining panic value
- managed humans are pre-seeded as already spotted so the false surprise sting
  is never started. PNC does not hard-stop player audio; any visible ordinary
  zombie leaves vanilla fear behavior untouched
- companions following an owner transactionally reserve an installed,
  currently free vehicle seat when they reach the owner's car. The authority
  first adds a private weighted reservation item to that seat container, which
  makes vanilla `BaseVehicle:isSeatOccupied()` enforce the capacity, and only
  then removes the live body. PNC tracks the companion as an `abstract`
  passenger at a 100 ms cadence; no `IsoZombie` is attached to the vehicle
- each reservation is one NPC to one real seat. Vanilla entry/switch checks,
  other PNC companions, and the vehicle seat UI all see that consumed capacity.
  The client blocks vanilla's "move items from seat" and inventory-transfer
  paths from treating the reservation as movable luggage
- reservations are authority-created and synchronized through the vehicle
  container item lane. They are released on disembark, vehicle transfer,
  abstraction rollback, seat loss, and NPC death. A bounded server audit
  removes duplicates, tokens moved outside their seat, and stale save/crash
  remnants whose NPC no longer has the matching runtime passenger state
- when the owner exits, normal safe-square materialization handles
  disembarkation. Changing vehicles transfers the abstract reservation without
  creating an intermediate body. A disconnect clears the reservation and,
  unless another player is nearby, resumes normal abstract owner-missing
  behavior from the last vehicle position
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
- server checks player distance with hysteresis through the player spatial
  index, computing the nearest result once per reconciliation
- a 250 ms player-interest wake pass schedules nearby abstract records even
  when their far/dormant AI cadence is sleeping; materialization responsiveness
  therefore does not depend on a distant NPC's next AI decision
- range-entry body creation is limited to two NPCs per server tick. Deferred
  records keep a 50 ms presence-wake cadence until their body is created
- live position reads occur with each budgeted record update, with a slower
  one-second whole-live-set pass retained only as an integrity safety net
- `Materialize` uses `addZombiesInOutfit(...)`
- `Materialize` always requests `Naked`, then applies human visuals and
  equipment from the canonical record
- unresolved live snapshots temporarily use a faster client body scan, then
  return to the normal low-frequency scan after binding
- `Abstract` snapshots current position and calls:
  - `removeFromWorld()`
  - `removeFromSquare()`
- the loaded-body audit consumes `PNC_WorldCensus`, sharing the same engine
  enumeration used by spatial indexing instead of scanning all zombies again

## Body Lifecycle Ownership

`PNC_BodyLifecycle.lua` is a stable facade. Implementation modules under
`Presence/PNC_BodyLifecycle/` own one lifecycle concern each:

- `State`: record lifecycle state, cleanup notes, audit counters, and ID normalization
- `World`: low-level zombie/corpse removal, combat cleanup, and corpse iteration
- `CorpseItems`: PNC inventory/identity policy layered over PsychopatzCore's
  reusable keyed corpse-item injection service
- `CorpseWornItems`: worn-item capture, corpse transfer, and network transmission
- `LiveBodies`: live-body stamping, leases, detachment, and removal transitions
- `Startup`: persisted-shell detection, startup materialization gate,
  record-local preflight cleanup, naked legacy-shell matching, and body-instance
  removal replication
- `Corpses`: live-to-corpse conversion and corpse identity stamping
- `Reanimation`: infection timing, single-spawn guards, vanilla corpse handoff,
  fallback creation, safeguard cleanup, and permanent release from PNC ownership
- `CorpseAudit`: delayed corpse finalization and bounded lightweight-marker supervision
- `Audit`: loaded-world live-body reconciliation and orphan/duplicate cleanup
- `Diagnostics`: read-only lifecycle data for debug surfaces

Callers should depend on the facade methods. New lifecycle behavior belongs in
the narrowest internal module so corpse policy, engine operations, and audit
rules can evolve without growing a central coordinator again.
