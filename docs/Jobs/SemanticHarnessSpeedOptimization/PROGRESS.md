# Progress — Semantic Harness Speed & Runtime Optimization

**Status:** COMPLETE.
**Current phase:** P5 (COMPLETE).
**Next Chunk:** None — `P1` through `P5` complete across `psychopatzCore` and `ProjectHoomans`.

## Completed Phases

- **P5 (Final Multi-Repo Verification & Evidence Closure):**
  - Re-ran all verification gates cleanly on committed `P4` state (`psychopatzCore` `2dec87a665aa5f26ed5287300ae42859e34852c6`, `ProjectHoomans` `dedf15bd3dd564c0c57aabeb86d6a7bfa10d6235`):
    - Declarative fixtures: `228/228` PASS in `35.16 s` serial and `15.25 s` with `--jobs 4`, `0` leftover workers.
    - Core `compact_unittest` serial (`DISPLAY=:0`): `63/63` modules, `283/283` PASS in `53.750 s` (`<= 60 s`), `0` leftover workers.
    - PNC `compact_unittest` serial (`DISPLAY=:0`): `171/171` modules, `700` tests PASS (`skipped=27`) in `300.250 s` (`294.330 s` prior clean pass; `294.330–300.250 s`), `0` leftover workers.
    - Unified Python runner (`tests/run_tests.py --suite python --jobs 4 --progress-every 10`, `DISPLAY=:0`): `171/171` modules, `700` tests PASS (`skipped=27`) in `148.846 s` (`146.141 s` in `P4`).
    - Unified Lua smoke runner (`tests/run_tests.py --suite lua --progress-every 100`): `1033/1039` PASS in `9.90 s` (same `6` pre-existing unrelated baseline failures: `4` listed in `unrelated_baselines.json`, `2` pre-existing prior to job baseline).
    - Direct `DISPLAY=:0` GUI journeys + static/acceptance checks (`test_semantic_harness_gui_journeys`, `test_python_acceptance_runner`, `test_semantic_harness_static_boundaries`): `15/15` PASS in `22.498 s` (`0` XIM deadlocks, `0` Tk errors).
    - `pz-verify --kahlua --severity ERROR` on all modified mod Lua files (`PsychopatzJson.lua`, `PsychopatzJson_Parser.lua`, `PsychopatzSemanticRegistry.lua`, `PsychopatzCustomTranslationManager.lua`, `SpeechRealization.lua`, `ToolResultRealization.lua`) + `ScenarioSession_Lifecycle.lua`: `0` errors.
    - Pre/post `ps -ef | grep '[w]orker.lua'`: `0` leaked workers before and after runs (`ZERO_WORKERS_BEFORE`, `ZERO_WORKERS_AFTER`).
  - Re-indexed `codebase-memory-mcp` (`fast` mode) for both `psychopatz-core` (`2dec87a6`) and `project-hoomans` (`dedf15bd`).

- **P4 (CodeBuilder Cache, Batch Reuse, XIM/Probe Cleanup, Compact Runners & Heavy Imperative Suite Acceleration):**
  - Added thread-safe mtime/fingerprint-keyed in-process cache in `conversation_compiler.py`, `_MODEL_CACHE_LOCK` in `compiler_probes.py`, batch/matrix worker reuse (`sweep_batch.py`, `sweep_service.py`, `response_observatory.py`, `response_candidate.py`), string-prefix path slicing in `convo_engine_psdl_inventory.py`/`convo_engine_ownership_inventory.py`, fast `copy_json` in `conversation_model.py` (`psdl_compiler.py`, `convo_engine_exchange.py`, `semantic_dialogue_ir.py`, `blocks.py`), `_lua_string`/`_lua_value` fast paths (`lexicon_compiler.py`, `dialogue_content.py`), and `reconcile_apply` Step 4 skip when clean.
  - Resolved two blockers surfaced during full PNC runs: set `XMODIFIERS=@im=none` (`app_initializer.py`, `gui_test_support.py`) preventing `ibus-x11` XIM deadlocks across repeated `tk.Tk()` windows on `DISPLAY=:0`; added `ConvoProbe.close()` `atexit.unregister`, `SemanticLabAuthoringService.close()`, `close_app()` authoring-service close + background sweep thread cancel/join (`lifecycle_controller.py`, `quality_sweep_controller.py`), `close_gui_app` cleanup, and hermetic cleanup in `test_semantic_harness_gui_journeys.py` (`23 -> 0` leaked `worker.lua` processes).
  - Deferred `ConvoEngineAuthoringPane.refresh()` and `SemanticBlockRegistryPane` catalog hydration until Studio/Blocks tab activation and overlapped `_start_worker()` with `_build_deferred_studio_editors()` in `shell.py`.
  - Fixed `ScenarioSession.reset` (`ScenarioSession_Lifecycle.lua`) to clear `Runtime.view = nil` when `Runtime.replaceProductionDurableState == true` (`phraseSalt` leak), implemented process-shared `WarmWorkerTestMixin` (`worker_reuse.py`) + `\bWarmWorkerTestMixin\b` regex classification in `acceptance.py`, and adopted `WarmWorkerTestMixin` across multi-spawn PNC imperative modules.
  - Added live-flushed compact test progress across declarative fixtures (`testing/executor.py`, `testing/cli.py`), `tools.semantic_harness.testing.compact_unittest` (with `close_all_warm_workers()` reaper and `--jobs` GUI-isolated shard execution), and `ProjectHoomans/tests/run_tests.py` (`--suite {lua,python,all}`, `--progress-every`).
  - Verified (`P4`):
    - Core `compact_unittest` serial: `63/63` modules, `283` tests PASS in `49.256 s` (`<= 60 s`), `0` leaked workers.
    - PNC `compact_unittest` serial (`DISPLAY=:0`): `171/171` modules, `700` tests PASS (`skipped=27`) in `294.330 s` (`<= 300 s`), `0` leaked workers.
    - `tests/run_tests.py --suite python --jobs 4`: `171/171` modules, `700` tests PASS (`skipped=27`) in `146.141 s`, `0` leaked workers.
    - Declarative fixtures: `228/228` PASS in `35.95 s` serial and `14.93 s` with `--jobs 4`, `0` leaked workers.
    - `test_semantic_harness_gui_journeys` directly on `DISPLAY=:0`: `4/4` PASS in `21.209 s`.
    - `test_python_acceptance_runner` + `test_semantic_harness_static_boundaries`: `11/11` PASS; `pz-verify --kahlua --severity ERROR` on all modified mod Lua files + `ScenarioSession_Lifecycle.lua`: `0` errors.

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

## Initial Job Commit Baseline & Completed State

- Initial baseline (`main`): `psychopatz-core` `d063236d7b0845a2685c8a572c19ad5b4913f1a5`, `project-hoomans` `3a476aee2b9f617ab88c3df43484e73daeb78629`, `dynamic-trading` `1fac47cdb1ff5ced7b2951634511859a0d276df3` (read-only).
- Committed `P4` implementation state verified in `P5`: `psychopatz-core` `2dec87a665aa5f26ed5287300ae42859e34852c6`, `project-hoomans` `dedf15bd3dd564c0c57aabeb86d6a7bfa10d6235` (`P5` docs closure committed on top of `dedf15bd`).

## Verified Baseline Timing (Pre-Optimization)

- Declarative semantic fixtures (39 files / 228 cases): `~337 s` (`~1,480 ms/case`)
- Single 1-turn case (`execute_case`): `~1,430–1,515 ms` (`945 ms` start + `180 ms` import + `301 ms` input + teardown)
- Single `w.input("follow me")` turn: `301.1 ms`
- `PsychopatzJson` baseline benchmark: `15.68 ms` `Encode`, `40.99 ms` `Decode` (span-scan prototype: `7.24 ms` / `8.96 ms`)
- Core unittest discovery (62 files / 277 tests): `142.28 s` serial (`124.77 s` recorded in prior audit)
- PNC unittest discovery (171 files / 702 tests): `~1,005 s` with `--jobs 4` (timed out at `900 s` serial)

## Notes for Concurrent Worktree Safety

- Unstaged modifications currently exist in `docs/Jobs/SemanticTestSubsystem/*` inside `ProjectHoomans`. Preserve them completely untouched and always commit with exact phase-owned paths via `agent-phase`.
