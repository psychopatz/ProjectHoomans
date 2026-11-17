# Roadmap — Semantic Harness Speed & Runtime Optimization (`P1`–`P5`)

**Parent status:** IN PROGRESS.
**Active phase:** `P2`.
**Completion boundary:** `P1`–`P5` accepted and committed cleanly across participant (`psychopatzCore`) and primary (`ProjectHoomans`).

## Global Rules

- Continue automatically from `P1` through `P5`; commit participant (`psychopatzCore`) first and primary (`ProjectHoomans`) last at each accepted phase boundary using exact phase-owned paths.
- Never use `git add -A`, never revert/touch unrelated dirty work (including `docs/Jobs/SemanticTestSubsystem/*`), never create new Git branches, and never push unless explicitly authorized.
- Never hand-edit CodeBuilder generated artifacts.

---

## P1 — Buffered Transport, Pure-Lua JSON Fast-Path & Redundant Copy Removal (`DONE`)

**Goal:** Eliminate ~390 ms/case of 1-byte pipe `read()` syscalls, accelerate pure-Lua JSON encoding/decoding by 2x–4.6x, and trim redundant Python `deepcopy` overhead on fresh decoded payloads.

### Targets
- `psychopatzCore/tools/semantic_harness/transport/process.py`: Change `subprocess.Popen(..., bufsize=0)` to buffered I/O (`bufsize=-1`); verify `_write_request` always flushes `stdin` and close/reap behavior remains deterministic.
- `psychopatzCore/tools/semantic_harness/lua/PsychopatzCore/Serialization/PsychopatzJson.lua` and `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Serialization/PsychopatzJson.lua`:
  - Replace byte-by-byte `parseString` and `whitespace` scanning with `string.find` span scanning.
  - Replace `string.sub(text, position)` tail slicing in number parsing with anchored `string.match(text, pattern, position)`.
  - Fast-path clean strings in `escaped()` using `string.find(text, '[%z\1-\31"\\]')` and single-pass escaping while keeping strict Kahlua2 / Lua 5.1 compatibility.
- `psychopatzCore/tools/semantic_harness/core/state.py` and `ProjectHoomans/tools/providers/pnc/runtime/worker_conversation.py`: Remove redundant `deepcopy()` calls on freshly JSON-decoded transport response dicts (preserving immutability where callers actually mutate returned state).

### P1 Acceptance Gate
- JSON serialization/deserialization unit tests and transport lifecycle tests pass.
- `pz-verify` reports 0 errors on modified Lua files.
- Single `worker.input("follow me")` latency measured `<= 90 ms` (down from `~301 ms`).
- Local phase commits succeed (`psychopatzCore` first, then `ProjectHoomans`).

---

## P2 — Lua Worker Startup Deduplication, Lazy Registry Sort & Translation Shard Cache

**Goal:** Cut cold `LuaSemanticWorker` startup from `~1,125 ms` to `<= 400 ms` and remove redundant translation shard decoding and duplicate suggestion builds on every reset/turn.

### Targets
- `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticRegistry.lua`:
  - Replace `O(N^2 log N)` per-call sorting in `Registry.RegisterPattern` with O(1) duplicate lookup via `Registry.Patterns[pattern.id]` + `_patternsDirty = true`, running `table.sort` + `refreshOrderedPatterns()` lazily in `Registry.GetPatterns()`.
- `ProjectHoomans/tools/providers/pnc/lua/worker/ProductionModules.lua` (and/or `tests/support/test.lua`):
  - Register loaded relative module names in `package.loaded` when `Test.load` runs so subsequent `require(...)` calls do not re-execute 21 already-loaded modules (e.g. `PNC_SemanticCatalog.lua`).
- `ProjectHoomans/tools/providers/pnc/lua/worker.lua` & `psychopatzCore/tools/semantic_harness/core/worker.py`:
  - Eliminate redundant initial `importSource(initialScenario)` / double bootstrap reset when `LuaSemanticWorker.__init__` immediately supplies the target scenario.
- `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua` and `ProjectHoomans/tools/providers/pnc/lua/worker/Translations.lua`:
  - Skip `invalidateLoadedCatalogs()` in `setLanguageOverride(language)` when the normalized language has not changed (resetting only lookup diagnostics).
  - Cache decoded immutable translation shard tables in memory by `(modID, systemName, language)` so `"EN" <-> "TL"` toggles do not re-read/decode disk JSON files.
- `ProjectHoomans/tools/providers/pnc/lua/worker/Conversation_Turn.lua`, `Conversation_View_Finalize.lua`, `OutputProjection_ObservationSuggestions.lua`:
  - Avoid building `DialogueSuggestions.Build` / `RefreshRootSuggestions` twice for unchanged view/turn state.

### P2 Acceptance Gate
- Cold `LuaSemanticWorker` startup (`__init__`) measured `<= 400 ms` (down from `~1,125 ms`).
- All semantic registry, translation, conversation projection, and worker startup tests pass.
- `pz-verify` reports 0 errors on modified mod Lua files.
- Local phase commits succeed (`psychopatzCore` first, then `ProjectHoomans`).

---

## P3 — Hermetic State Reset & Warm-Worker Reuse + Parallelism for Declarative Fixtures

**Goal:** Eliminate per-case cold worker spawns across all 228 declarative semantic fixtures via hermetic `worker.import_source(scenario)` reuse and `--jobs N` parallel sharding.

### Targets
- Fix all 3 state-reset leaks across `import_source` / `reset`:
  1. `psychopatzCore/tools/semantic_harness/lua/worker/RuntimeState.lua`: Clear `runtime.playerConduct = nil` and `runtime.socialEvents = {}` in `RuntimeState.resetContainers(runtime)`.
  2. `ProjectHoomans/tools/providers/pnc/lua/worker/ScenarioSession_Lifecycle.lua`: Call `PNC.ConvoEngine.ResponseCatalog.ResetSelections()` during `ScenarioSession.reset`.
  3. `ProjectHoomans/tools/providers/pnc/lua/worker/SemanticAdapters_Core_Context.lua`: Preserve `semanticHubPresentation` only when `Runtime.replaceProductionDurableState == false` (`resetConversation`), clearing it when `replaceProductionDurableState == true` (`importSource` / `resetWorld`).
- `psychopatzCore/tools/semantic_harness/testing/executor.py`, `cli.py`, and `psychopatzCore/tools/semantic_harness/ui/regression_controller.py`:
  - Allow `execute_case()` to accept an optional warm `worker` and reset via `worker.import_source(case.scenario)`.
  - Update `execute_cases()` and `execute_cases_batch()` to reuse a warm worker across cases, recycling it immediately after any case executing catalog-mutating operations (`beat.register`, `behavior.register`, `flow.register`, `flow.generate`) or encountering an error, and closing deterministically in `finally`.
  - Add `--jobs <N>` parallel worker sharding to `tools.semantic_harness.testing.cli` while preserving deterministic result order and summary reporting.
- Add hermetic warm-worker reuse unit tests verifying repeated `import_source` cycles match cold-worker results across conduct, anti-repeat variants, and hub suppression cases.

### P3 Acceptance Gate
- Full 39-file / 228-case declarative fixture suite passes (`228/228 PASS`, `0` failures) in:
  - serial warm-worker mode in `<= 25 s` (`<= 110 ms/case`);
  - `--jobs 4` mode in `<= 10 s`.
- `0` leftover Lua worker processes after completion.
- Local phase commits succeed (`psychopatzCore` first, then `ProjectHoomans`).

---

## P4 — CodeBuilder Compilation Cache, Batch Reuse & Heavy Imperative Suite Acceleration

**Goal:** Remove repeated canonical source recompilations and per-item worker churn in CodeBuilder, Observatory, Sweep Executor, and slow imperative test modules.

### Targets
- `psychopatzCore/tools/semantic_harness/codebuilder/conversation_compiler.py` & `service.py`:
  - Add a thread-safe mtime/fingerprint-keyed in-process cache for read-only `compile_conversation_sources` calls (with clean invalidation whenever underlying source roots or file mtimes change) so repeated CLI/service/test queries do not re-parse 500+ JSON files (`test_dataset_compiler_and_workflow.py` `30.65 s -> <= 6 s`).
- `psychopatzCore/tools/semantic_harness/testing/sweep_batch.py`, `sweep_service.py`, `inspection/response_observatory.py`, `inspection/response_candidate.py`:
  - Reuse a warm worker across cases/variants inside `SweepBatchExecutor`, `DialogueQualitySweepService`, `run_quality_matrix`, and `preview_authored_variant` instead of spawning 1–5 workers per item/metadata query.
- Heavy imperative test suites in `psychopatzCore/tools/semantic_harness/tests/` and `ProjectHoomans/tools/providers/pnc/tests/`:
  - Provide a clean, deterministic warm-worker reuse helper (with explicit process teardown at class/module/process exit) and adopt it in the slowest multi-case imperative loops (e.g., `test_contextual_social_reactions.py`, `test_response_observatory_matrix.py`, `test_sweep_acceptance.py`, `test_contextual_talk_parity.py`, `test_harness.py`) without altering any test assertions or weakening mechanism coverage of lifecycle/process-restart tests.

### P4 Acceptance Gate
- Core full unittest discovery (`277` tests) passes in `<= 60 s`.
- PNC full unittest discovery (`702` tests) passes in `<= 300 s` (and faster with `run_tests.py --jobs 4`) with `0` leaked Lua workers and `0` Tkinter cleanup errors.
- Local phase commits succeed (`psychopatzCore` first, then `ProjectHoomans`).

---

## P5 — Final Multi-Repo Verification & Evidence Closure

**Goal:** Prove full-estate correctness, speed targets, and clean resource ownership across all repositories and close `SemanticHarnessSpeedOptimization`.

### Targets
- Re-run all verification gates on clean phase commits:
  1. Declarative fixtures (`228/228 PASS`) serial and `--jobs 4`.
  2. Full Core unittest discovery (`277/277 PASS`).
  3. Full PNC unittest discovery (`702/702 PASS`).
  4. `pz-verify` on all modified mod Lua files.
  5. Pre/post Lua worker process count check (`0` new stray processes).
- Reconcile `README.md`, `AUDIT.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `PROGRESS.md`, and `HANDOFF.md` with exact observed runtimes, per-item latencies, and committed dependency vector (`state: "COMPLETE"`, `parent_status: "COMPLETE"`).

## Non-Goals

- No change to `semantic.harness-test.v1` fixture DSL or test semantics.
- No disabling, skipping, or weakening of existing imperative or declarative tests.
- No touching `docs/Jobs/SemanticTestSubsystem/*` or unrelated dirty files.
- No pushes, PRs, tags, rebases, or new Git branches.
