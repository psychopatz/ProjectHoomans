# Roadmap — Lightweight NPC Runtime

## Parent completion boundary

Project Hoomans ordinary gameplay is lightweight because total compact Core population no longer implies equal Hoomans runtime/persistence/scheduler work. Core-backed NPCs use one canonical durable authority, Hoomans rich state is lazy and reversible, logical commits do not synchronously flush broad state, network mutations use domain deltas, and profiling can diagnose performance without becoming the normal workload.

Do not declare the parent goal complete after one hot-path optimization. All L0-L5 developer gates must pass.

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
5. Record clean OFF-mode and instrumented baselines separately. Never compare instrumented timings as if they were native normal-play timings.

**Gate:** profiler-off baseline exists; profiler overhead is measured/isolated; normal play cannot accidentally retain unbounded deep wrapping; changed Core and Hoomans profiler tests pass.

## L1 — lazy Core -> Hoomans promotion/demotion

1. Remove normal startup/generated-refresh bulk `HydrateCoreActors()` behavior.
2. Keep far/abstract actors in Core only; map/portrait/discovery paths use Core projection without creating a persistent Hoomans record.
3. Add one idempotent on-demand promotion seam for Hoomans physical/gameplay responsibilities.
4. Add safe demotion that captures durable deltas, releases Hoomans runtime memberships and retains the same canonical Core actor.
5. Choose one bounded Hoomans extension authority and document it. Prefer the existing Core namespaced-extension seam when suitable; never keep both an extension and a duplicate full Hoomans record as durable authorities.
6. Prove provider handoff and recruited/unique/starting-companion behavior still use the same actor identity.

**Gate:** a world with many abstract Core actors has Hoomans rich records only for actors with current Hoomans responsibility; compact actor count may grow without proportional Hoomans scheduler/spatial/persistence growth; promotion/demotion/restart/provider-handoff tests pass.

## L2 — single-authority persistence and deferred physical flush

1. Remove duplicate Core-domain serialization from Core-backed Hoomans records.
2. Eliminate the Core-appearance-vs-Hoomans-schema nil serialization retry.
3. Make serializer/flush results explicit: success, terminal/not-applicable, retryable failure with bounded retry/backoff.
4. Decouple logical `PersistenceCoordinator.Commit()` from broad physical `GlobalModData.save()` and whole-registry dirty discovery.
5. Use owner/domain dirty marking and a bounded/coalescing persistence pump. OnSave/shutdown drains required durable state completely.
6. Avoid global position/stamina scanning on unrelated commits. Persist promoted physical deltas through bounded checkpoints/events.
7. Preserve save/reload exactness and current Core compact inventory/appearance contracts.

**Gate:** no permanently dirty Core-backed actor on a clean new save; repeated logical mutations do not repeatedly serialize unchanged actors or globally flush ModData; save/reload and failure injection prove no lost durable state.

## L3 — domain-delta replication

1. Audit every `forceSyncEvent`/record broadcast and map it to the smallest authoritative changed domain.
2. Reuse current presence and combat-damage deltas where valid; add bounded domain deltas for other frequently changing domains rather than sending a full record.
3. Give each delta the minimum revision/incarnation checks needed to converge.
4. Full snapshot remains initial detail/repair/fallback, not the default mutation packet.
5. Preserve mixed-capability and portrait-repair behavior from NPCReplicationScaling.

**Gate:** attack/reload/equipment/wound/treatment/medical/position scenarios do not build unrelated full snapshot domains; reconnect/gap/fallback tests converge; network-scale tests show bounded payload/build work.

## L4 — measured runtime cadence and allocation optimization

Only start L4 after L0-L3 and a fresh profiler-OFF baseline.

1. Re-audit remaining real hot paths: follow-owner, stamina, body cleanup/audit, census/spatial, zombie aggro, materialization and decision scheduling.
2. Reuse existing throttles/caches/budgets before inventing new systems.
3. Introduce activity-sensitive world-census/global cadence only if measurement proves it material, with event-driven urgent wake paths.
4. Ensure promotion/materialization work is prioritized and bounded across frames/ticks.
5. Remove avoidable per-NPC allocations/repeated engine lookups only where profiling OFF proves material cost.

**Gate:** no regression in combat/follow responsiveness, body safety or MP provider authority; measured server/frame cost improves against the L0 clean baseline on identical scenarios.

## L5 — scale acceptance, docs and phase close

Run focused and full regression plus explicit scale workloads covering small live party plus large abstract world, dense nearby population entering/leaving range, combat pressure, repeated knowledge/social mutation, save/reload, provider handoff, reconnect/domain repair, and profiler OFF versus bounded diagnostic capture.

Report Core actor count, Hoomans promoted-record count, live-body count, scheduler due/processed/deferred work, dirty extension/domain count, persistence writes/flushes/retry reasons, full-vs-domain network snapshot counts, materialization attempts/successes, census/spatial cadence, and server update/tail spikes from a clean non-deep-instrumented method.

**Gate:** developer-side tests/benchmarks pass; current architecture/system docs match implementation; no obsolete eager-hydration or duplicate-persistence instruction remains; accepted phases are locally committed with participant repos first and ProjectHoomans docs/HANDOFF last. Do not push.

Native SP/MP feel/capacity acceptance remains user-owned unless explicitly assigned.
