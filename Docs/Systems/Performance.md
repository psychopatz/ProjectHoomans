# Runtime Performance

## Goals

- one hundred registered NPCs must remain inexpensive when most are abstract
- live combat keeps responsive decision, pathing, bite, and attack-action lanes
- population spikes are deferred through explicit budgets instead of producing
  an unbounded server tick
- all optimizations preserve server authority and use runtime-only state

## World Census

`PNC_WorldCensus` is the only recurring owner of a full
`getCell():getZombieList()` traversal. It refreshes at most every 100 ms while
live NPC bodies exist and relaxes to 500 ms when the entire roster is abstract.
It reuses its arrays. The spatial index and body audit consume that same
census. Forced administrative audits may explicitly request a fresh census.

Ordinary zombies receive their stable PNC spatial ID during census collection.
A stale target lookup respects the normal census throttle and never forces a
new full scan for each NPC.

The spatial layer retains the last valid zombie grid when another consumer has
already refreshed the census but its generation has not changed. Player-cell
refreshes never clear zombie cells unless a replacement census generation is
actually indexed.

## Zombie Aggro Budget

`PNC_ZombieAggro_ActiveSet` admits zombies that are near a live NPC, were
provoked, have an NPC aggro lease, or own a bite lease. Entries expire after
leaving those conditions.

Defaults:

- active-set discovery: 250 ms
- active entry lease: 1,500 ms
- PNC zombie updates: 64 per server tick
- zombie pursuit path requests: 16 per server tick

Bite recovery remains an urgent small set and is maintained independently.
Nearest NPC discovery uses `PNC_SpatialIndex.QueryNPCs`.

## Perception Frames

Each NPC holds a runtime-only 200 ms zombie perception frame. One spatial query
provides:

- sorted zombie distances
- target candidates
- surrounded, pressure, and horde counts
- local repositioning counts

LOS is limited to a rotating window of six candidates plus a remembered zombie
attacker. A window with no visible result advances on the next frame. Frames
invalidate on expiry, meaningful observer movement, floor changes, or new
attacker memory.

An owner-targeting zombie is an urgent companion-defense exception. It is
selected from the owner's nearby spatial cells before the normal LOS window;
this does not perform a global zombie-list scan. Companions belonging to the
same player share that result for 100 ms.

## Simulation LOD

The scheduler uses these default tiers:

| Tier | Record cadence |
|---|---:|
| committed combat action | 50 ms |
| combat target | 75 ms |
| live moving/incapacitated | 100 ms |
| live idle | 1,000 ms |
| abstract near/active | 3,000 ms |
| abstract far and travelling | 15,000 ms |
| abstract stationary guard/dormant | 60,000 ms |

`PNC_SimulationClock` separately gates presence, vitals, and path pumping.
Health and stamina use elapsed time and therefore do not need to execute at
combat decision frequency. Abstract movement also uses elapsed time.

Player proximity is a separate wake lane. Every 250 ms it spatially finds
abstract NPCs inside materialization range and schedules them through the
normal 24-record server-tick budget. Body creation has a separate two-NPC
per-tick budget, with overflow retaining a 50 ms presence wake. A 60-second
dormant cadence therefore cannot delay range entry or create a mass-spawn
frame spike.

## Allocation Policy

- spatial grids use nested numeric cells instead of concatenated string keys
- world-census arrays are cleared and reused
- behavior movement intent tables are mutated and reused
- companions following one owner share a 250 ms sorted formation cache; the
  group is no longer rescanned and resorted once per follower tick
- local-authority presence snapshots are rebuilt per record by activity tier
  (50 ms attacks, 150 ms movement, 500 ms idle, 2,000 ms abstract) instead of
  rebuilding every record every 75 ms
- local-authority appearance maintenance runs at 250 ms and never replays
  server-owned locomotion; attack snapshots remain client-rendered in every
  topology, including single-player
- bounded local A* admits at most two searches per 50 ms window; excess NPCs
  keep their current waypoint and retry on a later scheduler pass
- performance collection is disabled unless runtime debug or an explicit
  capture window is active

## Diagnostics

Authorized debug-roster responses include `PNC_Performance.Snapshot()`:

- census scans and loaded counts
- spatial rebuilds
- active and processed aggro zombies
- issued/deferred pursuit paths
- perception frames, cache hits, candidates, and LOS checks
- scheduler processed/deferred counts
- census, spatial, perception, and server-tick timings

Counters and clocks are never serialized.

Collection is normally off. An authorized debug-roster request with
`performance=true` enables a 60-second capture window; Lua-console diagnostics
may also call `PNC.Performance.Enable(durationMs)`. Refresh the debug roster
after the workload to read the accumulated snapshot.

## Regression Gates

- `pnc_world_census_smoke.lua`
- `pnc_zombie_aggro_budget_smoke.lua`
- `pnc_perception_frame_smoke.lua`
- `pnc_companion_owner_defense_smoke.lua`
- `pnc_follow_formation_cache_smoke.lua`
- `pnc_client_animation_authority_smoke.lua`
- `pnc_local_path_planner_smoke.lua`
- `pnc_combat_commitment_smoke.lua`
- `pnc_simulation_lod_smoke.lua`
- `pnc_scheduler_smoke.lua`
- `pnc_spatial_throttle_smoke.lua`
