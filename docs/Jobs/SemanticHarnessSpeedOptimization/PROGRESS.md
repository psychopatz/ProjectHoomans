# Progress — Semantic Harness Speed & Runtime Optimization

**Status:** IN PROGRESS.
**Current phase:** P4.
**Next Chunk:** Execute `P4` — add mtime/fingerprint-keyed in-process cache for `compile_conversation_sources`, reuse warm workers in `SweepBatchExecutor`/`DialogueQualitySweepService`/`run_quality_matrix`/`preview_authored_variant`, and adopt warm-worker reuse in slow imperative test modules.

## Completed Phases

- **P3 (Hermetic State Reset & Warm-Worker Reuse + Parallelism for Declarative Fixtures):**
  - Fixed all state-reset leaks across `import_source`/`reset`: cleared `runtime.playerConduct` and `runtime.socialEvents` in `RuntimeState.resetContainers`, added `ResetSelections()` to `SpeechRealization.lua` and `ToolResultRealization.lua` and called them alongside `ResponseCatalog.ResetSelections()` in `ScenarioSession.reset`, and cleared `PNC.Network.ClientState.semanticHubPresentation` when `replaceProductionDurableState == true`.
  - Added warm-worker reuse (`execute_case(..., worker=...)`, `execute_cases`, `execute_cases_batch`) with `warm_worker_imported` ordering guard, `DTHoomans` preset keying, and catalog-mutation/error recycling, plus `--jobs N` (`execute_cases_parallel`) in `cli.py`.
  - Added `HermeticWarmWorkerReuseTests` in `test_worker_session.py`.
  - Verified: 228/228 declarative semantic fixtures PASS in `39.77 s` serial and `18.31 s` with `--jobs 4` (remaining compiler-case time `~11 s` to be cached in `P4`), `test_fixture_operations` + `test_acceptance_runner` (`17 tests OK`), `test_worker_session` (`2 tests OK`), `pz-verify` 0 errors, `0` leftover Lua workers.

- **P2 (Lua Worker Startup Deduplication, Lazy Registry Sort & Translation Shard Cache):**
  - Replaced per-call `table.sort` in `PsychopatzSemanticRegistry.RegisterPattern` with O(1) duplicate lookup + `_patternsDirty` lazy sorting in `Registry.GetPatterns()`.
  - Registered loaded relative module names in `package.loaded` inside `ProductionModules.lua` to prevent duplicate `require` passes.
  - Added `SEMANTIC_HARNESS_DEFER_INITIAL_IMPORT=1` when `import_source_on_start=True` in `core/worker.py`, skipping redundant `ScenarioSession.importSource` in `worker.lua` and heavy `hello` projection assembly in `CommandRouter_Session.lua`.
  - Added `previousLanguage ~= currentLanguage` guard in `PsychopatzCustomTranslationManager.setLanguageOverride` and in-memory decoded shard caching in `readCatalog`.
  - Verified: cold `LuaSemanticWorker` `__init__` `346.21–365.56 ms` (`<= 400 ms`, down from `~1,125 ms`), `pz-verify` 0 errors on modified mod Lua files, Core + PNC verification suites (`21 tests OK`) and `test_startup_session_parity` (`4 tests OK, 2 skipped`) passing.

- **P1 (Buffered Transport, Pure-Lua JSON Fast-Path & Redundant Copy Removal):**
  - Switched `LuaProcess` pipe transport (`psychopatzCore/tools/semantic_harness/transport/process.py`) from `bufsize=0` to `bufsize=-1`.
  - Optimized `PsychopatzJson.lua` (both harness and mod copies) and `PsychopatzJson_Parser.lua` with `string.find` span scanning, anchored `string.match(..., position)` number parsing, and fast-path single-pass string escaping.
  - Removed redundant `deepcopy` in `state.py` (`ImportedSourceSnapshot.from_scenario`) and `worker_conversation.py` (`mutation_response`), plus duplicate `_sync_effective_scenario` call.
  - Verified: `test_process`, `test_protocol`, `test_state`, `test_worker`, `test_core_worker` (16 tests OK), `test_worker_session` (1 test OK), Lua JSON roundtrip OK, `pz-verify` 0 errors on modified mod Lua files, `worker.input("follow me")` `56.94–84.74 ms` (`<= 90 ms`, down from `301.1 ms`).

## Current Commit Baseline

- `psychopatz-core`: `d063236d7b0845a2685c8a572c19ad5b4913f1a5` (`main`)
- `project-hoomans`: `3a476aee2b9f617ab88c3df43484e73daeb78629` (`main`)
- `dynamic-trading` (read-only): `1fac47cdb1ff5ced7b2951634511859a0d276df3` (`main`)

## Verified Baseline Timing (Pre-Optimization)

- Declarative semantic fixtures (39 files / 228 cases): `~337 s` (`~1,480 ms/case`)
- Single 1-turn case (`execute_case`): `~1,430–1,515 ms` (`945 ms` start + `180 ms` import + `301 ms` input + teardown)
- Single `w.input("follow me")` turn: `301.1 ms`
- `PsychopatzJson` baseline benchmark: `15.68 ms` `Encode`, `40.99 ms` `Decode` (span-scan prototype: `7.24 ms` / `8.96 ms`)
- Core unittest discovery (62 files / 277 tests): `142.28 s` serial (`124.77 s` recorded in prior audit)
- PNC unittest discovery (171 files / 702 tests): `~1,005 s` with `--jobs 4` (timed out at `900 s` serial)

## Notes for Concurrent Worktree Safety

- Unstaged modifications currently exist in `docs/Jobs/SemanticTestSubsystem/*` inside `ProjectHoomans`. Preserve them completely untouched and always commit with exact phase-owned paths via `agent-phase`.
