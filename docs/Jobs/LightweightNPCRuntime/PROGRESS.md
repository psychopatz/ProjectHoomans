# Progress — Lightweight NPC Runtime

## Current state

**IN PROGRESS — L0 COMPLETE; L1 NEXT.**

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

## Accepted dependencies

Do not reopen:

- Compact Survivor World S0-S11 canonical ownership and compact Core actor persistence;
- NPCReplicationScaling P1-P4 portrait/roster protocol acceptance;
- Core actor lifecycle/provider/GC ownership.

This job corrects Hoomans runtime adoption so it actually obeys those accepted contracts during ordinary play.

## Next Chunk

**L1 — lazy Core -> Hoomans promotion/demotion.**
