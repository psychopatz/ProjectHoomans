# PNC Fake Locomotion

## Purpose

`PNC_FakeLocomotion.lua` is the movement authority for embodied PNC live bodies.
It advances NPCs by small server-authoritative position steps while keeping the
underlying zombie AI disabled with `setUseless(true)`.

## Ownership

- `PNC_Behavior_*`: publish move intent only.
- `PNC_PathService`: owns the shared move lane, resolved movement mode,
  movement logs, and special movement orchestration.
- `PNC_FakeLocomotion`: owns fake walking/running/crawling step execution.
- `PNC_TraversalQuery`: owns shared occupancy and passage-edge queries.
- `PNC_LiveBodyControl`: owns zombie-body suppression and live-body cleanup.
- `PNC_Animation`: owns animation variables, walk types, speed multipliers, and
  bump playback.
- `PNC_Network` and `PNC_ClientPresenceSync`: replicate movement state and
  preserve short special-move bump windows for nearby clients.

## Rules

- Live bodies stay `setUseless(true)` by default.
- Do not reintroduce vanilla `pathToLocation`, `walktoward`, or `path2` as the
  primary locomotion authority.
- If pathfinding is reintroduced later, it may only provide waypoints. It must
  not own the body transform.
- Keep special movement inside the same shared lane so follow, combat, patrol,
  guard, and retreat all use one locomotion path.
- Prefer time-scaled small steps over large snaps for multiplayer stability.

## Resolved Locomotion Mode

- `crawl` stays `crawl`.
- `sneak` stays `sneak`.
- Follow stealth also resolves to `sneak`.
- Normal locomotion switches to `run` when far from goal and falls back to
  `walk` near the goal using hysteresis to avoid animation thrash.
- Current live thresholds are approximately `4.5` tiles to enter `run` and
  `2.9` tiles to settle back to `walk`, with stop distance still respected.

## Animation Notes

- The movement lane now exposes `resolvedMode` and `animSpeed`.
- Animation speed is driven from the resolved live mode so leg motion tracks the
  real fake-locomotion step rate better.
- Walking is intentionally slower than before; far-distance closing now uses run
  instead of over-speed walk.
- The server resolves `animSpeed` and replicates it to clients so nearby
  multiplayer observers do not guess a different walk cadence.
- Every real fake-locomotion displacement refreshes a short visual lease. The
  lease survives an immediate arrival long enough for short moves to render a
  gait locally and to be included in at least one moving and one stopping
  multiplayer snapshot; it never extends server transport.
- A follow-goal refresh inside that lease preserves the current body state and
  walk cycle instead of hard-resetting to idle between micro-movements.
- `BumpType` is reserved for explicit combat, reaction, and traversal actions.
  Locomotion startup does not occupy the bump channel, because short repeated
  goals would otherwise mask the normal leg cycle.
- Bump release is a two-tick handshake: completion remains true until the
  engine ActionContext leaves `bumped`; only the next bump start clears it.
  Locomotion cannot resume while that release acknowledgement is pending.
- Live locomotion reapplies `setMoving`, sneaking state, and animation variables
  every tick. Because the engine rejects `walktoward` for a useless zombie, PNC
  locomotion nodes also exist in the stable `idle` animation tree. This keeps
  leg playback independent from vanilla zombie transport ownership.
- Incapacitated crawling is a visual PNC locomotion profile. It keeps vanilla
  crawler, on-floor, and fall-on-front flags disabled so the body remains in
  the animation tree containing `PNC_Crawl` while fake steps move it.
- Downed animation maintenance also releases stale bump, stagger, and hit
  reaction ownership. This is repeated safely on server and clients because a
  damage callback can finish changing action state after custom HP reaches the
  incapacitated state.
- Stagger recovery clears the Java `bStaggerBack` latch and expires the action
  timer directly. A legacy `changeState(ZombieIdleState)` call does not change
  animation ActionContext and actually installs a fresh delay, which previously
  made a repeatedly attacked crawler glide until the delay could finally expire.

## Combat Override Notes

- Active attack actions temporarily override locomotion sync.
- Cancelling a move during an active attack no longer hard-resets the body back
  to idle, which prevents swings and shove bumps from freezing mid-action.

## Current Special Movements

- Doors: opened in-place and logged.
- Windows: opened in-place and logged.
- Window climb: fake bump plus controlled reposition to the opposite square,
  with origin and destination logging.
- Fences: shared edge detection, validated landing, controlled reposition, and
  a replicated climb lease.
- `PNC_PathService_TraversalRuntime` owns the timed transform and bump lifetime
  for fence/window climbs. Normal fake locomotion and combat facing remain
  suspended until that runtime releases the body.
- Traversal does not interpolate the authoritative transform during takeoff.
  The hop animation plays against a pinned origin, and the server commits the
  landing position only when `PNCTraversalFinished` becomes true at the
  animation's actual `End` event.
- Fake traversal uses only `PNC_ClimbFence`, `PNC_ClimbFenceTall`, and
  `PNC_ClimbWindow`. It never writes the vanilla `ClimbFenceStarted` or
  `ClimbWindowStarted` variables that enter unsafe Java traversal states.
- Special movement is only considered after a blocked fake step or a short
  no-progress stall, so nearby windows no longer steal normal movement ticks.
- Collision checks include the edge between squares, not only destination
  occupancy. Walls are hard barriers; a door, window, or fence directly ahead
  is handed to traversal before lateral steering is attempted.
- Traversal attempts remember the obstacle, source side, destination, and goal
  revision long enough to reject immediate same-side re-cross loops.

## Multiplayer Notes

- The server is authoritative for live-body movement.
- Clients consume replicated snapshots and live zombie replication only; they do
  not run NPC movement logic.
- Passage objects and traversal transforms are changed on the server. Clients
  receive door/window object synchronization and interpolate authoritative NPC
  positions; they never open a local-only passage or choose a landing square.
- Snapshot visual state carries short special-move bump windows so client visual
  sync does not overwrite climb bumps immediately.
- Snapshot visual state also carries the resolved locomotion animation speed so
  server fake-step transport and client leg cadence stay aligned.
- Client interpolation now starts new segments from the currently rendered body
  position for the same motion stream, which prevents backward rewinds between
  authoritative snapshots while keeping server-authored targets and durations.
- Normal MP move segments last at least 200 ms so a client remains in motion
  across the server's 150 ms active-snapshot cadence rather than running in
  place between short 35–50 ms interpolation segments.
- Every shared animation XML filename and root node name is `PNC_` namespaced
  and guarded by `PNCActor=true`, preventing Bandits or ordinary zombies from
  selecting PNC nodes when both mods are enabled.
