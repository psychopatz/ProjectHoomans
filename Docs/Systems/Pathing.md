# Pathing

## V1
- live NPCs use server-owned path requests and embodied path behaviors
- abstract NPCs use coarse world travel
- live NPCs can open doors and use windows when the path stalls near an obstacle
- fence hopping uses the same server-owned traversal lease, repeat suppression,
  landing validation, and client motion hints as window traversal
- all path ownership lives in `PNC_PathService`
- behavior writes `move intent`; only `PNC_PathService.Pump` may start, refresh, cancel, or complete live movement
- the live move lane uses explicit phases: `idle`, `requested`, `active`, `arrived`, `blocked`, `cancel_pending`
- `walktoward` is a normal locomotion state, not a path-conflict state; recovery is reserved for real combat/thump conflicts so valid movement is not reset every tick
- live path refresh now routes through a single move lane, which matches the Bandits-style "one active move action" flow more closely and avoids stacked `path2` state churn
- close-range combat approach now softens from `run` to `walk` so embodied chase looks less robotic near contact range
- combat target stickiness now reduces target thrash so embodied NPCs do not keep stop-stepping between nearby zombies every tick
- `PNC_LocomotionProfiles` now resolves transport speed, anim cadence, walk family, and crawl/sneak selectors once per lane so fake movement and animation stay in lockstep
- combat only borrows facing through short path-service leases; normal movement keeps body facing aligned to travel direction
- the server now emits optional `visualState.motionHint` segments so clients interpolate within a server-authored move/traversal window instead of inferring transport locally
- door opens, window opens, and window climbs stay server-owned and publish short traversal leases so client smoothing does not fight passage interactions
- door/window handling is obstacle-driven, not opportunistic: the lane only evaluates traversal after a blocked fake step or a short no-progress stall
- traversal candidates must be ahead of the goal-facing lane, improve distance toward the live goal, and avoid immediate re-cross of the same obstacle from the same side
- active move lanes keep short traversal memory so repeated same-side window climbs are rejected and logged instead of re-executed every tick
- long-lived non-locomotion action states during active fake locomotion are force-recovered back to idle before the next travel tick so walking stance does not freeze in `turnalerted`
- path debug logs now report recovery, repath, timeout, and blocked states with the active goal so stuck movement is diagnosable without flooding normal runtime

## Next Expansion
- smarter repath and stuck recovery lanes
- path cache reuse for larger live crowds
