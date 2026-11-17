# Progress — Semantic Harness Speed & Runtime Optimization

**Status:** IN PROGRESS.
**Current phase:** P2.
**Next Chunk:** Execute `P2` — lazy pattern sorting in `PsychopatzSemanticRegistry.lua`, `package.loaded` registration in `ProductionModules.lua` / `test.lua`, eliminating double `importSource` on worker startup, and caching decoded translation shards in `PsychopatzCustomTranslationManager.lua`.

## Completed Phases

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
