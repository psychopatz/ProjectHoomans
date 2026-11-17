# Architecture — Semantic Harness Optimization Invariants

**Status:** Active design constraints for `SemanticHarnessSpeedOptimization`.

## 1. Single Behavioral Authority Preserved

- Do not alter `semantic.harness-test.v1` schema, assertion operators, expectation matching, IR contracts, or dialogue outcomes.
- Speedups must come from removing redundant I/O, redundant reloads/recompilations, quadratic data-structure work, and redundant OS process boots—never from skipping assertions or weakening tolerances.

## 2. Hermetic Warm-Worker Reuse Contract

A warm worker reset via `worker.import_source(scenario)` (`replaceProductionDurableState == true`) must produce outputs **bit-for-bit semantically identical** to a fresh cold `LuaSemanticWorker(scenario)`:

- Clear `Runtime.playerConduct` and `Runtime.socialEvents` in `RuntimeState.resetContainers`.
- Reset `PNC.ConvoEngine.ResponseCatalog.ResetSelections()` (`LAST_VARIANTS`) during `ScenarioSession.reset`.
- Clear `PNC.Network.ClientState.semanticHubPresentation` when `replaceProductionDurableState == true` (`importSource` / `resetWorld`), while preserving it when `replaceProductionDurableState == false` (`resetConversation`) so same-day hub suppression behavior stays intact.
- Clear `Runtime.view = nil` inside `ScenarioSession.reset` (`ScenarioSession_Lifecycle.lua`) when `Runtime.replaceProductionDurableState == true` so `priorContext.phraseSalt`/`variationSeed` cannot leak across scenarios lacking explicit `phraseSalt`.
- Catalog-mutating fixture operations (`beat.register`, `behavior.register`, `flow.register`, `flow.generate`) and tests registering mock adapters (`TEST_EVIDENCE_PROVIDERS`) must either recycle/close the warm worker or use an isolated worker instance.

## 3. Kahlua2 / Lua 5.1 Compatibility Contract

Runtime Lua files shared with Project Zomboid mods (`PsychopatzJson.lua`, `PsychopatzSemanticRegistry.lua`, `PsychopatzCustomTranslationManager.lua` under `Contents/mods/`) must remain strictly Kahlua2 / Lua 5.1 safe:

- No `goto`, bitwise operators, `//`, `table.pack`, `table.unpack`, `os`, `io`, `debug`, `package`, or `next` where restricted by `pz-verify`.
- Both copies of `PsychopatzJson.lua` (harness copy under `tools/semantic_harness/lua/...` and mod copy under `Contents/mods/PsychopatzCore/...`) must remain behaviorally aligned.
- Run `pz-verify` on every modified mod Lua file.

## 4. Deterministic Process Ownership & Clean Teardown

- Buffered pipe transport (`bufsize=-1`) relies on explicit `flush()` calls on every outbound IPC frame; preserve `stdin.flush()` and non-blocking/clean `QUIT` + pipe close + `wait()` + `terminate()` reaper semantics.
- Every fixture runner shard, batch service, GUI session, and reusable imperative-test worker session (`WarmWorkerTestMixin.close_all_warm_workers()` invoked automatically by `compact_unittest.py` `finally:` and `atexit`) must guarantee deterministic cleanup (`try/finally`, `SemanticLabAuthoringService.close()`, `ConvoProbe.close()` with `atexit.unregister`, sweep background thread cancellation/join, and `XMODIFIERS=@im=none` for `DISPLAY=:0` Tk XIM safety) so `0` test-owned Lua processes remain after normal exit or failure.
- Preserve unrelated dirty work in concurrent job folders (specifically `docs/Jobs/SemanticTestSubsystem/*`) by using exact owned paths on phase commits.

## 5. Studio Lazy Hydration & Compact Live-Flushed Runners

- `ConvoEngineAuthoringPane` (`auto_refresh=False`) and `SemanticBlockRegistryPane` (`auto_load=False`) skip heavy workspace/block catalog compilation and eager `ConvoProbe` worker spawns during `SemanticHarnessApp` startup until Studio or Block Contracts tabs are selected (`<<NotebookTabChanged>>`) or explicitly refreshed, while `shell.py` starts `self._start_worker()` alongside Studio construction.
- `tools.semantic_harness.testing.compact_unittest` (`--jobs N` keeps GUI modules serialized on one shard while parallelizing headless suites), `tools.semantic_harness.testing.cli` (domain-grouped progress in compact mode), and `tests/run_tests.py` (`--suite {lua,python,all}`, `--progress-every`) flush bounded progress lines live on `stdout`.
