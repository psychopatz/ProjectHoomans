---
state: "USER_ACCEPTANCE"
parent_status: "DEVELOPER_COMPLETE"
phase: "L5"
chunk: "Scale acceptance, docs and phase close"
retrieval_tier: "verify"
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
next_phase: "USER_NATIVE_ACCEPTANCE"
updated_at: "2026-11-19T21:55:42.969577Z"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "L5"
phase_commit_message: "phase(L5): add L5 scale acceptance matrix, reconcile architecture and system docs, and close developer-side gates"
phase_commit_vector: "psychopatz-core=2fc8e5e8c237caa9507a93272896cf87b75e295a;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
---


# Session Handoff

## L5 Closed (Developer-Side L0–L5 Complete)

- **Headless scale benchmark matrix (`HEADLESS LUA SIMULATOR — NON-NATIVE`):** Upgraded `tests/support/lightweight_runtime_simulator.lua` and `tests/benchmarks/lightweight_npc_runtime.lua` (`ALL L5 BENCHMARK MATRIX ASSERTIONS PASSED`).
  - Core population scaling (`N=100, 500, 1000, 2000` with `L=6, Z=50, C=1, OFF`): bit-identical Hoomans operations across `N` (`PkPr=9, EnPr=9, PkLv=9, Com=4/Pmp=6/SerA=16, PrsD=93/CmbD=7/HWEq=4, Full=18, Census=75, ExtraZ=0, ZAggr=3244, DirtyEnd=0, GSave=1`); 20s profiler-OFF control `N=500` improved `4004.86ms` (L0) -> `971.07ms` (`-75.8%`), and `N=100` improved `2001.45ms` -> `1126.22ms` (`-43.7%`).
  - Active set scaling (`L=1, 6, 12, 24`, capped at `20` live bodies with `MaxProm<=4` and `MaxMat<=2`), zombie pressure (`Z=0, 50, 200` + `IDLE0_Z200` at `39.23ms` / `Avg 0.16ms` with `ZAggr=0, ExtraZ=0`), client fan-out (`C=1, 4, 16` + `C=4` mixed-capability repair converging with `SafePhaseFailures=0`), departure demotion (`DEPART_DEM: PkPr=9 -> EnPr=0, CoreN=500`), knowledge mutation storm (`MUT_STORM: Com=33 -> Pmp=4, SerA=13, GSave=1, DirtyEnd=0`), and `OFF`/`COARSE`/`DEEP` (`deep_instrumented_diagnostic_only`) profiler restoration verified.
- **Documentation reconciled:** Updated `docs/01_SYSTEM_MAP.md`, `docs/Systems/Persistence.md`, `docs/Systems/Networking.md`, `docs/Systems/Performance.md`, `docs/Systems/Presence.md`, `docs/Jobs/LightweightNPCRuntime/ARCHITECTURE.md`, and `docs/Jobs/LightweightNPCRuntime/README.md` to match the L0–L5 runtime contracts.
- **Multi-repo regression verification:**
  - `ProjectHoomans`: `tests/benchmarks/lightweight_npc_runtime.lua` pass; `tests/pnc_lightweight_runtime_simulation_smoke.lua` 10/10 pass; `tests/benchmarks/npc_replication.lua` (P1–P4) pass; full `python3 tests/run_tests.py` sweep `1078/1082` pass (4 pre-existing unrelated baseline failures untouched: `pnc_animation_scene_debug_routes_smoke.lua`, `pnc_context_debug_smoke.lua`, `pnc_population_director_smoke.lua`, `pz_custom_translation_manager_smoke.lua`).
  - `psychopatzCore`: Python profiler suite `54/54` pass; relevant Lua smoke suite `65/69` pass (4 pre-existing unrelated headless baseline failures untouched: `psychopatz_profiler_client_composition_smoke.lua`, `psychopatz_profiler_server_composition_smoke.lua`, `psychopatz_survivor_world_client_knowledge_smoke.lua`, `psychopatz_survivor_world_generation_smoke.lua`).
- **Local commit checkpoints (`pushed=false`, branch `main`):**
  - `psychopatzCore`: L0 `37ab6da`, L1 `2fc8e5e` (clean at `2fc8e5e8c237caa9507a93272896cf87b75e295a`).
  - `ProjectHoomans`: L0 `1303f51`, L1 `9ca238a`, L2 `879c878`, L3 `c388168`, L4 `a1fa4ac`, L5 `self`.

## Remaining User-Owned Scope

- **Native Project Zomboid SP/MP acceptance (not run automatically):**
  - Launch native SP & MP with profiler `OFF` (and optional bounded `COARSE` sanity check) across ordinary travel, combat, idle-away-from-NPCs, and populated regions.
  - Verify live FPS/frame-time feel under engine `IsoZombie` creation/rendering, Java pathfinder behavior, and chunk streaming/unloading around `L` active bodies vs large Core `N`.
  - Verify real MP server/client socket traffic, reconnect/detail inspection, and mixed-client compatibility if applicable.
  - Verify real SP/MP save/reload persistence endurance (companion states, injuries/equipment/jobs, sparse `ProjectHoomans.ActorExtension`, zero accumulated dirty backlog).
