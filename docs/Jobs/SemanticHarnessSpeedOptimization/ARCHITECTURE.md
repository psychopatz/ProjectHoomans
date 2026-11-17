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
- Catalog-mutating fixture operations (`beat.register`, `behavior.register`, `flow.register`, `flow.generate`) and any worker transport/runtime error must mark the warm worker tainted so it is closed and replaced before the next case.

## 3. Kahlua2 / Lua 5.1 Compatibility Contract

Runtime Lua files shared with Project Zomboid mods (`PsychopatzJson.lua`, `PsychopatzSemanticRegistry.lua`, `PsychopatzCustomTranslationManager.lua` under `Contents/mods/`) must remain strictly Kahlua2 / Lua 5.1 safe:

- No `goto`, bitwise operators, `//`, `table.pack`, `table.unpack`, `os`, `io`, `debug`, `package`, or `next` where restricted by `pz-verify`.
- Both copies of `PsychopatzJson.lua` (harness copy under `tools/semantic_harness/lua/...` and mod copy under `Contents/mods/PsychopatzCore/...`) must remain behaviorally aligned.
- Run `pz-verify` on every modified mod Lua file.

## 4. Deterministic Process Ownership & Clean Teardown

- Buffered pipe transport (`bufsize=-1`) relies on explicit `flush()` calls on every outbound IPC frame; preserve `stdin.flush()` and non-blocking/clean `QUIT` + pipe close + `wait()` + `terminate()` reaper semantics.
- Every fixture runner shard, batch service, and reusable imperative-test worker session must guarantee deterministic cleanup (`try/finally` + `atexit` safety net) so `0` test-owned Lua processes remain after normal exit or failure.
- Preserve unrelated dirty work in concurrent job folders (specifically `docs/Jobs/SemanticTestSubsystem/*`) by using exact owned paths on phase commits.
