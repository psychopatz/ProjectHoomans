# Deterministic Headless Runtime Simulator

## Purpose

The Lightweight NPC Runtime job must not require repeatedly launching native Project Zomboid for ordinary implementation feedback.

Create one integrated deterministic headless simulator that exercises the **real Project Hoomans production seams** behind engine adapters and verifies the architectural scaling contract across Core actors, Hoomans promotion, scheduling, persistence, networking, materialization, zombies, and profiler modes.

Native Project Zomboid remains the final authority for engine-specific behavior and feel. The simulator is the mandatory developer feedback loop before native acceptance.

## Required artifacts

Preferred names unless current repository conventions prove a better equivalent:

- `tests/pnc_lightweight_runtime_simulation_smoke.lua` — fast correctness/regression scenario run on ordinary changes;
- `tests/support/lightweight_runtime_simulator.lua` — reusable deterministic world/time/engine boundary fixture;
- `tests/benchmarks/lightweight_npc_runtime.lua` — broader scale/performance-counter matrix.

Do not create a second fake implementation of Project Hoomans. Mock only external Project Zomboid/native boundaries and drive current production modules wherever practical.

## Deterministic model

The simulator accepts explicit fixed inputs, for example:

```lua
Simulator.New({
    worldSeed = 123456,
    actorCount = 500,
    nearbyActors = 12,
    expectedPromotedActors = 6,
    zombieCount = 80,
    playerCount = 1,
    clientCount = 1,
    simulatedMs = 60000,
    stepMs = 50,
})
```

Every run must be reproducible for the same source revision and fixture inputs. Avoid wall-clock sleeps and uncontrolled randomness.

## Production-seam principle

Prefer real modules for:

- Core actor/provider/runtime contracts;
- Project Hoomans promotion/runtime-view construction;
- scheduler and SimulationLOD;
- presence/materialization admission and budgets;
- persistence dirty marking/pump/serialization boundaries;
- network snapshot/delta builders;
- world census/spatial/aggro/perception budgeting where engine-independent;
- profiler feature installation/restore behavior.

Fake only narrow native interfaces such as player/zombie position access, loaded-object collections, body/materialization shell creation, socket sends, ModData storage/flush counters, and engine path/render callbacks.

A fake boundary must expose only the minimum API consumed by production code and must collect diagnostics rather than silently bypassing work.

## Canonical smoke scenario

The fast smoke scenario should approximate an ordinary populated save while remaining quick enough for routine agent use:

```text
100 Core SurvivorWorld actors
  80 far abstract
  14 near but still abstract/provider-neutral
   6 requiring Hoomans runtime

1 player
20-80 simulated zombies
1-3 clients as needed by the phase
20-60 seconds deterministic simulated time
```

Drive a sequence such as:

1. startup with mostly abstract actors;
2. player movement and interest change;
3. actor promotion/materialization;
4. follower movement/idle transition;
5. combat start and damage;
6. wound/treatment or equipment mutation;
7. inventory mutation;
8. knowledge/social logical mutations;
9. actors leave interest and demote;
10. persistence checkpoint/save drain;
11. reload/reconstruction;
12. reconnect or revision-gap repair where networking is active.

The exact fixture can evolve, but it must remain deterministic and cover every accepted L1-L4 contract.

## Mandatory architectural assertions

### Abstract population does not imply Hoomans population

For `N` Core actors and a much smaller relevant set `L`, assert that Hoomans rich runtime, scheduler membership, Hoomans spatial membership and Hoomans persistence work remain proportional to `L`, not `N`.

Example invariant:

```text
Core actors              = 500
actors needing Hoomans   = 6
promoted Hoomans records <= expected bounded active set
live bodies              <= materialization policy
```

A regression that bulk-hydrates all 500 actors must fail immediately.

### Promotion and demotion preserve identity

Assert that promotion/demotion/re-promotion retains the exact canonical Core actor ID, identity seed, provider ownership rules and durable state. Demotion must remove Hoomans scheduler/spatial/body/runtime membership without deleting the Core actor.

### Persistence work is dirty-domain proportional

Collect counters for:

- logical commits;
- dirty-domain marks;
- persistence pump runs;
- actor/extension serialization attempts;
- physical ModData writes;
- `GlobalModData.save()` calls;
- terminal/not-applicable outcomes;
- retryable failures and retry attempts.

Many logical social/knowledge mutations must coalesce into bounded persistence work. Unchanged abstract actors must not be repeatedly serialized. Terminal/non-applicable Core-backed state must not stay dirty forever.

### Network mutations use the narrowest valid representation

Use simulated recipients and count production builders/sends for movement, attack, reload, damage, wounds/treatment, equipment/appearance, inventory/detail and repair.

Ordinary single-domain changes must not build unrelated full snapshots. Intentionally inject a revision gap or unsupported delta and assert exactly the documented full-current repair/fallback behavior.

### Materialization is bounded

When many actors enter range at once, assert the configured promotion/materialization budget per tick/frame and verify overflow is deferred rather than synchronously materialized.

### Zombie/census work is shared and bounded

With simulated zombie populations, assert no per-NPC full loaded-zombie scan is introduced. Exercise the real shared census/spatial/aggro/perception budgets wherever possible and verify work remains bounded under increasing zombie count.

### Profiler modes are observable

Run equivalent simulator work with profiler OFF, coarse capture and explicitly deep capture where supported.

At minimum assert:

```text
OFF deep-wrapper installs/calls = 0
```

and prove capture stop/expiry restores original functions. Instrumented timing must be labelled separately from clean baseline timing.

## Simulator diagnostics

The smoke test should fail assertions but also print a concise useful summary so an agent can see regressions without reading raw logs. Include as available:

```text
CoreActors
PromotedHoomansRecords
LiveBodies
SchedulerProcessed
SchedulerDeferred
PromotionAttempts
Promotions
Demotions
MaterializationAttempts
Materializations
LogicalCommits
PersistencePumps
SerializationAttempts
PhysicalWrites
GlobalSaveCalls
RetryablePersistenceFailures
PresenceDeltas
CombatDeltas
HealthOrWoundDeltas
EquipmentDeltas
FullSnapshots
RepairSnapshots
CensusScans
PerNpcGlobalZombieScans
ProfilerDeepWrapperCalls
```

Counters must come from the real exercised seams or narrow test adapters, not invented expected values.

## Scale benchmark matrix

The slower benchmark should sweep representative combinations such as:

- Core actors: 100 / 500 / 1000 / 2000 where practical;
- promoted/relevant Hoomans actors: 1 / 6 / 12 / 24;
- zombies: 0 / 50 / 200;
- clients: 1 / 4 / 16 for network-capable scenarios.

Do not require every Cartesian combination if it adds little evidence. Select reproducible cases that test the complexity contract and record unsupported limits explicitly.

Compare at minimum:

- rich Hoomans record count vs total Core actor count;
- scheduler work;
- persistence scans/writes/flushes;
- full vs domain-delta snapshot builds;
- promotion/materialization work;
- retained caches/queues;
- deterministic operation counts;
- elapsed CPU only when the headless timing method is stable and clearly labelled.

Prefer operation/count budgets over fragile machine-specific millisecond thresholds for correctness gates.

## Native boundary

The simulator cannot prove native engine behavior such as:

- actual `IsoZombie`/body creation cost;
- Java pathfinder cost and path correctness;
- rendering FPS;
- chunk streaming;
- real socket packet size/timing;
- native model/clothing rendering;
- engine event order under real SP/MP;
- final multiplayer synchronization feel.

These remain native acceptance items. Do not mislabel the simulator as native performance proof.

## Phase integration

- **L0:** simulator must compare profiler OFF/coarse/deep installation and operation counts.
- **L1:** simulator must prove large Core population stays mostly Core-only and promotion/demotion is identity-stable.
- **L2:** simulator must prove dirty-domain persistence coalescing and no permanent retry loop.
- **L3:** simulator must prove ordinary mutations use domain deltas while repair/fallback converges.
- **L4:** simulator becomes the repeatable identical workload used before/after measured cadence/allocation changes.
- **L5:** fast smoke + scale benchmark + focused/full suites are mandatory developer acceptance evidence before user-owned native testing.
- **L6:** continuous moving-player + 1/3/6/12 live `FollowOwner` companions, NPC combat-contact workloads (NPC -> zombie/NPC/player), compact abstract/mobile-group journey handoff workloads, **and** large player/multi-NPC inventory/ModData workloads, with operation-count baselines and bounded stutter-correlation diagnostics, are mandatory before returning to native acceptance.

Every L1-L4 and L6 change must extend the simulator when it introduces or changes a runtime contract. A phase is not complete if its main optimization can only be tested by manually launching Project Zomboid.

## L6 follow-walk extension

The canonical smoke scenario's generic `player movement and interest change` is not sufficient evidence for sustained companion following.

L6 adds a dedicated moving-player workload described in [FOLLOW_WALK_STUTTER.md](FOLLOW_WALK_STUTTER.md). The simulator must update the fake player's position every simulation step during walking/running intervals and expose the player methods consumed by production follow logic, including `isPlayerMoving`, running/sprinting state, and forward direction.

The workload must exercise the real scheduler/SimulationLOD -> `TickFollowOwner` -> formation -> move-intent -> PathService chain. Only the native engine path computation/progress boundary may be deterministic/fake.

The fast smoke must include a bounded six-follower open/turn-stop case. The slower benchmark must cover 1/3/6/12 followers and the obstacle/stall cases.

Operation counters, not machine-specific milliseconds, are the primary regression gate. Profiler-OFF average/p95/max tick timing is supporting evidence. A clean healthy open-field fake provider must not create synthetic native timeout/stall/traversal events.

## L6 combat-hit extension

The simulator must also exercise successful attack impacts, not merely "combat active" ticks.

See [COMBAT_HIT_STUTTER.md](COMBAT_HIT_STUTTER.md). At minimum provide deterministic:

- `COMBAT_NPC_ZOMBIE_MISS` / `COMBAT_NPC_ZOMBIE_HIT`
- `COMBAT_NPC_NPC_MISS` / `COMBAT_NPC_NPC_HIT`
- `COMBAT_NPC_PLAYER_MISS` / `COMBAT_NPC_PLAYER_HIT`

The miss/control cases must run the same attack decision/action timing without accepted target damage. This establishes the incremental cost of the impact boundary.

The hit cases must drive production `BuildHitEvent` / `ApplyTargetDamage` and target-specific services as far as engine-independent code permits. Fake only narrow native body/reaction/stats/socket boundaries and count every invocation.

The slower benchmark must include 1/3/6/12 NPC attackers with controlled contact spacing plus one synchronized-contact stress case. Include repeated nonlethal hits and deterministic kill/incapacitation transitions.

Primary correctness gates are operation counts and bounded same-frame fan-out. Profiler-OFF average/p95/max tick time is supporting evidence. Native Project Zomboid remains the final authority for Java/engine body-hit and frame-time cost.

## L6 abstract-travel/materialization extension

See [ABSTRACT_TRAVEL_HANDOFF_STUTTER.md](ABSTRACT_TRAVEL_HANDOFF_STUTTER.md).

The simulator must exercise the canonical Core group journey across representation transitions rather than mocking "teleport every N hours."

Required scenarios:

- `ABSTRACT_ROUTE_FAR`
- `ABSTRACT_ROUTE_TIME_LEAP`
- `ABSTRACT_ROUTE_PLAYER_INTERCEPT`
- `ABSTRACT_ROUTE_PLAYER_EXIT`
- `ABSTRACT_ROUTE_ARRIVAL`
- `ABSTRACT_ROUTE_LIVE_STALL_HANDOFF`
- `ABSTRACT_ROUTE_MP_INTEREST`

Use the real Core `GroupJourney` / group traversal projection and the real ProjectHoomans bridge/presence/travel handoff seams. Only engine body spawning/path progress is a narrow deterministic fake.

The scale benchmark must cover 1/10/50/100 simultaneous travelling groups and 1/3/6/12 group members while proving that distant groups remain compact/bodyless and only the nearby subset incurs promotion/materialization/live-body work.

A large world-hour jump must be tested against equivalent small-step advancement and reach equivalent canonical journey state without replaying intermediate server frames.

## L6 required cross-system stress matrix

The three isolated workload families are necessary for attribution but are not sufficient for L6 acceptance. After their pre-fix baselines and evidence-driven fixes, run these compound scenarios through the same integrated simulator:

- `COMBINED_SAVE_RELOAD_PRESSURE`
- `COMBINED_MATERIALIZE_COMBAT`
- `TRAVEL_MEMBER_DEATH_HANDOFF`
- `TRAVEL_ARRIVAL_STORM`
- `OBSERVATION_PROJECTION_LOAD`
- `PLAYER_FAST_INTEREST_JUMP`
- `PROVIDER_HANDOFF_TRAVEL`
- `LONG_WORLD_ENDURANCE`

`COMBINED_MATERIALIZE_COMBAT` must be in the fast smoke: a travelling hostile group crosses into projected player interest, materializes through production presence/promotion seams, begins combat, lands deterministic hits, and later remains safe to abstract. Count promotion/materialization, targeting/pathing, accepted hits, reaction/social/faction/network work, dirty-domain/persistence work, and maximum same-frame fan-out.

`PLAYER_FAST_INTEREST_JUMP` must also have a short smoke fixture so teleport/fast travel cannot strand stale projected positions or bypass materialization budgets.

The heavier benchmark owns save/reload-under-pressure, travel-member death/handoff, arrival storms, observation load, provider handoff, and long-world endurance. Endurance should advance many simulated days without replaying every frame and report bounded high-water marks for dirty queues, live bodies, promoted Hoomans records, provider leases, tombstones, runtime indexes, transient diagnostic structures, and sparse durable extensions.

These scenarios must compose the same production paths already exercised by the isolated fixtures. Do not write a second combined-lifecycle implementation inside the test harness.

## L6 inventory/ModData scale extension

See [INVENTORY_MODDATA_STRESS.md](INVENTORY_MODDATA_STRESS.md).

The integrated simulator must support large deterministic player-native inventories, many compact Core actor inventories without live bodies, player -> many NPC and many NPC -> player transfers, inventory mutation storms, inventory-bearing subset materialization/abstraction, save/reload at inventory scale, and multi-client inventory replication pressure.

Report compact mode counts (`SEED_ONLY`, `BASELINE_DELTA`, `FULL`), logical item counts, total and per-actor encoded bytes, hydrate/capture/decode operations, dirty/persistence/network work, and same-frame high-water marks.

Selected scale points should include 100/500/1000/2000 player items and 10/50/100/500 NPC actors with representative item-count tiers, without constructing a wasteful full Cartesian matrix.

The mandatory composition matrix also includes `COMBINED_INVENTORY_FOLLOW`, `COMBINED_INVENTORY_COMBAT`, `COMBINED_INVENTORY_MATERIALIZATION`, and `COMBINED_INVENTORY_SAVE_RELOAD`.

These scenarios must prove inventory size does not accidentally make unrelated follow/combat/travel hot paths proportional to total carried item count.
