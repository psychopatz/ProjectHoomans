# Semantic Harness Speed & Runtime Optimization

**Status:** IN PROGRESS (`P1` ready to start).

## Objective

Eliminate per-case 1-second+ latency in the Semantic Harness across both declarative semantic fixtures (`tools.semantic_harness.testing.cli`) and imperative Python tests (`tools/providers/pnc/tests` and `tools/semantic_harness/tests`) without changing `semantic.harness-test.v1` semantics or weakening test coverage, hermeticity, Kahlua/Lua 5.1 compatibility, or deterministic process ownership.

## Repository Scope

- **Primary (job owner):** `project-hoomans` (`/home/psychopatz/Zomboid/Workshop/ProjectHoomans`)
- **Participant:** `psychopatz-core` (`/home/psychopatz/Zomboid/Workshop/psychopatzCore`)
- **Read-only dependency:** `dynamic-trading` (`/home/psychopatz/Zomboid/Workshop/DynamicTrading`, commit `1fac47cdb1ff5ced7b2951634511859a0d276df3`)

## Baseline vs Target

| Surface | Measured Baseline | Acceptance Target |
| :--- | :--- | :--- |
| Declarative fixtures (39 files / 228 cases, serial) | `~337 s` (`~1,480 ms/case`) | `<= 25 s` (`<= 110 ms/case`) |
| Declarative fixtures (`--jobs 4`) | Not supported (`> 337 s`) | `<= 10 s` |
| Cold `LuaSemanticWorker` startup | `~1,125 ms` | `<= 400 ms` |
| Warm scenario switch (`import_source`) | `~180 ms` (unused in fixtures) | `<= 35 ms` |
| Single `worker.input()` turn | `~301 ms` | `<= 60 ms` |
| PsychopatzCore unittest discovery (62 files / 277 tests) | `~125–142 s` | `<= 60 s` |
| PNC unittest discovery (171 files / 702 tests) | `~1,005 s` (`> 900 s` serial bound) | `<= 300 s` (`0` leaked workers) |

## Phase Map

- `P1` — Transport buffered I/O, pure-Lua `PsychopatzJson` fast-path, and redundant Python `deepcopy` removal.
- `P2` — Lua worker startup deduplication (`package.loaded`), lazy pattern sorting, translation shard cache retention, and duplicate suggestion deduplication.
- `P3` — Hermetic warm-worker state reset, warm worker reuse in declarative fixture execution, and `--jobs N` parallel sharding.
- `P4` — CodeBuilder compilation caching, sweep/observatory/candidate batch worker reuse, and heavy imperative test suite acceleration.
- `P5` — Multi-repository final verification, zero-leak worker audit, and job documentation closure.
