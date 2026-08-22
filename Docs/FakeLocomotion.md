# PNC Fake Locomotion

## Purpose

`PNC_FakeLocomotion.lua` is the single-player and exceptional fallback mover.
Multiplayer embodied movement is owned by the engine's native zombie controller;
fake position steps are never used as MP transport.

## Ownership

- `PNC_Behavior_*`: publish move intent only.
- `PNC_PathService`: owns the shared move lane, resolved movement mode,
  movement logs, and special movement orchestration.
- `PNC_FakeLocomotion`: owns fake walking/running/crawling step execution.
- `PNC_TraversalQuery`: owns shared occupancy and passage-edge queries.
- `PNC_NavigationRouter`: selects a provider for each movement policy.
- `PNC_EnginePathPlanner`: owns bounded native local/travel movement handoffs.
- `PNC_TraversalProfiles`: owns traversal animation names and timing profiles.
- `PNC_LiveBodyControl`: owns zombie-body suppression and live-body cleanup.
- `PNC_Animation`: owns animation variables, walk types, speed multipliers, and
  bump playback.
- `PNC_Network` and `PNC_ClientPresenceSync`: replicate movement state and
  preserve short special-move bump windows for nearby clients.

## Rules

- Single-player fallback bodies stay `setUseless(true)` outside a synchronous
  native update. Multiplayer live bodies always stay `setUseless(false)`.
- Vanilla `PathFindBehavior2` owns meaningful router-approved local/travel
  and combat movement. `PNC_PathService` pumps and releases that lease;
  committed attacks, sub-tile corrections, and native failures return to fake
  locomotion.
- Keep special movement inside the same shared lane so follow, combat, patrol,
  guard, and retreat all use one locomotion path.
- Prefer time-scaled small steps over large snaps for multiplayer stability.

## Navigation Router

The router selects both steering and the movement implementation:

- `local`, `travel`, and `combat` use the `engine_path` provider.
- Meaningful movement uses native routing on both open ground and indoors.
  Sub-tile corrections remain direct and allocation-light.
- Native path requests are asynchronous, globally budgeted, and staggered.
  PathService pumps the active engine behavior directly and cancels/resets it
  on success, failure, timeout, policy switch, or invalidation.
- Unknown policy names fall back to `local`; missing providers fall back to the
  final target without interrupting movement.

New algorithms can be added without changing behaviors or PathService:

```lua
PNC.NavigationRouter.RegisterProvider("kite_arc", {
    GetSteeringTarget = function(record, body, finalTarget, policy)
        return finalTarget
    end,
    Clear = function(record)
        -- Optional: discard provider-specific cached state.
    end,
})

PNC.NavigationRouter.RegisterPolicy("kite", {
    provider = "kite_arc",
})
```

Pass `{ navigationPolicy = "kite" }` as the final `Common.MoveRecord` or
`MoveIntent.RequestMove` argument. Providers cache expensive state on the
record; any movement handoff remains mediated by PathService.

The engine controller supplies its own doorway/window-aware movement for the
bounded lease. The collision-driven fake lane resumes when that lease ends.

The path overlay reports the selected `policy/provider`, native controller
state, traversal state, goal/final distances, and non-progress diagnostics.

Fake locomotion only refreshes its progress lease when it beats the best
distance reached for the current lane goal. Zero-length axis candidates are
discarded, and bounded lateral movement that fails to improve that best
distance invalidates the cached route. This prevents walk-in-place and
away/back oscillations from hiding a blocked NPC indefinitely.

## Native Engine Routing

- PNC never indexes `zombie.pathfind.Path` from Lua; Build 42 does not expose
  that Java object as a Kahlua table.
- The engine behavior is pumped directly, matching the robust movement pattern
  used by Bandits, and is never wrapped in `pcall`.
- Only one request may start per global budget window, so a following group
  cannot launch all path searches in one scheduler pass.
- Moving targets replan only after drifting 1.5 tiles and after a one-second
  cooldown, preventing follow targets from restarting A* every behavior tick.
- Combat approach, retreat, and kiting use bounded native routes. Beginning a
  committed attack immediately invalidates the native lease before its bump
  animation is applied.
- Facing and animation return to normal fake-locomotion ownership as soon as
  the native lease succeeds, fails, times out, or is invalidated.
- Every accepted native displacement publishes motion hints for diagnostics
  and visual-state context; embodied MP position transport remains owned by
  Project Zomboid's zombie network controller.

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
- Short-fence split hops use the low-fence profile timing and wait one update
  between the raise clip and landing clip so the bumped-to-Idle transition can
  settle. Tall fences keep their separate single-clip profile and completion
  event. The profile is authoritative because `AnimationPlayer` is engine
  userdata that is not safely reflectable from Kahlua.
- Fake traversal uses only `PNC_ClimbFence`, `PNC_ClimbFenceTall`, and
  `PNC_ClimbWindow`. It never writes the vanilla `ClimbFenceStarted` or
  `ClimbWindowStarted` variables that enter unsafe Java traversal states.
- Those names and their travel/hold timings are registered through
  `PNC.TraversalProfiles`. A new animation variant can be installed with
  `TraversalProfiles.Register(kind, variant, profile)` and selected by context
  with `TraversalProfiles.RegisterSelector(kind, selector)` without editing the
  traversal runtime.
- PNC-authored transforms synchronize the body’s previous-position fields.
  This keeps Java collision handling from reinterpreting controlled movement
  as a traversal collision on an `IsoZombie` without player `BodyDamage`.
- Special movement is only considered after a blocked fake step or a short
  no-progress stall, so nearby windows no longer steal normal movement ticks.
- Collision checks include the edge between squares, not only destination
  occupancy. Walls are hard barriers; a door, window, or fence directly ahead
  is handed to traversal before lateral steering is attempted.
- Vehicle-intersecting squares are treated as occupied, so the existing
  side-preference steering walks around the vehicle footprint.
- Build 42 returns vehicle polygons as Java `VehiclePoly` userdata rather than
  Lua tables. Vehicle avoidance derives a conservative scan bound from the
  vehicle position and script extents, then uses the engine's
  `isIntersectingSquare` method for exact occupancy without indexing Java
  polygon fields.
- Traversal attempts remember the obstacle, source side, destination, and goal
  revision long enough to reject immediate same-side re-cross loops.

## Multiplayer Notes

- The server owns NPC decisions and publishes native path goals.
- Mirroring Bandits, the nearest client advances `PathFindBehavior2` inside
  that body's `OnZombieUpdate`; other clients observe normal IsoZombie
  replication.
- Every MP live body remains useful for its full lifetime. Health, animation,
  materialization, and safety maintenance all route through one flag writer.
- Native movement owns doors, windows, fences, stairs, facing, and position.
  Fake steps and scripted traversal transforms do not run as MP transport.
- Roster snapshots never write client NPC X/Y. The legacy interpolation module
  was removed, so there is no second position owner.
- Every shared animation XML filename and root node name is `PNC_` namespaced
  and guarded by `PNCActor=true`, preventing Bandits or ordinary zombies from
  selecting PNC nodes when both mods are enabled.
