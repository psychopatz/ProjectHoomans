# Progress — Lightweight NPC Runtime

## Current state

**IN PROGRESS — L0, L1, L2 COMPLETE; L3 NEXT.**

Phase L0 established clean profiler-OFF behavior, safe explicit time-bounded deep profiling (`coarse` vs `deep`), and the deterministic integrated headless runtime simulator foundation before optimizing downstream phases.

## L0 — Clean baseline and profiler safety (COMPLETE)

- **Persisted config trace:** `~/Zomboid/Lua/PsychopatzCore_Profiler.txt` is loaded by `PsychopatzProfilerBootstrap.Initialize() -> readConfiguredConfig()`. Persisted `performance_depth=deep` is automatically downgraded to `"coarse"` (`persistedDeepDowngraded = true`), and `serializeConfig` / `profiler_config.py` never persist `"deep"`.
- **Shared Core profiler safety:** Explicit `performance_depth = "coarse" | "deep"` with clamped time-bounding (`5000ms..300000ms`, default `60000ms`), automatic expiry checks in `Begin`/`Wrap`/`Sample`, deterministic deep-hook restoration on expiry and full restoration on `Stop()` / `Bootstrap.Disable()`, and explicit snapshot/report labels (`deep_instrumented_diagnostic_only` vs `coarse_sampled` vs `no_performance_timers`).
- **Hoomans profiler split:** 10 coarse top-level boundaries (`0` deep wrappers in `COARSE`, `0` total wrappers in `OFF`) vs 97 explicit time-bounded deep wrappers (`RestoreDeep()`, idempotent `RestoreServerTick()`).
- **Integrated deterministic headless runtime simulator:** Created `tests/support/lightweight_runtime_simulator.lua`, `tests/pnc_lightweight_runtime_simulation_smoke.lua`, and `tests/benchmarks/lightweight_npc_runtime.lua`.
- **HEADLESS LUA SIMULATOR (NON-NATIVE) L0 baselines:**
  - Smoke (`N=100, Z=40, 15s`):
    - `OFF`: `coarseWr=0, deepWr=0, deepCalls=0, tickCpuMs=1188.04ms`
    - `COARSE`: `coarseWr=10, deepWr=0, coarseCalls=1598, deepCalls=0, tickCpuMs=1247.94ms`
    - `DEEP (5s expiry)`: `DeepExpired=true, EndDeepWrappersInstalled=0, coarseCalls=1605, deepCalls=2941, tickCpuMs=1340.43ms`
    - Identical gameplay/persistence/network op counts across all three modes: `core=100, promoted=100, live=9, schedProc=231, commits=5, serAttempts=500, globalSaves=5, dirtyEnd=100, fullSnap=168, census=129, extraZScans=102, SafePhaseFailures=0`
  - Benchmark (`Z=64, 20s`):
    - `N=100`: `OFF 2001.45ms` (`CoarseWr=0, DeepWr=0`), `COARSE 2066.12ms` (`+64.67ms`), `DEEP 2382.27ms` (`+380.82ms`, `10781` deepCalls); `promoted=100, dirtyEnd=100, serAttempts=600, globalSaves=6, fullSnap=216`
    - `N=500`: `OFF 4004.86ms`, `COARSE 4002.27ms` (`-2.58ms`), `DEEP 4289.13ms` (`+284.28ms`, `12392` deepCalls); `promoted=500, dirtyEnd=500, serAttempts=3000, globalSaves=6, fullSnap=216`
- **Pre-existing unrelated Core baseline failures left untouched:** `psychopatz_profiler_client_composition_smoke.lua` (`module 'TimedActions/ISAttachItemHotbar' not found` in headless env) and `psychopatz_profiler_server_composition_smoke.lua` (`OnClientCommand` count `2` vs `1`).
- **L0 verification:** `luac -p` pass, `pz_verify.py --kahlua` 0 errors/0 warnings, Core Lua profiler tests 5/5 pass, Core Python profiler tests 54/54 pass, Hoomans profiler tests 10/10 pass, simulator smoke 1/1 pass.

## L1 — Lazy Core -> Hoomans promotion/demotion (COMPLETE)

- **Single bounded Hoomans durable extension authority:** `actor.extensions["ProjectHoomans.ActorExtension"]` (`schemaVersion = 1`) via `PNC_CoreActorExtension.lua`. Never duplicates Core-owned identity, appearance, `personalInventory`, social/persona/knowledge, SurvivorWorld affiliation/world/journey, or `providerLease`. Unmodified bystanders encode to `nil` (0 bytes); Core-backed promoted records never write legacy `PNC_npc_<id>` ModData or dirty the legacy Hoomans directory.
- **Core spatial & extension index (`psychopatzCore`):** Added lazy incremental 32-tile `_spatialIndex` and `QueryNearPosition` / `HasActiveActor` / `GetExtension` / `ListWithExtension` / `ListMaterialized` to `PsychopatzActorRegistry` & `PsychopatzActors`; skipped $O(N)$ identity index rebuild in `Commit()` when identity fields are unchanged.
- **Lazy promotion & reversible demotion (`ProjectHoomans`):** Removed bulk startup/refresh `HydrateCoreActors()`; added `RestoreActiveCoreActors`, bounded interest promotion (`CORE_PROMOTE_MAX_PER_REFRESH = 4`, respecting `PresenceAdmission` headroom), single idempotent `PromoteCoreActor`, `HasActiveHoomansResponsibility` (treating default standby jobs `GuardAnchor` and `HuntNearestPlayer` as non-blocking unless an explicit order/target/combat/facility is active), `SyncPromotedCoreActorToCore`, `DemoteCoreActor`, and bounded `PumpDemotions` (`CORE_DEMOTE_GRACE_MS = 2000`, `CORE_DEMOTE_PUMP_MS = 1000`, `CORE_DEMOTE_MAX_PER_PUMP = 8`) backed by non-destructive `Registry.ReleasePromotedRecord`.
- **Consumer identity preservation:** Updated `PNC_CorePresenceAdapter` (lazy promotion on `DebugForceLive`, rollback on failure, demotion on `DebugRelease`), `PNC_UniqueNPCRegistry_{Maintenance,Diagnostics}`, `PNC_AbstractGroupManager_Membership`, `PNC_MobileGroupDirector_Members`, and `PNC_StartingCompanionService_{Ensure,Grant}` to preserve canonical Core actor IDs without eager hydration or duplication.
- **HEADLESS LUA SIMULATOR (NON-NATIVE) L1 results vs L0:**
  - Smoke (`N=100, Z=40, 15s`, `OFF`): `startProm=0` (was 100), `peakProm=9`, `endProm=9`, `schedEnd=9`, `spatialEnd=9`, `serAttempts=18` (was 500), `dirtyEnd=0` (was 100), `fullSnap=157` (was 168), `SafePhaseFailures=0`, `tickCpuMs=1147.10ms`; exact bit-for-bit operational invariance across `OFF` / `COARSE` / `DEEP` and `OFF_300` (`N=300` vs `N=100`).
  - Departure (`DEPART`): `peakProm=9 -> endProm=0, demoted=9, schedEnd=0, spatialEnd=0, CoreActors=100, SafePhaseFailures=0`.
  - Crowd burst (`MASS40`): `peakProm=20 <= 24`, `MaxPromotionsInSingleRefresh <= 4`, `MaxMaterializationsInSingleTick <= 2`, `SafePhaseFailures=0`.
  - Benchmark (`Z=64, 20s`, `OFF`):
    - `N=100`: `Promoted=9` (was 100), `DirtyEnd=0` (was 100), `serAttempts=18` (was 600), `FullSnap=205` (was 216), `TickCpuMs=2094.12ms`.
    - `N=500`: `Promoted=9` (was 500), `DirtyEnd=0` (was 500), `serAttempts=18` (was 3000), `FullSnap=205` (was 216), `TickCpuMs=3340.07ms` (was 4004.86ms).
- **L1 verification:** `luac -p` pass & `pz_verify.py --kahlua --severity WARNING` 0 errors/0 warnings on all modified/created runtime Lua files in both repos; Core spatial/extension smoke + 44/44 related Core actor/survivor_world tests pass (leaving the 2 pre-existing unrelated Core baseline failures untouched); ProjectHoomans focused suites pass (`core_actor` 4/4, `survivor_world` 8/8, `lightweight` 2/2, `presence` 119/119, `persistence` 13/13, `registry` 10/10, `replication` 3/3, `starting_companion` 12/12, `unique_npc` 7/7, `profiler` 10/10).

## L2 — Single-authority persistence and deferred physical flush (COMPLETE)

- **Explicit outcome classification & zero duplicate Core serialization:** `PNC.Persistence.SerializeRecord` returns `(payload, outcome, reason)` with canonical `WRITTEN` / `TERMINAL_OR_NOT_APPLICABLE` / `RETRYABLE_FAILURE`; rejects `coreBacked`/`core_extension` (`owned_by_core_extension`) and Core appearance envelopes (`core_appearance_authority_mismatch`) as terminal without down-converting to legacy `schemaVersion == 2`. `CoreProvider.SyncPromotedCoreActorToCore` returns explicit `WRITTEN` / `TERMINAL_OR_NOT_APPLICABLE` / `RETRYABLE_FAILURE` and sets `Registry.CoreStoreDirty = true` on Core commit.
- **Bounded retry/backoff & terminal quarantine:** `PNC_Registry_LoadDirty.lua` clears terminal outcomes on attempt 1 with structured warning + `PersistenceDiagnostics.terminalEvents`; tracks retryable failures in `Registry.RetryState` with exponential backoff (`PERSISTENCE_RETRY_BASE_MS = 1000` .. `PERSISTENCE_RETRY_MAX_MS = 30000`) and quarantines after `PERSISTENCE_RETRY_MAX_ATTEMPTS = 5` (cleared on fresh gameplay `MarkDirty`), eliminating infinite dirty retry loops.
- **Decoupled logical commit, coalescing pump & bounded physical checkpoints:** Refactored `PNC_PersistenceCoordinator.lua` into ordered `DOMAINS` with `Commit()` (default deferred enqueue/coalesce; zero synchronous `service.Save`, `Registry.FlushDirty`, `RuntimeStore.Save`, or `GlobalModData.save()`), `Pump()` (wired into `PNC_Server_SubsystemPumps.lua:H.FinishTick` at `PERSISTENCE_PUMP_INTERVAL_MS = 2000`, `PERSISTENCE_PUMP_MAX_RECORDS = 8`, no `GlobalModData.save()`, no `RuntimeStore.Save()`), and complete synchronous `FlushNow()` on `OnSave` (`"world_save"`), shutdown (`OnServerShutdown` / `OnGameEnd`), or `{ immediate = true }`. Added bounded round-robin `Registry.PumpPhysicalCheckpoints` (`5000ms` cadence, max `8` promoted records/pass) instead of scanning all records on unrelated commits. Routed direct gameplay `GlobalModData.save()` callers (`PNC_ColonyManagement_FactionCommands`, `PNC_ProvisionPolicyService`, `PNC_DebugCompanionRecruit_Persistence`) through `PersistenceCoordinator`, exposed `Persistence.Pump` as a coarse profiler boundary, and updated the 36 native restart fixtures in `tests/native/*_native_write_smoke.lua` to pass `{ immediate = true }`.
- **HEADLESS LUA SIMULATOR (NON-NATIVE) L2 results vs L0/L1:**
  - Smoke (`N=100, Z=40, 15s`, `OFF`): `globalSaves=1` (was 5), `coreSaves=2`, `term=0`, `retry=0`, `dirtyEnd=0`, `SafePhaseFailures=0`, `tickCpuMs=957.84ms`; `OFF_300` (`N=300`): `tickCpuMs=813.71ms` (was `1950.67ms` in L1), bit-identical op counts vs `N=100`; `MUT_STORM` (25 rapid knowledge commits over 6s): coalesced to `pumps=3`, `serAttempts=5`, `globalSaves=1`, `coreSaves=2`, `dirtyEnd=0`.
  - Benchmark (`Z=64, 20s`, `OFF`):
    - `N=100`: `Promoted=9, DirtyEnd=0, globalSaves=1` (was 6), `TickCpuMs=1613.59ms` (L1: `2094.12ms`, L0: `2001.45ms`).
    - `N=500`: `Promoted=9, DirtyEnd=0, globalSaves=1` (was 6), `TickCpuMs=1836.38ms` (L1: `3340.07ms`, L0: `4004.86ms`).
- **L2 verification:** `luac -p` pass & `pz_verify.py --kahlua --severity WARNING` 0 errors/0 warnings on all 12 modified runtime Lua files (zero `next()` calls); `luac -p` pass on all 36 updated native write tests; new `pnc_lightweight_persistence_authority_smoke.lua` pass; all 14 focused suites pass (`persistence` 14/14, `registry` 10/10, `presence` 119/119, `lightweight` 3/3, `profiler` 10/10, `core_actor` 4/4, `survivor_world` 8/8, `knowledge` 17/17, `starting_companion` 12/12, `provision` 5/5, `colony` 21/21, `recruit` 2/2, `world_save` 3/3, `companion` 28/28); full `tests/run_tests.py` sweep 1076/1080 pass (4 pre-existing unrelated failures untouched: `pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke`).

## Accepted dependencies

Do not reopen:

- Compact Survivor World S0-S11 canonical ownership and compact Core actor persistence;
- NPCReplicationScaling P1-P4 portrait/roster protocol acceptance;
- Core actor lifecycle/provider/GC ownership.

This job corrects Hoomans runtime adoption so it actually obeys those accepted contracts during ordinary play.

## Next Chunk

**L3 — domain-delta replication.**
