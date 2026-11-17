---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
workspace_scope: "multi"
workspace_primary: "project-hoomans"
workspace_repositories: "project-hoomans;psychopatz-core;dynamic-trading"
codebase_memory_indexed_commit: "24965c9c6cef4f9b0dbadc949c9db7867a94f2a9"
updated_at: "2026-11-17T15:06:06.639015Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P3"
chunk: "P3 hermetic state reset, warm-worker reuse, and --jobs N parallelism for declarative fixtures"
retrieval_tier: "verify"
phase_commit: "self"
phase_commit_phase: "P2"
phase_commit_message: "phase(P2): semantic_harness(P2): deduplicate ProductionModules require and skip redundant startup import/hello"
phase_commit_vector: "project-hoomans=self;psychopatz-core=fe8093833c74441e69ffceca262e2595a3a50202;dynamic-trading=1fac47cdb1ff5ced7b2951634511859a0d276df3"
phase_residual_vector: "project-hoomans=791e2a8abd94c5481933eec993f5d9a48076e39fe99be33e0575d34ffcfe5920;psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "791e2a8abd94c5481933eec993f5d9a48076e39fe99be33e0575d34ffcfe5920"
---



# Session Handoff

## What became true

- Completed full timing/root-cause audit across declarative semantic fixtures (39 files / 228 cases, `~337 s` / `~1,480 ms/case`) and imperative suites (`psychopatzCore` 62 files / 277 tests in `142.28 s`; `ProjectHoomans` 171 files / 702 tests in `~1,005 s @ --jobs 4`).
- Created full job docs (`README.md`, `AUDIT.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `PROGRESS.md`, `AGENT_RUNBOOK.md`, `HANDOFF.md`) defining Phases `P1`–`P5`.

## Remaining

- Execute `P1` through `P5` and close the multi-repo job cleanly.

## Resume

Use Codebase Memory at tier `verify` for `psychopatz-core` and `project-hoomans`. Read `PROGRESS.md`, `AUDIT.md`, and `ROADMAP.md` (`P1`).

Exact next action (`P1`):

1. Switch `subprocess.Popen(..., bufsize=0)` -> `bufsize=-1` in `psychopatzCore/tools/semantic_harness/transport/process.py` (verifying `stdin.flush()` and close/reap safety).
2. Optimize `PsychopatzJson.lua` (both `tools/semantic_harness/lua/PsychopatzCore/Serialization/PsychopatzJson.lua` and `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Serialization/PsychopatzJson.lua`) with `string.find` span scanning, anchored `string.match(..., position)`, and fast-path single-pass string escaping while preserving Kahlua/Lua 5.1 compatibility.
3. Trim redundant `deepcopy` calls on freshly JSON-decoded transport dicts in `ProjectHoomans/tools/providers/pnc/runtime/worker_conversation.py` and `psychopatzCore/tools/semantic_harness/core/state.py`.
4. Run P1 gate checks (JSON/transport tests, `pz-verify` on modified mod Lua, `w.input("follow me")` latency `<= 90 ms`), commit `psychopatzCore` first and `ProjectHoomans` last via `agent-phase`, then continue immediately into `P2`–`P5`.

## Evidence

- `RUNTIME_VERIFIED` / `CODE_VERIFIED`: Audit measurements recorded in `AUDIT.md`.
- `UNVERIFIED`: No optimization code changes implemented yet (`P1` pending).

## Expensive discoveries worth preserving

- Changing `bufsize=0` to `bufsize=-1` alone dropped `readline(200 KB)` from `194.8 ms -> <1 ms` and `w.input("follow me")` from `301.1 ms -> 77.1 ms`.
- Reusing a warm worker across all 228 fixtures exposed only 3 state-reset leaks (`Runtime.playerConduct`/`socialEvents`, `ResponseCatalog.ResetSelections()`, and `semanticHubPresentation` when `replaceProductionDurableState == true`), slated for `P3`.
- Unrelated dirty work exists in `docs/Jobs/SemanticTestSubsystem/*`; preserve it completely untouched.

## Blockers / open decisions

- None.

## Acceptance

- Phase `P1`: JSON + transport tests pass, `pz-verify` clean, single `worker.input("follow me")` `<= 90 ms`, participant + primary phase commits succeed.
