# Agent Runbook — Lightweight NPC Runtime

## Startup

1. Read root `AGENTS.md` in ProjectHoomans and psychopatzCore before editing either repository.
2. Re-verify branch, HEAD, upstream/worktrees and dirty/staged/untracked state. Preserve unrelated work.
3. Read this job's `PROGRESS.md`, then `HANDOFF.md`, then only the active ROADMAP/ARCHITECTURE sections.
4. Read PsychopatzCore `Docs/survivor_world_runtime/README.md`, `ARCHITECTURE.md`, `COMPACT_PERSISTENCE.md`, and current `PROGRESS.md` as the canonical compact-world ownership contract.
5. Treat `SurvivorWorldAuthorityMigration` eager hydration as a superseded transitional implementation detail, not a new invariant.
6. Treat NPCReplicationScaling P1-P4 as accepted protocol work. Change it only when an L3 regression requires a minimal compatible extension.
7. Use exact current source/tests as authority. Do not implement from this audit by filename assumption alone.

## First evidence targets

ProjectHoomans:

- `PNC_Server_Lifecycle.lua`
- `PNC_CoreSurvivorWorldAdapter.lua`
- `PNC_Persistence_CoreProvider.lua`
- `PNC_Registry_LoadDirty.lua`
- `PNC_Registry_StorageCore.lua`
- `PNC_PersistenceCoordinator.lua`
- `PNC_Persistence_Serialize.lua`
- `PNC_Network_Server_Broadcasts.lua`
- `PNC_Network_Server_RosterInterest.lua`
- `PNC_Server_RecordProcessing.lua`
- existing promotion/runtime-view/provider tests

PsychopatzCore:

- `PsychopatzProfiler.lua`
- `PsychopatzProfilerPZAdapter.lua`
- profiler feature registry/bootstrap/config tests
- ActorRegistry/ActorPersistence/ActorProvider/SurvivorWorld contracts

## Performance measurement rule

Never optimize from one deeply instrumented number.

For every performance claim record exact commit/worktree state, scenario and actor/live/zombie counts, whether profiler was OFF/coarse/deep, sample duration/tick count, mean plus tail/peak or another stated distribution, and instrumentation limitations.

Use deep wrappers only for short attribution windows after a clean baseline shows a problem.

## Persistence safety rule

Do not "fix" nil serialization by coercing Core appearance into the retired Hoomans appearance schema. That would preserve duplicate authority.

Instead establish the correct Core-backed persistence boundary. Tests must prove Core canonical domains survive restart, Hoomans-owned extension survives restart, unchanged abstract actors create no Hoomans persistence work, terminal/not-applicable serialization cannot remain infinitely dirty, retryable I/O/serialization failure retries with bounded backoff, and OnSave drains required state without losing unrelated dirty data.

## Lazy-promotion rule

A map/roster/portrait query is not permission to create a Hoomans runtime record. Prefer canonical Core projection.

Every promotion trigger must name the Hoomans responsibility that requires rich state. Every demotion must release scheduler/spatial/body/runtime references and retain canonical identity.

Do not whole-registry poll Core every tick to discover promotion. Use existing interest/provider events and bounded spatial/provider seams.

## Network rule

Before adding a packet, inspect current negotiated capability, incarnation, revision and fallback contracts. Extend the existing record-sync protocol rather than creating a parallel bus.

A domain delta must be smaller and semantically narrower than the full snapshot. A delta that cannot safely converge must fall back to the existing full current baseline.

## Integrated runtime simulator

[RUNTIME_SIMULATOR.md](RUNTIME_SIMULATOR.md) is mandatory developer infrastructure for this job. Prefer one reusable simulator over many phase-specific fake worlds. Mock native Project Zomboid boundaries narrowly and execute real production modules wherever practical.

The fast smoke must remain deterministic and cheap enough for routine iteration. The slower benchmark may sweep larger actor/zombie/client populations. Every L1-L4 phase must add assertions/counters for its runtime contract before the phase closes. Native PZ is not required merely to validate architecture that can be exercised headlessly.

Do not treat the simulator as proof of Java pathfinder cost, rendering FPS, chunk streaming, real socket bytes, native model rendering or final SP/MP event behavior. Those are explicit native acceptance boundaries.

## Execution identity

Run development, test, profiler, and bridge operations as the workspace owner. Check `id -un` and compare it with `stat -c '%U' <repository>` before writing. On this workspace's host that account is `psychopatz` (UID 1000). For a root-running remote service, wrap the entire command in `sudo -u psychopatz -H bash -lc '…'` so pipelines, redirection, and child processes share the intended UID.

Run `find <repository> <participant-repository> <bridge-runtime> -user root -print` before and after each phase. Investigate any output with `stat`. Repair only verified tooling-created paths and preserve their modes. Check that the active bridge request files are readable and writable by the workspace owner and that a temporary request-directory probe can be replaced and removed. Verify Git write access with the phase commit itself.

## Validation

Prefer the integrated runtime simulator plus existing focused smoke/native-harness tests and add explicit regressions for the defects in AUDIT.md. Run touched-subsystem tests first, then the repository's normal full developer suite/baseline gates before accepting a phase.

Do not delete or weaken unrelated failing tests to make the new goal green. Label existing baseline failures separately.

## Git/phase closure

At an accepted developer-side phase: reconcile ROADMAP/PROGRESS/HANDOFF, stage only exact phase-owned paths, commit participant repository changes first, commit ProjectHoomans primary/job docs last with HANDOFF, verify the committed vector and remaining unrelated work, then continue automatically to the next mandatory phase.

Never push, create PRs/tags/releases, amend/rebase/force-update, or publish Steam Workshop content without explicit authorization.

## L6 — follow-walk stutter procedure

When native acceptance reports stutter while a player moves with followers:

1. Keep every repository/test/profiler command under the `psychopatz` user when remote tooling runs as root. Verify no new root-owned workspace/bridge artifacts.
2. Read [FOLLOW_WALK_STUTTER.md](FOLLOW_WALK_STUTTER.md), then inspect the exact current simulator, FollowOwner, formation, move-intent, PathService, and EnginePathPlanner source before editing.
3. Run existing focused follow/path tests first. Preserve failures as evidence; do not weaken assertions.
4. Implement the continuous player-motion fixture in the existing lightweight runtime simulator. The fixture must call production follow seams, not a duplicate follow algorithm.
5. Record profiler-OFF operation counts for 1/3/6/12 followers and all required L6 scenarios **before** changing runtime behavior.
6. Use bounded coarse/deep diagnostics only after the clean workload points to a lane. Never optimize from deep timing alone.
7. Classify the root cause: follow/formation target churn, move-intent churn, native request/replan churn, passage/traversal recovery, another shared runtime lane, or native-only engine cost not reproducible headlessly.
8. Apply the smallest evidence-backed fix. Shared owner-group pursuit caching or replan staggering is allowed only when the baseline proves it addresses the implicated work.
9. Rerun the exact pre-fix workload and compare operation counts plus profiler-OFF timing. Do not accept a speedup that breaks follow responsiveness or obstacle correctness.
10. Run focused follow/path, lightweight simulator, scale benchmark, NPC replication, and relevant full regression suites. Update ROADMAP/PROGRESS/HANDOFF with exact evidence.
11. Close L6 with an exact-path local commit only after its gate passes. Do not push.
12. Return to user-owned native SP/MP verification using profiler `OFF` first and the bounded stutter trace only if another hitch remains.

A headless failure to reproduce Java pathfinder cost is not permission to invent a fake fix. If operation counts are healthy but native stutter remains, preserve the developer evidence and use the low-overhead native trace to localize the engine-facing boundary.

### L6 combat-hit addition

The L6 phase is not closed by fixing FollowOwner alone.

After establishing the follow baseline, or in the same baseline pass when practical, extend the integrated simulator with the combat-contact matrix from [COMBAT_HIT_STUTTER.md](COMBAT_HIT_STUTTER.md).

Before changing combat runtime behavior:

1. run the existing combat-resolution, attack-commit, player-damage, NPC-wounds, social-damage, faction-attack, zombie-reaction, and profiler-combat focused tests
2. record profiler-OFF miss-vs-hit baselines for NPC -> zombie, NPC -> NPC, and NPC -> player
3. record repeated-hit, synchronized-contact, and kill/incapacitation transition counters
4. classify whether the spike is common impact work, zombie reaction/aggro/network, NPC wound/medical/faction/social, player BodyDamage/stats/witness work, kill-only work, or same-frame fan-out
5. fix only the measured cause while keeping authoritative damage immediate
6. rerun the identical workload plus focused and full regressions

Do not "fix" combat spikes by skipping damage, removing consequences, reducing attacker counts, hiding work behind deep profiler mode, or merely increasing combat cadence.

### L6 abstract-travel/materialization addition

The L6 phase is also not closed by follow and combat fixes alone.

Read [ABSTRACT_TRAVEL_HANDOFF_STUTTER.md](ABSTRACT_TRAVEL_HANDOFF_STUTTER.md), `PNC_AbstractTraversal_Travel.lua`, `PNC_CoreGroupTraversalBridge.lua`, PsychopatzCore GroupJourney/SurvivorWorld traversal, Presence decisions/reconcile, and Travel `OnMaterialized`/`OnAbstracted` before editing.

Before runtime changes:

1. establish a fully abstract A -> B Core group journey baseline
2. prove large world-time leaps match equivalent small-step canonical outcomes
3. intercept the projected route with a player and measure promotion/materialization
4. leave range and prove live progress is captured before abstract progression resumes
5. test repeated enter/exit, arrival, save/reload, live-stall handoff, and overlapping MP interest
6. scale to 1/10/50/100 travelling groups while keeping distant actors bodyless
7. record profiler-OFF Core journey, promotion/materialization, spatial, network, persistence, and same-frame handoff counters before optimizing

Do not optimize abstract travel by keeping bodies alive, bulk-hydrating Core actors, polling every route every frame, or sending every projected coordinate over the network.

### L6 cross-system composition pass

Passing the three isolated workload families is not the L6 stop condition.

After isolated profiler-OFF baselines identify root causes and their fixes pass the identical workloads:

1. run `COMBINED_MATERIALIZE_COMBAT` in the fast smoke and prove materialization + targeting + accepted hit + reaction/social/network/persistence fan-out stays bounded;
2. run a short `PLAYER_FAST_INTEREST_JUMP` smoke case;
3. run the heavier `COMBINED_SAVE_RELOAD_PRESSURE`, `TRAVEL_MEMBER_DEATH_HANDOFF`, `TRAVEL_ARRIVAL_STORM`, `OBSERVATION_PROJECTION_LOAD`, `PROVIDER_HANDOFF_TRAVEL`, and `LONG_WORLD_ENDURANCE` cases;
4. compare high-water marks for bodies, promoted records, provider leases, dirty queues, tombstones, runtime indexes, transient diagnostics, and sparse extension state;
5. verify transition hooks remain exactly-once and no combined case creates duplicate actor/body/journey/network/persistence authority;
6. only after these compound gates pass may L6 advance to the user-owned native SP/MP acceptance boundary.

Do not hide a compound regression by weakening an isolated threshold. If a combined case exposes a new synchronous fan-out, return to evidence collection for that lane and fix the production cause.

### L6 inventory/ModData scale addition

The L6 phase is not closed until the inventory scale gate passes.

Read [INVENTORY_MODDATA_STRESS.md](INVENTORY_MODDATA_STRESS.md), the Core actor-inventory codec/bridge, ProjectHoomans inventory bridge, server transfer authority, inventory replication, UI cache tests, and persistence-scale tests before changing inventory code.

Before optimization:

1. establish large player-native inventory scan/UI baselines;
2. establish 10/50/100/500 compact NPC inventory byte/mode baselines while actors remain abstract;
3. stress player -> many NPC and many NPC -> player transfers;
4. run mutation storms and measure dirty/persistence/network coalescing;
5. materialize only a small inventory-bearing subset and measure hydration/capture;
6. save/reload and report exact compact mode and byte distributions;
7. run inventory replication scale with mixed recipient interest;
8. preserve profiler-OFF pre-fix counts/bytes before changing compaction, serialization, lookup, hydration, or replication behavior.

Do not optimize by dropping item identity/state, converting inventory to count summaries, hydrating every actor, or imposing smaller supported inventories. Fix measured redundant work/representation.
