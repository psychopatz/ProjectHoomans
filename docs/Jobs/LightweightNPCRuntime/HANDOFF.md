---
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "L4"
chunk: "Measured runtime cadence and allocation optimization"
retrieval_tier: "verify"
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
next_phase: "L5"
updated_at: "2026-11-19T21:44:00.329012Z"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "L4"
phase_commit_message: "phase(L4): eliminate duplicate zombie scans, add activity-sensitive census and aggro cadence, and deduplicate materialization wakes"
phase_commit_vector: "psychopatz-core=2fc8e5e8c237caa9507a93272896cf87b75e295a;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
---






# Session Handoff

## L4 Closed
- Eliminated every duplicate loaded-zombie scan outside `PNC_WorldCensus` across `PNC_Bandits_Targeting.lua`, `PNC_BodyLifecycle_Startup_{Batch,Sweep,Coordinator}.lua` (with empty-world maintenance skipping), and `PNC_LiveBodyControl_Events.lua`; added `BanditBodies`/`GetBandits`, 3-tier activity-sensitive cadence (`100ms` combat/urgent -> `250ms` calm live -> `1000ms` zero-live idle), and `MarkUrgent` urgent wakes, plus removed the O(Z) gauge walk in `PNC_SpatialIndex.lua` (`extraZScans: 102 -> 0`).
- Deduplicated `ActorOwnership.IsForeignOwned` and zombie activations per refresh in `PNC_ZombieAggro_ActiveSet.lua`, added empty-world fast-exit and per-entry cadence (`150ms` mid-range pursuit / `250ms` idle with instant wake for close range, active bites, native player targets/attackers, hit-settling, and `OnZombieProvoked`) in `PNC_ZombieAggro_Update_Loop.lua`, and guarded pursuit diagnostic string formatting behind `isPursuitAuditEnabled()`.
- Eliminated startup materialization thrashing and added follower priority (`forceLive` > active follower > closer bystander) in `PNC_Presence_Materialize.lua` and `PNC_Presence_Reconcile.lua` alongside clean scalar `Presence.Metrics` and `Spatial.RebuildCount` counters (`matAtt: 85 -> 46` bit-identical across `OFF`/`COARSE`/`DEEP`/`OFF_300`).
- Verified across `pnc_lightweight_runtime_cadence_smoke.lua`, `pnc_lightweight_runtime_simulation_smoke.lua` (including `Z_PRESS` and `IDLE_0`), `pnc_constants_presence_boundary_smoke.lua`, `tests/benchmarks/lightweight_npc_runtime.lua` (`N=100 OFF: 965.22ms`, `N=500 OFF: 994.00ms` vs L0 `4004.86ms` / L3 `2123.57ms`), 18 focused Lua suites (`221/221` pass), `luac -p`, and `pz_verify.py --kahlua --severity WARNING` (`0` errors/warnings, zero `next()` calls).

## Next Chunk
- **L5 — scale acceptance, docs and phase close:** Expand the headless scale benchmark matrix (N=100/500/1000/2000, L=1/6/12/24, Z=0/50/200, clients=1/4/16), run full regression sweeps in `psychopatzCore` and `ProjectHoomans` (explicitly recording pre-existing unrelated baseline failures), reconcile all architecture/system/job docs so no obsolete eager-hydration or duplicate-persistence guidance remains, and create final local Phase L5 checkpoint commits for user-owned native SP/MP acceptance.
