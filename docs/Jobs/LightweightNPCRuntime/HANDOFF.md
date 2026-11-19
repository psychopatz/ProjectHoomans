---
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "L0"
chunk: "Clean profiler-OFF baseline and profiler safety"
retrieval_tier: "verify"
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
next_phase: "L1"
updated_at: "2026-11-19T20:26:07.742859Z"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "L0"
phase_commit_message: "phase(L0): isolate coarse vs bounded deep profiler wrappers and establish headless runtime simulator baseline"
phase_commit_vector: "psychopatz-core=37ab6da2f6b5c4351cafa7adcd2a2fe771ff3a62;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
---


# Session Handoff

## L0 Closed
- Persisted `~/Zomboid/Lua/PsychopatzCore_Profiler.txt` deep capture is downgraded to `"coarse"` at bootstrap and never re-serialized as `"deep"`.
- Shared Core profiler supports `performance_depth = "coarse" | "deep"`, enforces clamped time-bounded deep windows (`5s..300s`, default `60s`), deterministically restores deep hooks on expiry and all wrappers on `Stop()` / `Bootstrap.Disable()`, and tags reports with explicit instrumentation scope.
- Hoomans profiler splits 10 coarse boundaries from 97 time-bounded deep wrappers (`0` wrappers in `OFF`).
- Deterministic integrated headless runtime simulator (`tests/support/lightweight_runtime_simulator.lua`) established clean `OFF` vs `COARSE` vs `DEEP` baselines and confirmed pre-L1 eager hydration/persistence bloat (`promoted=100/500`, `dirtyEnd=100/500`, `serAttempts=600/3000`, `fullSnap=216`).

## Next Chunk
- **L1 — lazy Core -> Hoomans promotion/demotion:** Remove startup/refresh bulk `HydrateCoreActors()`, add bounded lazy Core -> Hoomans promotion and reversible demotion backed by single sparse Core extension `ProjectHoomans.ActorExtension`, preserve canonical IDs across unique/starting companions/provider handoff, and extend the integrated simulator with L1 scale/demotion/mass-entry assertions.
