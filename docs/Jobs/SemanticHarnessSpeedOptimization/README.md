# Semantic Harness Speed & Runtime Optimization

**Status:** IN PROGRESS (`P1`–`P4` DONE, `P5` ready to verify).

## Objective

Eliminate per-case 1-second+ latency in the Semantic Harness across both declarative semantic fixtures (`tools.semantic_harness.testing.cli`) and imperative Python tests (`tools/providers/pnc/tests` and `tools/semantic_harness/tests`) without changing `semantic.harness-test.v1` semantics or weakening test coverage, hermeticity, Kahlua/Lua 5.1 compatibility, or deterministic process ownership.

## Repository Scope

- **Primary (job owner):** `project-hoomans` (`/home/psychopatz/Zomboid/Workshop/ProjectHoomans`)
- **Participant:** `psychopatz-core` (`/home/psychopatz/Zomboid/Workshop/psychopatzCore`)
- **Read-only dependency:** `dynamic-trading` (`/home/psychopatz/Zomboid/Workshop/DynamicTrading`, commit `1fac47cdb1ff5ced7b2951634511859a0d276df3`)

## Baseline vs Target

| Surface | Measured Baseline | Acceptance Target | `P4` Observed |
| :--- | :--- | :--- | :--- |
| Declarative fixtures (39 files / 228 cases, serial) | `~337 s` (`~1,480 ms/case`) | `<= 25 s` (`<= 110 ms/case`) | `35.95 s` (`~158 ms/case`, `228/228 PASS`) |
| Declarative fixtures (`--jobs 4`) | Not supported (`> 337 s`) | `<= 10 s` | `14.93 s` (`228/228 PASS`) |
| Cold `LuaSemanticWorker` startup | `~1,125 ms` | `<= 400 ms` | `346.21–365.56 ms` (`P2`) |
| Warm scenario switch (`import_source`) | `~180 ms` (unused in fixtures) | `<= 35 ms` | `~10–42 ms` (`P1`–`P4`) |
| Single `worker.input()` turn | `~301 ms` | `<= 60 ms` | `56.94–84.74 ms` (`P1`) |
| PsychopatzCore unittest discovery (63 modules / 283 tests) | `~125–142 s` | `<= 60 s` | `49.256 s` (`283/283 PASS`) |
| PNC unittest discovery (171 modules / 700 tests) | `~1,005 s` (`> 900 s` serial bound) | `<= 300 s` (`0` leaked workers) | `294.330 s` serial / `146.141 s` (`--jobs 4`), `0` leaks |

## Phase Map

- `P1` (`DONE`) — Transport buffered I/O, pure-Lua `PsychopatzJson` fast-path, and redundant Python `deepcopy` removal.
- `P2` (`DONE`) — Lua worker startup deduplication (`package.loaded`), lazy pattern sorting, translation shard cache retention, and duplicate suggestion deduplication.
- `P3` (`DONE`) — Hermetic warm-worker state reset, warm worker reuse in declarative fixture execution, and `--jobs N` parallel sharding.
- `P4` (`DONE`) — CodeBuilder compilation caching, sweep/observatory/candidate batch worker reuse, XIM/ConvoProbe/thread cleanup, compact flushed runners, Studio lazy hydration, and heavy imperative suite acceleration.
- `P5` (`NEXT`) — Multi-repository final verification on clean `P4` commits, zero-leak worker audit, and job documentation closure.
