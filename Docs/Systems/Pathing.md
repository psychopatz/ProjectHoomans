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
  cannot cancel the bump or restart fake locomotion midway across a passage
- doors and windows are considered opened only after their engine state reports
  open, then their object/path state is synchronized by the authoritative side
- all path ownership lives in `PNC_PathService`
- abstract travel is elapsed-time based (`speed × elapsed`) so reducing a far
  NPC's AI cadence does not change its simulated travel speed
- behavior writes `move intent`; only `PNC_PathService.Pump` may start, refresh, cancel, or complete live movement
- repeated move/hold requests reuse their runtime intent table, reducing
  short-lived Kahlua allocations during follow and combat
- continuously moving follow/steering goals use a 0.22-tile retarget
  threshold, avoiding lane-state resets for sub-step owner jitter
- bounded local route searches are spread across scheduler windows rather than
  allowing a newly obstructed group to run every A* search in one frame
- follower slot membership and owner heading are shared per owner for 250 ms;
  each follower still updates the cached slot against the owner's live position
- the live move lane uses explicit phases: `idle`, `requested`, `active`, `arrived`, `blocked`, `cancel_pending`
- `walktoward` is a normal locomotion state, not a path-conflict state; recovery is reserved for real combat/thump conflicts so valid movement is not reset every tick
- live path refresh now routes through a single move lane, which matches the Bandits-style "one active move action" flow more closely and avoids stacked `path2` state churn
- close-range combat approach now softens from `run` to `walk` so embodied chase looks less robotic near contact range
- combat target reassessment uses a short interval and distance hysteresis so
  NPCs can respond to a nearby attacker without stop-stepping between nearly
  equivalent targets every tick
- `PNC_LocomotionProfiles` now resolves transport speed, anim cadence, walk family, and crawl/sneak selectors once per lane so fake movement and animation stay in lockstep
- combat only borrows facing through short path-service leases; normal movement keeps body facing aligned to travel direction
- the server emits incremental `visualState.motionHint` segments for traversal
  so remote clients follow the same eased authoritative hop without stretching
  every small network delta over the entire animation duration
- door opens, window opens, and window climbs stay server-owned and publish short traversal leases so client smoothing does not fight passage interactions
- door/window handling is goal-directed rather than opportunistic: the lane
  probes only the adjacent cardinal passage edges that advance the active goal,
  then falls back to blocked-step, collision, and no-progress recovery
- traversal candidates must be ahead of the goal-facing lane, improve distance toward the live goal, and avoid immediate re-cross of the same obstacle from the same side
- active move lanes keep short traversal memory so repeated same-side window climbs are rejected and logged instead of re-executed every tick
- vehicle-intersecting squares are hard occupancy failures for fake
  locomotion, steering NPCs around vehicle collision geometry instead of
  allowing a Lua-authored step into the chassis
- `PNC_VehicleAvoidance` supplements the square flag with a shared 250 ms
  footprint cache built from loaded `BaseVehicle` polygons. This covers the
  multiplayer window where a vehicle is synchronized before the grid-square
  intersection cache catches up, without scanning every vehicle per NPC step
- planned travel treats the one-tile ring around a chassis as clearance:
  routes cannot enter that ring from outside, while an NPC already inside it
  may move outward. Exact chassis tiles remain hard-blocked in both directions
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
- long-lived non-locomotion action states during active fake locomotion are force-recovered back to idle before the next travel tick so walking stance does not freeze in `turnalerted`
- a committed attack lease stops the path pump before requested or active fake
  locomotion can overwrite the attack action graph
- path debug logs report recovery, repath, timeout, and blocked states with the active goal only for NPCs explicitly marked `Record Debug`; global debug presentation does not opt the whole roster into movement logging

## Next Expansion
- smarter repath and stuck recovery lanes
- path cache reuse for larger live crowds
