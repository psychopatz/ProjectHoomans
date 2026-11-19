# Runtime Performance

## Goals

- one hundred registered NPCs must remain inexpensive when most are abstract
- live combat keeps responsive decision, pathing, bite, and attack-action lanes
- population spikes are deferred through explicit budgets instead of producing
  an unbounded server tick
- all optimizations preserve server authority and use runtime-only state

## World Census

`PNC_WorldCensus` is the single canonical owner of full
`getCell():getZombieList()` traversals and exposes shared buckets
(`AllZombies`, `OrdinaryZombies`, `ManagedBodies`, `BanditBodies`,
`LifecycleCandidates`, and `ByOnlineID`). It uses 3-tier activity-sensitive
cadence:

- combat / active bites / `MarkUrgent` wake: 100 ms (`WORLD_CENSUS_REFRESH_MS`);
- calm live NPC bodies present: 250 ms (`WORLD_CENSUS_CALM_REFRESH_MS`);
- zero live NPC bodies: 1,000 ms (`WORLD_CENSUS_IDLE_REFRESH_MS`).

`MarkUrgent(now, durationMs, invalidateThrottle)` wakes census immediately on
zombie provocation and live materialization. `PNC_SpatialIndex`,
`PNC_BodyLifecycle_Audit`, `PNC_BodyLifecycle_Startup` maintenance,
`PNC_Bandits_Targeting.EnumerateTargets`, and
`PNC_LiveBodyControl.ScanLoadedManagedBodies` all consume this shared census
instead of running redundant engine scans.

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
leaving those conditions. `RefreshActiveSet` fast-exits when zero live bodies
exist and deduplicates `ActorOwnership.IsForeignOwned` + activation checks
once per unique zombie across nearby NPCs. `PumpActiveSet` applies per-entry
cadence (`150 ms` mid-range pursuit / `250 ms` idle) while waking at zero
latency for close-range bites (`<= ZOMBIE_BITE_DISTANCE + 1.5`), active bite
states, hit-settling, native player targets/attackers, and
`OnZombieProvoked`. Pursuit diagnostic string formatting is gated behind
`isPursuitAuditEnabled()`.

Defaults:

- active-set discovery: 250 ms
- mid-range pursuit / idle per-entry cadence: 150 ms / 250 ms
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

Player proximity is a separate wake lane. Every 250 ms it queries Core's
lazy 32-tile spatial index (`QueryPromotionCandidates`, capped at
`CORE_PROMOTE_MAX_PER_REFRESH = 4` per refresh while leaving far/abstract
Core actors Core-only) and Hoomans `SpatialIndex.QueryNPCs`, prioritizes
candidates (`forceLive` > active follower > bystander), respects active
`materializeRetryAt` / `materializeWakeAt` backoff so retries never thrash,
and schedules them through the normal 24-record server-tick budget. Body
creation has a separate two-NPC per-tick budget, while `PumpDemotions`
(`2,000 ms` grace, `1,000 ms` cadence, `8` per pass) reversibly releases
demoted Core-backed Hoomans records without deleting Core actors.

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
- meaningful movement uses the native engine controller, including combat
  approach; request starts remain capped at one per 100 ms, moving targets must
  drift 1.5 tiles before a one-second replan, and sub-tile corrections avoid
  path search; excess NPCs are deferred to later scheduler passes
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

Collection is normally `OFF` (`0` wrappers installed, `0` wrapper calls).
`COARSE` sampling wraps bounded top-level boundaries (`<= 15`, no per-NPC
hot-function deep wrappers). Deep profiling requires explicit opt-in with
clamped time-bounding (`5,000..300,000 ms`, never persisted as `"deep"` in
`PsychopatzCore_Profiler.txt`), deterministically restores every wrapped
function/event on expiry or `Disable()`, and labels timings separately
(`no_performance_timers` / `coarse_sampled` / `deep_instrumented_diagnostic_only`).

## Regression Gates

- `pnc_lightweight_runtime_simulation_smoke.lua`
- `pnc_lightweight_runtime_cadence_smoke.lua`
- `pnc_lightweight_persistence_authority_smoke.lua`
- `pnc_lightweight_domain_delta_replication_smoke.lua`
- `tests/benchmarks/lightweight_npc_runtime.lua`
- `pnc_world_census_smoke.lua`
- `pnc_zombie_aggro_budget_smoke.lua`
- `pnc_perception_frame_smoke.lua`
- `pnc_companion_owner_defense_smoke.lua`
- `pnc_follow_formation_cache_smoke.lua`
- `pnc_client_animation_authority_smoke.lua`
- `pnc_engine_path_planner_smoke.lua`
- `pnc_combat_commitment_smoke.lua`
- `pnc_simulation_lod_smoke.lua`
- `pnc_scheduler_smoke.lua`
- `pnc_spatial_throttle_smoke.lua`
