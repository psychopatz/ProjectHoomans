# Roadmap — Lightweight NPC Runtime

## Parent completion boundary

Project Hoomans ordinary gameplay is lightweight because total compact Core population no longer implies equal Hoomans runtime/persistence/scheduler work. Core-backed NPCs use one canonical durable authority, Hoomans rich state is lazy and reversible, logical commits do not synchronously flush broad state, network mutations use domain deltas, and profiling can diagnose performance without becoming the normal workload.

Do not declare the parent goal complete after one hot-path optimization. All L0-L6 developer gates must pass.

## Invariants

- Preserve PsychopatzCore SurvivorWorld as canonical actor/world authority.
- Preserve accepted NPCReplicationScaling P1-P4 behavior; do not rebuild a second portrait/roster protocol.
- No compatibility shims, permanent dual writes, fallback Hoomans actor world, or duplicate identity/appearance/inventory/social authority.
- Do not solve performance by lowering population settings or weakening server authority.
- Hoomans physical gameplay remains Hoomans-owned.
- Existing unrelated failures remain explicit baselines; do not hide them by deleting tests or broad exception handling.

## L0 — clean baseline and profiler safety

1. Reproduce the current workload through developer-side harnesses/fixtures where possible.
2. Prove normal gameplay with PsychopatzProfiler `OFF` installs no Project Hoomans deep wrappers.
3. Add/repair a cheap coarse performance-capture mode in PsychopatzCore if the current profiler cannot observe top-level runtime without deep wrapping.
4. Deep capture must be explicit, bounded/expiring and restore cleanly.
5. Establish the deterministic integrated runtime simulator described in [RUNTIME_SIMULATOR.md](RUNTIME_SIMULATOR.md). L0 must at least exercise equivalent profiler OFF/coarse/deep workloads and assert zero deep-wrapper installs/calls while OFF.
6. Record clean OFF-mode and instrumented baselines separately. Never compare instrumented timings as if they were native normal-play timings.

**Gate:** profiler-off baseline exists; profiler overhead is measured/isolated; normal play cannot accidentally retain unbounded deep wrapping; the integrated simulator has a deterministic L0 scenario and useful counters; changed Core and Hoomans profiler tests pass.

## L1 — lazy Core -> Hoomans promotion/demotion

1. Remove normal startup/generated-refresh bulk `HydrateCoreActors()` behavior.
2. Keep far/abstract actors in Core only; map/portrait/discovery paths use Core projection without creating a persistent Hoomans record.
3. Add one idempotent on-demand promotion seam for Hoomans physical/gameplay responsibilities.
4. Add safe demotion that captures durable deltas, releases Hoomans runtime memberships and retains the same canonical Core actor.
5. Choose one bounded Hoomans extension authority and document it. Prefer the existing Core namespaced-extension seam when suitable; never keep both an extension and a duplicate full Hoomans record as durable authorities.
6. Extend the integrated simulator with a large Core population plus a small relevant Hoomans set. Assert promoted/scheduled/spatial Hoomans state stays bounded to the relevant set, promotion/demotion preserves canonical identity, and mass interest entry obeys promotion/materialization budgets.
7. Prove provider handoff and recruited/unique/starting-companion behavior still use the same actor identity.

**Gate:** a world with many abstract Core actors has Hoomans rich records only for actors with current Hoomans responsibility; compact actor count may grow without proportional Hoomans scheduler/spatial/persistence growth; the simulator fails if eager bulk hydration returns; promotion/demotion/restart/provider-handoff tests pass.

## L2 — single-authority persistence and deferred physical flush

1. Remove duplicate Core-domain serialization from Core-backed Hoomans records.
2. Eliminate the Core-appearance-vs-Hoomans-schema nil serialization retry.
3. Make serializer/flush results explicit: success, terminal/not-applicable, retryable failure with bounded retry/backoff.
4. Decouple logical `PersistenceCoordinator.Commit()` from broad physical `GlobalModData.save()` and whole-registry dirty discovery.
5. Use owner/domain dirty marking and a bounded/coalescing persistence pump. OnSave/shutdown drains required durable state completely.
6. Avoid global position/stamina scanning on unrelated commits. Persist promoted physical deltas through bounded checkpoints/events.
7. Extend the simulator to count logical commits, dirty-domain marks, persistence pumps, serialization attempts, physical writes, global saves, terminal outcomes and retryable retries. Exercise repeated social/knowledge mutations and assert bounded/coalesced persistence work.
8. Preserve save/reload exactness and current Core compact inventory/appearance contracts.

**Gate:** no permanently dirty Core-backed actor on a clean new save; repeated logical mutations do not repeatedly serialize unchanged actors or globally flush ModData; the simulator proves dirty-domain proportional behavior and bounded retries; save/reload and failure injection prove no lost durable state.

## L3 — domain-delta replication

1. Audit every `forceSyncEvent`/record broadcast and map it to the smallest authoritative changed domain.
2. Reuse current presence and combat-damage deltas where valid; add bounded domain deltas for other frequently changing domains rather than sending a full record.
3. Give each delta the minimum revision/incarnation checks needed to converge.
4. Full snapshot remains initial detail/repair/fallback, not the default mutation packet.
5. Extend the simulator with representative recipients and mutations. Count full snapshots versus domain deltas, inject a revision gap, and assert ordinary mutations stay narrow while exactly documented repair/fallback converges.
6. Preserve mixed-capability and portrait-repair behavior from NPCReplicationScaling.

**Gate:** attack/reload/equipment/wound/treatment/medical/position scenarios do not build unrelated full snapshot domains; the integrated simulator exposes the full-vs-delta counts and repair behavior; reconnect/gap/fallback tests converge; network-scale tests show bounded payload/build work.

## L4 — measured runtime cadence and allocation optimization

Only start L4 after L0-L3 and a fresh profiler-OFF baseline.

1. Re-audit remaining real hot paths: follow-owner, stamina, body cleanup/audit, census/spatial, zombie aggro, materialization and decision scheduling.
2. Reuse existing throttles/caches/budgets before inventing new systems.
3. Introduce activity-sensitive world-census/global cadence only if measurement proves it material, with event-driven urgent wake paths.
4. Ensure promotion/materialization work is prioritized and bounded across frames/ticks.
5. Use the simulator as the identical before/after deterministic workload for every L4 optimization; add zombie/census/materialization pressure scenarios as needed and keep operation-count regressions separate from machine timing noise.
6. Remove avoidable per-NPC allocations/repeated engine lookups only where profiling OFF proves material cost.

**Gate:** no regression in combat/follow responsiveness, body safety or MP provider authority; measured server/frame cost improves against the L0 clean baseline on identical scenarios.

## L5 — scale acceptance, docs and phase close

Run the fast integrated smoke simulator, its scale benchmark, focused and full regression plus explicit scale workloads covering small live party plus large abstract world, dense nearby population entering/leaving range, combat pressure, repeated knowledge/social mutation, save/reload, provider handoff, reconnect/domain repair, zombie pressure, and profiler OFF versus bounded diagnostic capture.

Report Core actor count, Hoomans promoted-record count, live-body count, scheduler due/processed/deferred work, dirty extension/domain count, persistence writes/flushes/retry reasons, full-vs-domain network snapshot counts, materialization attempts/successes, census/spatial cadence, and server update/tail spikes from a clean non-deep-instrumented method.

**Gate:** the integrated smoke simulator and scale benchmark pass; developer-side tests/benchmarks pass; current architecture/system docs match implementation; no obsolete eager-hydration or duplicate-persistence instruction remains; accepted phases are locally committed with participant repos first and ProjectHoomans docs/HANDOFF last. Do not push.

Native SP/MP feel/capacity acceptance remains user-owned unless explicitly assigned.

## L6 — live FollowOwner, combat-hit, abstract-travel/materialization, and inventory/ModData scale reproduction / root-cause optimization (DEVELOPER GATES COMPLETE — READY FOR USER_ACCEPTANCE)

Native acceptance after L5 exposed severe remaining stutter while the player walks with a multi-companion follow group. Treat that as a developer-side regression gap, not as a reason to discard the accepted L0-L5 architecture.

1. Extend the **existing** integrated runtime simulator with a continuous moving-player contract; do not create a separate benchmark framework.
2. Drive real `FollowOwner` decision/formation/move-intent/PathService seams behind a narrow deterministic native-path adapter.
3. Exercise deterministic 1/3/6/12-follower workloads with at least open-field, turn/stop, obstacle/traversal, and injected-stall scenarios. The six-follower case is the primary reproduction target.
4. Collect profiler-OFF operation counters for follow decisions, formation sampling/cache behavior, move-intent requests/suppression, path requests, engine requests, replans, budget deferrals, retries, timeouts, active routes, traversal events, presence deltas, census refreshes, and per-frame bursts.
5. Add an off-by-default bounded stutter ring trace that can correlate native top-level spikes with those counters without requiring deep wrappers.
6. Record the pre-fix baseline before changing follow/path behavior. Deep profiler timings are diagnostic only and cannot serve as the clean baseline.
7. Identify the dominant source before optimizing. Candidate fixes such as owner-group pursuit-corridor caching, stable route targets, or deterministic replan staggering are conditional on measured evidence.
8. Do not blindly raise the global engine path request budget; prove queue starvation before increasing synchronous path work.
9. Preserve follow responsiveness, MP owner-travel heading, formation spacing, combat preemption, obstacle correctness, and existing L0-L5 scaling/authority contracts.
10. Rerun the full lightweight-runtime matrix, follow/path focused suites, NPC replication benchmark, and relevant full regression after the fix.
11. Extend the same integrated simulator with deterministic combat-contact controls for NPC -> zombie, NPC -> Hoomans NPC, and NPC -> player.
12. For every combat target type, compare a pre-impact miss/control workload with accepted hits so attack orchestration can be separated from impact fan-out.
13. Cover repeated nonlethal hits, synchronized multi-attacker contact, and deterministic kill/incapacitation transitions.
14. Count hit-resolution, engine reaction, health/wound, medical, faction, social/witness, semantic, network, persistence, and same-frame fan-out operations before changing combat code.
15. Identify the dominant target-specific or shared impact cost, apply the smallest evidence-backed fix, then rerun identical combat workloads plus the existing combat/wound/social/faction regressions.
16. Authoritative damage and combat outcomes remain immediate. Performance work may coalesce/defer only noncritical downstream work whose semantics permit it.
17. Add compact mobile-group/Core journey workloads that advance from world time while remaining bodyless and avoid rich Hoomans promotion while no player is relevant.
18. Verify deterministic projected-position materialization when players intercept a route, then live -> abstract handoff and continued progress without journey reset or rewind.
19. Cover time leaps, mid-route save/reload, repeated range enter/exit, abstract/live arrival convergence, live-stall handoff, multiplayer overlapping interest, and 1/10/50/100 simultaneous travelling groups.
20. Track Core journey advances/projections, promotions, materialization attempts, live bodies, abstractions/demotions, spatial/network/persistence work, and maximum same-frame handoff pressure.
21. Preserve the Core canonical group journey. Map/debug/discovery observation must remain side-effect-free and cannot promote/materialize distant actors.
22. After isolated baselines/fixes, run the mandatory cross-system stress matrix: `COMBINED_SAVE_RELOAD_PRESSURE`, `COMBINED_MATERIALIZE_COMBAT`, `TRAVEL_MEMBER_DEATH_HANDOFF`, `TRAVEL_ARRIVAL_STORM`, `OBSERVATION_PROJECTION_LOAD`, `PLAYER_FAST_INTEREST_JUMP`, `PROVIDER_HANDOFF_TRAVEL`, and `LONG_WORLD_ENDURANCE`.
23. Treat `COMBINED_MATERIALIZE_COMBAT` as a primary gameplay spike case: a projected hostile group becomes relevant, materializes under budget, acquires combat work, lands hits, then can later abstract without duplicate faction/social/network/persistence state.
24. Treat `LONG_WORLD_ENDURANCE` as the leak/backlog gate: advance many simulated days while tracking dirty queues, runtime indexes, tombstones, extension sizes, bodies, provider leases, arrival/death state, and transient diagnostics.
25. Compound scenarios must reuse real production seams and the existing simulator. They must not become a parallel test-only lifecycle.
26. Add a fourth isolated workload family for large player inventory + many NPC compact inventories. Exercise 100/500/1000/2000 player-item scale, 10/50/100/500 NPC inventory scale, player -> many NPC and many NPC -> player transfers, mutation storms, subset materialization, save/reload, and inventory replication.
27. Report Core actor inventory compact modes (`SEED_ONLY`, `BASELINE_DELTA`, `FULL`), total/per-actor encoded bytes, logical item counts, persistence/network operation counts, and hydration/capture counts so ModData optimization is evidence-driven.
28. Preserve Core as the durable NPC inventory authority. Distant NPCs with items remain compact/bodyless; only relevant live actors hydrate richer/native inventory state.
29. Extend the mandatory composition matrix with `COMBINED_INVENTORY_FOLLOW`, `COMBINED_INVENTORY_COMBAT`, `COMBINED_INVENTORY_MATERIALIZATION`, and `COMBINED_INVENTORY_SAVE_RELOAD`.

See [FOLLOW_WALK_STUTTER.md](FOLLOW_WALK_STUTTER.md), [COMBAT_HIT_STUTTER.md](COMBAT_HIT_STUTTER.md), [ABSTRACT_TRAVEL_HANDOFF_STUTTER.md](ABSTRACT_TRAVEL_HANDOFF_STUTTER.md), and [INVENTORY_MODDATA_STRESS.md](INVENTORY_MODDATA_STRESS.md).

**Gate:** all four isolated L6 workload families **and the mandatory cross-system stress matrix** pass. The simulator reproduces sustained moving-player follow work, NPC combat impact work, compact abstract/mobile-group travel through deterministic proximity materialization/abstraction, and large player/multi-NPC inventory pressure with measurable compact ModData growth; then proves those systems compose under save/reload, immediate combat after materialization, death during travel/handoff, arrival storms, heavy observation, player teleports, provider handoff, and long-world endurance. Profiler-OFF pre-fix baselines identify developer-reproducible churn before optimization; accepted fixes reduce implicated work on identical workloads without correctness regressions; distant groups remain compact/bodyless, time leaps are bounded elapsed-time calculations rather than replayed ticks, handoffs never duplicate or rewind actors/journeys, transition hooks remain idempotent, combat fan-out stays bounded, long-run transient state does not leak monotonically, and the low-overhead trace is suitable for subsequent user-owned native profiler-OFF verification.


## Core-backed recruitment acceptance

- Adopt API spawns before registry registration and record Core as the persistence authority.
- Route manual and starting-companion recruitment through one transaction. Publish personal ownership and faction/community affiliation through Core before installing the default follow order.
- Build the Colonists roster from community membership indexes and preserve those indexes when runtime records are absent during load.
- Adopt existing legacy records in bounded persistence batches. Verify the Core codec round trip and wait for a successful Core store save before retiring the old payload.
- Test failed recruitment, save and reconnect, dismissal, and demotion/re-promotion through the integrated headless harness. Rerun the existing runtime and replication matrices.
- Verify execution identity and root ownership for both repositories and the bridge runtime.
