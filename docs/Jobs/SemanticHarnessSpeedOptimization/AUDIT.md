# Performance Audit — Semantic Harness Runtime & Test Estate

**Status:** Baseline audit verified (`RUNTIME_VERIFIED` / `CODE_VERIFIED`).
**Baseline Commits:**
- `psychopatz-core`: `d063236d7b0845a2685c8a572c19ad5b4913f1a5`
- `project-hoomans`: `3a476aee2b9f617ab88c3df43484e73daeb78629`
- `dynamic-trading` (read-only): `1fac47cdb1ff5ced7b2951634511859a0d276df3`

## Measured Single-Item Latency (`~1,430–1,515 ms` per 1-turn case)

1. `LuaProcess.start()` (OS spawn + Lua boot + `hello` handshake): `945.2 ms`
   - `ProductionModules.load` (loading Lua files + duplicate `require` passes): `699.4 ms`
   - Initial `ScenarioSession.configureRuntime` + `ScenarioSession.importSource`: `58.2 ms`
   - `hello` JSON encode (180 KB) + IPC transfer + decode: `~187.6 ms`
2. Redundant `worker.import_source(scenario)` on `__init__`: `180.4 ms` (Total `__init__`: `1,125.6 ms`)
3. `worker.input(...)` (`INPUT` 210 KB + `MUTATION_PROJECTION` 57 KB): `301.1 ms`
4. `worker.close()` + teardown: `~15–80 ms`

## Seven Verified Bottlenecks

### 1. Unbuffered `bufsize=0` Pipe `readline()` 1-Byte Syscalls
- **Files:** `psychopatzCore/tools/semantic_harness/transport/process.py` (`LuaProcess.start`, `_read_stdout`).
- **Mechanism:** `subprocess.Popen(..., bufsize=0)` makes `process.stdout` an unbuffered `_io.FileIO`. Calling `.readline()` falls back to `_IOBase.readline()`, issuing one `read(fd, 1)` syscall per byte (~586 KB across `hello`, `IMPORT_SOURCE`, `INPUT`, and `MUTATION_PROJECTION` = ~586,000 syscalls per single case, ~390–420 ms overhead).
- **Verified Benchmark (`bufsize=0` -> `bufsize=-1`):**
  - `readline(200 KB)`: `194.8 ms` -> `<1.0 ms`
  - `w.input("follow me")`: `301.1 ms` -> `77.1 ms` (`3.9x` faster)
  - `w.import_source(...)`: `162.4 ms` -> `41.7 ms` (`3.9x` faster)
  - `w.reset()`: `182.9 ms` -> `40.1 ms` (`4.5x` faster)

### 2. Cold Subprocess Spawn Per Fixture Case, Sweep Case, and Matrix Row
- **Files:** `psychopatzCore/tools/semantic_harness/testing/{executor.py,cli.py,sweep_batch.py,sweep_service.py}`, `psychopatzCore/tools/semantic_harness/ui/regression_controller.py`, `psychopatzCore/tools/semantic_harness/inspection/response_observatory.py`.
- **Mechanism:** `execute_case()` spawns and tears down a fresh `LuaSemanticWorker` process for all 228 declarative fixture cases instead of reusing a warm worker via `worker.import_source(case.scenario)`.
- **Hermeticity Audit:** Reusing one warm worker across all 228 cases surfaced **only 3 state-reset leaks** (6/228 failures before fix):
  1. `PNC.ConvoEngine.ResponseCatalog.ResetSelections()` (`ResponseCatalog_Selection.lua`) is never called in `ScenarioSession.reset` (`ScenarioSession_Lifecycle.lua`), leaking `LAST_VARIANTS` anti-repeat rotation across cases (`health_injured_en`, `health_companion_wait_tl`).
  2. `Runtime.playerConduct` and `Runtime.socialEvents` are not cleared in `RuntimeState.resetContainers` (`RuntimeState.lua`), leaking conduct evidence IDs (`duplicate_evidence_id` in `health_hostile_boundary_en/tl`, `apology_context_clarification`).
  3. `PNC.Network.ClientState.semanticHubPresentation` (`SemanticAdapters_Core_Context.lua`) is preserved unconditionally; it must be preserved only on `resetConversation` (`Runtime.replaceProductionDurableState == false`) and cleared on `importSource` / `resetWorld` (`Runtime.replaceProductionDurableState == true`).
  - Note: Cases running catalog-mutating operations (`beat.register`, `behavior.register`, `flow.register`, `flow.generate`) mutate in-memory catalogs and must recycle the worker afterward.

### 3. Duplicate Module Execution (`dofile` vs `require`) + Quadratic Pattern Sorting on Startup
- **Files:** `ProjectHoomans/tools/providers/pnc/lua/worker/ProductionModules.lua`, `ProjectHoomans/tests/support/test.lua`, `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticRegistry.lua`, `ProjectHoomans/tools/providers/pnc/lua/worker.lua`, `psychopatzCore/tools/semantic_harness/core/worker.py`.
- **Mechanism:**
  - `ProductionModules.load` calls `Test.load()` (`dofile`) without registering `package.loaded[relativePath]`. Subsequent `require(...)` calls execute 21 modules a second time (`PNC_SemanticCatalog.lua` runs twice: `173.0 ms + 237.1 ms = 410.1 ms`).
  - `PsychopatzSemanticRegistry.RegisterPattern` is called 443 times per registration pass, linearly scanning `PatternOrder`, running `table.sort`, and rebuilding `OrderedPatterns` on every call (`159.1 ms` per pass). Lazy sorting via `_patternsDirty` in `Registry.GetPatterns()` eliminates 442 redundant sorts (`159.1 ms -> ~2.0 ms`).
  - `worker.lua` executes `configureRuntime` (`20.6 ms`) + `importSource(initialScenario)` (`37.6 ms`) during startup right before `LuaSemanticWorker.__init__` sends `IMPORT_SOURCE` over IPC.

### 4. Unconditional Translation Catalog Cache Invalidation
- **Files:** `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua`, `ProjectHoomans/tools/providers/pnc/lua/worker/Translations.lua`.
- **Mechanism:** `Translations.setLanguage` calls `Manager.setLanguageOverride(selected)` on every `reset` / `import_source`, which unconditionally calls `invalidateLoadedCatalogs()`, wiping `Manager.Data` and `source._state` even when the language is unchanged (`"EN"`), forcing ~57 KB of JSON translation shards to be re-read and decoded per reset/turn (`~11.8 ms`). Caching immutable decoded shard tables across `"EN" <-> "TL"` switches eliminates repeat disk decode in matrix tests as well.

### 5. Pure-Lua `PsychopatzJson` Byte-by-Byte Loops + Duplicate Suggestion Builds & `deepcopy`
- **Files:** `psychopatzCore/tools/semantic_harness/lua/PsychopatzCore/Serialization/PsychopatzJson.lua`, `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Serialization/PsychopatzJson.lua`, `ProjectHoomans/tools/providers/pnc/lua/worker/{Conversation_Turn.lua,Conversation_View_Finalize.lua,OutputProjection_ObservationSuggestions.lua}`, `ProjectHoomans/tools/providers/pnc/runtime/worker_conversation.py`, `psychopatzCore/tools/semantic_harness/core/state.py`.
- **Mechanism:**
  - `PsychopatzJson.lua` scans strings and whitespace byte-by-byte via `string.sub(text, pos, pos)`, slices tails for number matching, and runs 5 chained `string.gsub` calls per string. Using `string.find` span scanning, anchored `string.match(..., pos)`, and fast single-pass escaping benchmarked `2.2x` faster `Encode` (`15.7 ms -> 7.2 ms`) and `4.6x` faster `Decode` (`41.0 ms -> 9.0 ms`).
  - `DialogueSuggestions.Build` / `RefreshRootSuggestions` builds a 98 KB suggestion payload twice per view/turn (`7.65 ms`).
  - Python `deepcopy` is called repeatedly on freshly `json.loads()`-decoded transport payloads (`~15 ms/turn`).

### 6. Uncached `compile_conversation_sources` Across CodeBuilder / CLI / Studio Tests
- **Files:** `psychopatzCore/tools/semantic_harness/codebuilder/{conversation_compiler.py,service.py}`, `psychopatzCore/tools/semantic_harness/inspection/response_candidate.py`, `psychopatzCore/tools/semantic_harness/testing/compiler_probes.py`.
- **Mechanism:** Unlike `compiler_probes.py`, `SemanticLabAuthoringService`, CLI dataset commands, and `response_candidate.py` re-parse and compile all 500+ canonical JSON source files from scratch on every read-only call (`~1.5–2.0 s` each). `test_dataset_compiler_and_workflow.py` alone spends `30.65 s` across 7 tests repeating identical compilations.

### 7. Imperative Test Suite & Service Worker Churn
- **Files:** `sweep_batch.py`, `sweep_service.py`, `response_observatory.py`, `response_candidate.py`, and 118 PNC test modules (`451` `LuaSemanticWorker` call sites across 702 test methods).
- **Mechanism:** `DialogueQualitySweepService`/`SweepBatchExecutor` spawns 3 temporary metadata workers + 1 worker per case; `preview_authored_variant` spawns 5 separate workers per call; imperative test suites spawn workers inside `for` / `subTest` loops or per test method.

## Root Causes Surfaced & Fixed During `P4`

### 8. X11 `ibus-x11` (XIM) Deadlock on Repeated `tk.Tk()` Destruction/Creation
- **Files:** `psychopatzCore/tools/semantic_harness/ui/app_initializer.py`, `ProjectHoomans/tools/providers/pnc/tests/gui_test_support.py`.
- **Mechanism:** Mapping `ttk.Entry` on `DISPLAY=:0` and destroying `tk.Tk()`, then creating another `tk.Tk()`, deadlocked inside `ttk.Notebook.add` waiting on an `ibus-x11` XIM handshake. Setting `os.environ.setdefault("XMODIFIERS", "@im=none")` before Tk root creation eliminates the deadlock cleanly on `DISPLAY=:0` without `xvfb-run`.

### 9. Leaked `ConvoProbe` `worker.lua` Processes & Unjoined Background Sweep Threads
- **Files:** `psychopatzCore/tools/semantic_harness/codebuilder/{convo_probe.py,service.py}`, `psychopatzCore/tools/semantic_harness/ui/{lifecycle_controller.py,quality_sweep_controller.py}`, `ProjectHoomans/tools/providers/pnc/tests/{gui_test_support.py,test_semantic_harness_gui_journeys.py}`.
- **Mechanism:** `ConvoEngineAuthoringPane` created `service.convo_probe = ConvoProbe(...)` with only `atexit.register(self.close)` and neither `close_app()` nor `close_gui_app()` closed `authoring_service`, nor were sweep background threads tracked/joined. Adding `ConvoProbe.close()` `atexit.unregister`, `SemanticLabAuthoringService.close()`, `close_app()` service close + sweep thread cancel/join, and `gui_test_support.close_gui_app` cleanup brings leaked worker processes to `0`.

### 10. `Runtime.view` (`phraseSalt`) Leak Across Warm `import_source` & CodeBuilder / Startup Bottlenecks
- **Files:** `ProjectHoomans/tools/providers/pnc/lua/worker/ScenarioSession_Lifecycle.lua`, `psychopatzCore/tools/semantic_harness/codebuilder/{conversation_model.py,psdl_compiler.py,convo_engine_exchange.py,semantic_dialogue_ir.py,blocks.py,convo_engine_psdl_inventory.py,convo_engine_ownership_inventory.py,lexicon_compiler.py,dialogue_content.py,reconcile.py}`, `psychopatzCore/tools/semantic_harness/studio/{convo_engine_authoring_pane.py,block_registry.py}`, `psychopatzCore/tools/semantic_harness/ui/{shell.py,studio_surface_builder.py}`.
- **Mechanism:** `ScenarioSession.reset` left `Runtime.view` populated on `replaceProductionDurableState == true`, leaking `priorContext.phraseSalt` when scenarios omitted `phraseSalt`. In Python, `copy.deepcopy` on JSON ASTs (~3.6M calls per compile), `Path.relative_to()` (~15k calls), and eager Studio pane initialization (`ConvoEngineAuthoringPane.refresh()` spawning `ConvoProbe` + `SemanticBlockRegistryPane` compiling blocks before `_start_worker`) added ~35–40 s of overhead across GUI and compiler tests. Replacing JSON `deepcopy` with `copy_json`, string-prefix path slicing, clean-string `_lua_string` / exact-type `_lua_value`, deferring `ConvoEngineAuthoringPane` & `SemanticBlockRegistryPane` hydration until tab activation, and starting `app._start_worker()` ahead of Studio construction resolved these bottlenecks without altering behavior.
