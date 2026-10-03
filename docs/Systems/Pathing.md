# Pathing

## V1
- live NPCs use server-owned path requests and embodied path behaviors
- abstract NPCs use coarse world travel
- live NPCs proactively probe the cardinal passage edges toward their current
  goal, opening doors or windows before repeated collision, while blocked-step
  and stall detection remain recovery fallbacks
- fence hopping uses the same server-owned traversal lease, repeat suppression,
  landing validation, and client motion hints as window traversal
- fence and window climbs use one eased server-owned transport segment aligned
  with the hop animation; ordinary locomotion remains blocked until the XML
  `PNCTraversalFinished` signal or a short bounded missing-event fallback
- traversal completion refreshes the obstacle cooldown so a newly refreshed
  follow/combat goal cannot immediately hop back across the same fence
- traversal bump types and completion variables are PNC-only; stale vanilla
  climb-start/outcome variables are reset only when adopting an accidental
  engine climb state, before the PNC bump takes ownership
- fresh follow/combat goals remain pending while traversal owns the body; they
  cannot cancel the bump or restart locomotion midway across a passage
- doors and windows are considered opened only after their engine state reports
  open, then their object/path state is synchronized by the authoritative side
- all path ownership lives in `PNC_PathService`
- cross-domain movement resets use
  `PNC.PathService.Commands.Reset(record, zombie, reason)`. The legacy
  `PNC.PathService.Reset(zombie, record)` method remains supported, but the
  record-first command is canonical and prevents body/record argument reversal
- `PNC.PathService.Queries.IsTraversalActive` is the canonical read boundary;
  its direct-method alias remains supported
- abstract travel is elapsed-time based (`speed × elapsed`) so reducing a far
  NPC's AI cadence does not change its simulated travel speed
- behavior writes `move intent`; only `PNC_PathService.Pump` may start, refresh, cancel, or complete live movement
- repeated move/hold requests reuse their runtime intent table, reducing
  short-lived Kahlua allocations during follow and combat
- continuously moving follow/steering goals use a 0.22-tile retarget
  threshold, avoiding lane-state resets for sub-step owner jitter
- native engine requests are spread across scheduler windows rather than
  allowing a newly moving group to start every A* search in one frame
- follower slot membership and owner heading are shared per owner for 250 ms;
  each follower still updates the cached slot against the owner's live position
- the live move lane uses explicit phases: `idle`, `requested`, `active`, `arrived`, `blocked`, `cancel_pending`
- `walktoward` is a normal locomotion state, not a path-conflict state; recovery is reserved for real combat/thump conflicts so valid movement is not reset every tick
- live path refresh now routes through a single move lane, which matches the Bandits-style "one active move action" flow more closely and avoids stacked `path2` state churn
- close-range combat approach now softens from `run` to `walk` so embodied chase looks less robotic near contact range
- combat target reassessment uses a short interval and distance hysteresis so
  NPCs can respond to a nearby attacker without stop-stepping between nearly
  equivalent targets every tick
- `PNC_LocomotionProfiles` resolves transport mode, animation cadence, walk
  family, and crawl/sneak selectors once per lane so native and fallback
  movement share the same presentation
- combat approach and repositioning use native routes; a committed attack
  invalidates that route before the attack action graph takes ownership
- the server emits incremental `visualState.motionHint` segments for traversal
  so remote clients follow the same eased authoritative hop without stretching
  every small network delta over the entire animation duration
- SP native routes are advanced from the authoritative `OnZombieUpdate` frame.
- In multiplayer the server publishes path goals but never calls the native
  behavior update. Mirroring Bandits, the nearest client owns
  `PathFindBehavior2:update()` from the replicated body's `OnZombieUpdate`
  callback; generic client ticks only bind the latest goal. Normal zombie
  networking transports movement and native door/window/fence/stair states.
- `PNC_LiveBodyControl` is the single writer for managed-body usefulness.
  Native path and scripted-action leases temporarily keep the engine body
  useful; fake locomotion and idle suppression restore the humanized useless
  state. Health, animation, and behavior code do not write the flag directly.
- MP sub-tile corrections also use the delegated native controller; fake
  setX/setY steps are not an alternate multiplayer transport.
- door/window handling is goal-directed rather than opportunistic: the lane
  probes only the adjacent cardinal passage edges that advance the active goal,
  then falls back to blocked-step, collision, and no-progress recovery
- traversal candidates must be ahead of the goal-facing lane, improve distance toward the live goal, and avoid immediate re-cross of the same obstacle from the same side
- active move lanes keep short traversal memory so repeated same-side window climbs are rejected and logged instead of re-executed every tick
- exact vehicle-intersecting squares remain occupancy failures for fake
  locomotion, preventing a Lua-authored SP step directly into the chassis
- vehicle proximity is not treated as a clearance obstacle. Native movement
  owns physical contact, and a vehicle contact does not relocate the body or
  quarantine its active goal
- authoritative NPC position writes synchronize the engine previous-position
  fields. This prevents Java collision handling from reinterpreting controlled
  motion as a player-style traversal on an embodied `IsoZombie` without
  `BodyDamage`
- materialization validates saved coordinates against the same occupancy
  service and relocates a blocked legacy NPC to the nearest safe square. This
  repairs existing saves in place; it does not require NPC or world regeneration
- live bodies receive a throttled position-safety audit. If a moving vehicle or
  changed world geometry traps a body, the server relocates it, resets local
  path-recovery state, and forces a multiplayer position snapshot
- successful repairs store `runtime.positionRecovery` diagnostics and emit an
  `NPC position recovery` warning containing NPC id/name, recovery event,
  obstacle reason, source, destination, and recovery count. These rare
  operational warnings are emitted even when per-record debug logging is off
- long-lived non-locomotion action states during fallback fake locomotion are
  force-recovered before the next travel tick
- a committed attack lease cancels native routing and stops the path pump
  before locomotion can overwrite the attack action graph
- path debug logs report recovery, repath, timeout, and blocked states with the active goal only for NPCs explicitly marked `Record Debug`; global debug presentation does not opt the whole roster into movement logging

## Engine pathing research

The vanilla zombie, animal, and off-screen pathing investigation is kept
separately to avoid mixing research conclusions with the operational design:

[Vanilla and animal pathing research](../Research/VanillaAndAnimalPathing.md)

The research document also records the door/window traversal boundary and
the recommended abstract-route handoff.
## Composition and performance boundary

`PNC_PathService.lua` is the canonical movement-lane entry and loads its seven
internal modules in explicit dependency order. Supporting pathing primitives
load earlier in the shared composition because BodyLifecycle, Health,
animation, combat, and travel are intentionally interleaved consumers; they
must not be regrouped based on alphabetical filenames.

The command boundary adds no tick, scan, allocation loop, scheduler wake, path
request, or network message. Reset remains an event-driven transition used by
order changes, abstraction, incapacitation, facility arrival, and combat hold.
Only `PNC_PathService` clears `runtime.pathing` and `runtime.moveIntent` during
normal production composition; the OrderSystem direct clear remains solely as
a compatibility fallback when the service is unavailable.

## Next Expansion
- smarter repath and stuck recovery lanes
- native-route admission tuning for larger live crowds
