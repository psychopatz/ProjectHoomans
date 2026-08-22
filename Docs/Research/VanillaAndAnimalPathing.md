# Vanilla and animal pathing research

Status: B42.20 baseline, investigated 2026-08-22.

This document intentionally keeps engine research separate from the
operational Hoomans pathing design. The Java findings come from the
deobfuscated `pz-java-baseline` indexed by Codebase Memory.

## Executive conclusion

Project Zomboid has several movement layers, not one universal pathfinding
API:

1. Native population simulation moves genuinely virtual zombies.
2. Materialized characters use `PathFindBehavior2` and the engine pathfinder.
3. Passage traversal is a separate interaction/state layer for doors,
   windows, fences, and similar obstacles.
4. Virtual animals follow authored animal-zone polylines and junctions; they
   are not arbitrary obstacle-aware navigation.

The reusable Hoomans pattern is therefore an abstract route plus an
occasional live engine-path probe, followed by an explicit passage-traversal
handoff. The virtual zombie or virtual animal managers are not safe generic
route providers for arbitrary NPC records.

## Truly virtual zombies

`zombie.popman.ZombiePopulationManager.updateMain()` runs when the process is
not a multiplayer client. It calls the native population update
`n_updateMain(GameTime.multiplier, worldAgeHours)`, then consumes native data
containing zombie position, state, and optional `pathTargetX/pathTargetY`.
The native side is the part that advances zombies while they do not exist as
rendered `IsoZombie` objects.

The population manager publishes loaded areas with `n_loadedAreas()`. It sends
both ordinary loaded areas and, on a dedicated server, `loadedServerCells`.
Areas outside that simulation boundary remain native population data rather
than Java actors.

When a real zombie is virtualized, `virtualizeZombie()` stores its position,
direction, state, and current path target through `n_addZombie()`, then removes
the real body from the world. When native population data returns to a loaded
area, `addZombieMoving()` creates a real `IsoZombie`, restores its position,
and calls `realZombie.pathToLocation(pathTargetX, pathTargetY, 0)` for the
remaining route. The Java pathfinder then handles the local obstacle-aware
portion of the journey.

The Lua global `setAggroTarget(playerNum, x, y)` is only a bridge to the native
population manager's player aggro target. It is keyed by player slots, does not
return a custom route, and should not be used for Hoomans records.

## Materialized zombie pathing

`IsoZombie.initializeStates()` registers `pathfind` and
`walktoward-network`. `PathFindState.execute()` owns the normal
`PathFindBehavior2:update()` loop. `PathFindBehavior2.update()` submits a
request to `PathfindNative` when native pathfinding is enabled, otherwise to
`PolygonalMap2`, then advances along the returned path.

`WalkTowardState` refreshes a target-character route with `pathToCharacter()`.
It uses direct movement while the route is clear and re-enters
`pathToLocation()` after collision. The network state uses the same pattern:
direct `moveToPoint()` when line-clear, otherwise `pathToLocationF()` plus
`PathFindBehavior2:update()`.

## Animal pathing comparison

### Virtual animals

A virtual animal is represented by `VirtualAnimal` and advanced by
`VirtualAnimalState`. Its `moveAlongPath()` follows an `AnimalZone` polyline,
crosses authored zone junctions, and updates the virtual position directly.
This is a persistent off-screen movement graph, but it is not a building or
dynamic-obstacle pathfinder: it does not call `PolygonalMap2` or
`PathFindBehavior2`.

The animal zones are not normally hand-drawn one path at a time. During world
generation, `ZoneGenerator.genAnimalsPath()` procedurally creates polylines
inside meta-cells from the Lua `animals_path_config` table. That configuration
provides the animal type, count, chance, point count, radius, and extension
parameters. The generator uses deterministic world-seeded randomness, avoids
ineligible map zones such as towns and water, adds Follow/Eat/Sleep extensions,
and saves the resulting zones in `map_animals.bin`. Designers author the
generation rules; the individual world paths are generated and persisted.

The animal-zone idea could still inspire an Hoomans long-distance navigation
graph. It would need authored or generated nodes for rooms, corridors, doors,
and other transitions before it could represent NPC travel. It would not
automatically react to changed barricades, furniture, vehicles, or open/closed
doors.

### Materialized animals

A materialized `IsoAnimal` uses the useful live path stack. Its state map
contains `walk`, `pathfind`, `followwall`, and `climbfence`.
`IsoAnimal.pathToLocation()` delegates to `PathFindBehavior2`.
`AnimalPathFindState` updates that behavior and retries failed routes.
`AnimalWalkState` starts pathfinding after a collision, while
`AnimalFollowWallState` performs local adjacent-square collision checks and
chooses offset goals around a wall.

The wall-follow behavior is a local recovery/steering policy, not a global
replacement for the engine path search. It is a reasonable abstract fallback
after a short segment stalls, provided the relevant squares are loaded.

## Animal threat detection and fleeing

Materialized animals do not avoid players and zombies through a special
steering pathfinder. They use a perception-and-flee behavior layered on top of
the normal animal path stack.

`IsoAnimal.updateLOS()` scans the current cell's moving objects on the same
floor. It reports nearby zombies to `BaseAnimalBehavior.spotted()` and reports
visible, non-invisible, non-ghost players. Other animals are not treated as
threats by this scan. This means the behavior belongs to a live/materialized
animal and depends on the relevant cell objects being available.

`BaseAnimalBehavior.spotted()` applies different rules by threat type:

- Zombies raise stress within roughly 10 tiles and trigger an immediate flee
  response within roughly 6 tiles. The animal definition's `fleeZombies` flag
  controls whether zombies are considered.
- Wild animals detect moving players probabilistically. Running greatly
  increases detection, sneaking reduces it, and distance, the player's
  Tracking/Sneak/Lightfoot/Nimble skills, and the animal's facing direction
  modify the chance.
- Non-wild animals use stress and player acceptance. A moving player, low
  acceptance, high stress, and running can cause fleeing; highly stressed
  animals can instead attack when their definition allows it.

When fleeing, `fleeFromChr()` subtracts the threat position from the animal's
position to obtain an escape direction. It requests a goal about 10 tiles away
for ordinary animals and about 30 tiles away for wild animals, sets the running
animation, starts a short repath cooldown, and calls
`IsoAnimal.pathToLocation()`. `forceFleeFromChr()` exposes the same direct
escape-vector behavior without the normal probabilistic checks. The engine
pathfinder then resolves obstacles on the way to that escape goal.

The behavior also propagates alerts to nearby herd members. `alertOtherAnimals()`
examines a roughly 10-by-10-tile area and copies either an alert target or a
spotted threat into neighboring animals' behavior state.

If the engine route fails, `AnimalPathFindState` enables `shouldFollowWall` and
retries. `AnimalFollowWallState` uses adjacent-square collision tests, chooses
a clockwise or counter-clockwise wall side, and submits offset goals around
the obstruction. This is the most reusable part for Hoomans fleeing: direct
escape target first, bounded engine path probe second, local wall-following
recovery third.

Virtual animals do not run this threat behavior. `VirtualAnimalState` only
advances an `AnimalZone` polyline and chooses authored junctions; it does not
scan players or zombies and does not call `PathFindBehavior2` or
`PolygonalMap2`. A virtual animal must therefore receive an explicit abstract
threat event or be materialized before it can perform the live flee behavior.

For Hoomans, the safe adaptation is not to create hidden animal proxies. Use a
server-authoritative threat snapshot and the animal pattern as a policy:

```text
threat event -> escape vector -> several candidate flee goals
             -> bounded live/abstract route probe
             -> choose a reachable goal -> wall-follow/repath if stalled
```

For an abstract NPC, candidate goals should be scored against all known threats
and rejected when they move the NPC toward a second threat. For a materialized
NPC, the existing engine path owner should perform the final obstacle check.

## Doors, windows, and traversal

### Non-zombie characters and animals

The shared `PathFindBehavior2` movement loop does include explicit passage
handling. After selecting the next path node, it calls
`checkDoorHoppableWindow()` for non-zombie characters. That helper can:

- toggle an openable `IsoDoor` or door-like `IsoThumpable`;
- climb through an `IsoWindow` or window thumpable;
- climb through a window frame;
- climb over hoppable fences and walls when the character supports it; and
- return control to the state machine while the traversal animation runs.

So for a live animal or ordinary live character, the engine path behavior can
route to a passage and initiate the appropriate door/window/fence action.

### Vanilla zombies

Vanilla zombies use a different boundary. In `PathFindBehavior2.update()`, the
`checkDoorHoppableWindow()` call is guarded by `zombie == null`, so an
`IsoZombie` does not use that generic helper directly.

Instead, `IsoZombie.updateInternal()` calls `tryThump()` while the zombie is
moving. `tryThump()` detects windows, window frames, hoppable fences, and
thumpable doors/objects. It either starts the climb or assigns a thump target.
`ThumpState` then applies damage through the object's `Thump()` method. Once a
door is open or destroyed, the zombie can lunge through it and resume pursuit;
once a window is climbable, the zombie enters the window traversal state.

Therefore vanilla zombie pathing does traverse doors and windows, but not as a
single pure pathfinding operation. The flow is:

```text
engine route -> collision/passage detected -> zombie thump or climb state
             -> passage opens/destroys/traversal completes -> route resumes
```

This separation is important for Hoomans. A copied abstract route must not
pretend that a door or window is just another waypoint. It needs a passage
lease/state that owns the interaction, animation, authority, timeout, and
post-traversal position repair.

## Hoomans integration implications

Hoomans abstraction removes the live body, records its position, and changes
the travel controller to `abstract`. `PNC_Travel_Service.RefreshAbstractPositions()`
advances `PNC_Travel_Projection.Projection.AdvanceMutable()` along stored route
segments using elapsed world time. That projection updates coordinates and ETA
but does not query the game collision/pathfinding engine.

`PNC_PathService.AdvanceAbstract()` is similarly a straight distance/speed
step. It is useful for coarse movement but is not an obstacle solver.

The safest architecture is:

- retain the abstract route, persistence, ETA, and server authority;
- use the existing Hoomans `engine_path` provider for materialized bodies;
- when an abstract NPC needs dynamic obstacle reasoning, run a bounded live
  path probe or delegate to the existing engine-path owner;
- copy the next route snapshot/waypoints into the abstract projection; and
- hand doors, windows, fences, and stairs to a dedicated traversal state
  before resuming route projection.

Do not create hidden `IsoAnimal` objects as pathfinding proxies. They carry
animal-specific data, local-owner rules, synchronization, and lifecycle state
without granting virtual animals dynamic obstacle awareness.

## Implemented Hoomans retreat adaptation

The current combat implementation uses the existing bounded retreat lifecycle
as the live NPC flee response. A retreat is armed only when both conditions are
true:

- the threat report contains at least four zombies inside the horde radius; and
- a recent zombie attack marker exists, whether the attack caused damage or was
  avoided as a near miss.

The attack marker lasts for the configured damage-pressure window, allowing a
horde that forms immediately after the attack to still trigger the response.
Once a retreat goal is reached, a low-stamina NPC holds on the safe side and
does not re-engage until both the absolute and ratio stamina thresholds are
met. A healthy NPC resumes combat after the bounded retreat completes.

Retreat goals continue to use `TraversalQuery` candidate checks, so doors,
windows, and other passage interactions remain delegated to the existing
engine-path/traversal stack. For follow orders, the final goal is clamped to the
owner leash; non-follow orders keep the normal retreat distance and are allowed
to create more separation.

This is a policy adaptation of the animal flee pattern, not animal pathing
reuse: escape-vector selection, bounded candidate probing, and local recovery
are reusable, while animal zones remain unsuitable for dynamic NPC obstacle
avoidance.

At the Java level, `PathFindBehavior2.pathNextX/pathNextY` are public and can
serve as a next-waypoint snapshot. The complete path list is private inside
`PathFindBehavior2`; exporting every node would require a small Java bridge or
repeated short-goal probes.

## Ground-truth source locations

- Java: `zombie/popman/ZombiePopulationManager.java`
- Java: `zombie/characters/IsoZombie.java`
- Java: `zombie/characters/NetworkZombieAI.java`
- Java: `zombie/ai/states/PathFindState.java`
- Java: `zombie/ai/states/WalkTowardState.java`
- Java: `zombie/ai/states/WalkTowardNetworkState.java`
- Java: `zombie/ai/states/ThumpState.java`
- Java: `zombie/characters/animals/IsoAnimal.java`
- Java: `zombie/characters/animals/AnimalDefinitions.java`
- Java: `zombie/characters/animals/behavior/BaseAnimalBehavior.java`
- Java: `zombie/ai/states/animals/AnimalPathFindState.java`
- Java: `zombie/ai/states/animals/AnimalWalkState.java`
- Java: `zombie/ai/states/animals/AnimalFollowWallState.java`
- Java: `zombie/characters/animals/VirtualAnimal.java`
- Java: `zombie/characters/animals/VirtualAnimalState.java`
- Java: `zombie/characters/animals/VirtualAnimalState.java`
- Java: `zombie/characters/animals/AnimalZone.java`
- Java: `zombie/ai/states/animals/AnimalPathFindState.java`
- Java: `zombie/ai/states/animals/AnimalFollowWallState.java`
- Java: `zombie/pathfind/PathFindBehavior2.java`
- Hoomans: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua`
- Hoomans: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua`
- Hoomans: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua`
- Hoomans: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Travel/PNC_Travel_Service.lua`
- Hoomans: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Travel/PNC_Travel_Projection.lua`
