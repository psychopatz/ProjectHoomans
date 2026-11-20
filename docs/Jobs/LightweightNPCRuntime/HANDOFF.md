---
state: "DIRTY_RESUMABLE"
parent_status: "IN_PROGRESS"
phase: "L6-live-follow-combat-abstract-travel-inventory-stutter"
chunk: "Four-family follow, combat, abstract-travel, and inventory reproduction baselines"
retrieval_tier: "verify"
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
next_phase: "L6_IMPLEMENTATION"
updated_at: "2026-11-20T00:36:30.661165Z"
checkpoint_mode: "dirty_snapshot"
phase_commit: "none"
phase_commit_phase: "L6-live-follow-combat-abstract-travel-inventory-stutter"
phase_commit_message: ""
phase_commit_vector: "psychopatz-core=7ba3976943b4324a3f875e1db1b9cd87f1d467e6;project-hoomans=fdcc073965e11682b411f41dc5a7e59f5a8d8c34"
phase_residual_vector: "psychopatz-core=a6031742d3180bfc2711a5c61724279957969a52d652e33dd610962efa2130b9;project-hoomans=ad1f7e7dda242d45bffbe007d357d52aeff50d62d54e541d41d508147caee0cc"
residual_worktree_fingerprint: "ad1f7e7dda242d45bffbe007d357d52aeff50d62d54e541d41d508147caee0cc"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
---

# Session Handoff

## L6 reopened from user-owned native acceptance: follow movement + combat impact + abstract travel handoff + inventory/ModData scale

Native testing after the accepted L0-L5 runtime work still shows severe visible stutter while the player walks with multiple live recruited companions **and** massive lag spikes when NPC attacks land against zombies, other NPCs, or players. L6 additionally verifies the compact mobile-group lifecycle so far-away travellers progress deterministically from Core journey time and only materialize near players without resetting/duplicating their route. This reopens developer work; the parent goal is no longer at USER_ACCEPTANCE.

### Verified gap

- The existing integrated simulator moves its fake player only on a one-second boundary and does not exercise sustained real `FollowOwner` work for a continuously moving owner.
- Focused follow tests cover isolated correctness but not the full moving owner -> formation -> move-intent -> PathService workload at 1/3/6/12 followers.
- The native audit observed a six-follower party and profiler peaks of six moving followers and six active paths. Captured logs showed progress timeout/stall/traversal symptoms, but those are candidate evidence rather than proof of a sole root cause.
- The latest profiler snapshot is `DETAILED`; L6 clean timing evidence must use profiler `OFF`.
- CODE_VERIFIED combat fan-out: successful NPC impacts dispatch through `CombatResolution.ApplyTargetDamage`. Zombie hits may fan out into reaction/aggro/network/social/semantic kill work; NPC hits may fan out into health/wounds/medical/faction/social/network/removal work; player hits may fan out into BodyDamage update, player-stat sync, faction handling, and live-witness social scans.
- Existing focused combat tests verify many correctness contracts, but the integrated lightweight simulator does not yet compare miss/control vs successful-hit impact cost across NPC -> zombie/NPC/player or synchronized multi-attacker contacts.
- CODE_VERIFIED abstract travel: `PNC_AbstractTraversal_Travel` delegates group journey authority to `PNC_CoreGroupTraversalBridge` and PsychopatzCore GroupJourney. Core progression is elapsed-world-time based and can cross route segments/waits in one large advance.
- CODE_VERIFIED handoff: Presence materializes from current projected positions; Travel `OnMaterialized` advances/syncs the same journey into the live lane and `OnAbstracted` captures live progress before returning the same journey to abstract control.
- Existing mobile-group/Core-journey/presence tests cover pieces, but the integrated runtime simulator does not yet prove the far-route -> projected player intercept -> materialize -> live travel -> abstract -> continue -> arrive lifecycle, time-leap equivalence, save/reload continuity, overlapping MP interest, or 1/10/50/100-group scale.
- CODE_VERIFIED inventory authority: NPC personal inventory is compact PsychopatzCore ActorInventory with SEED_ONLY, BASELINE_DELTA, and FULL payload modes. ProjectHoomans hydrates/captures richer inventory state through the actor bridge only when concrete gameplay needs it.
- Existing inventory bridge/persistence/replication/UI/transfer tests verify local contracts, but the integrated simulator does not yet measure 100/500/1000/2000 player-item scans, 10/50/100/500 NPC compact inventory scale, total/per-actor encoded bytes, transfer/mutation fan-out, subset hydration, or inventory-scale save/reload.

### Exact next responsibility

Implement the L6 reproduction baselines only:

1. extend tests/support/lightweight_runtime_simulator.lua with continuous step-wise player motion and production FollowOwner player methods;
2. run 1/3/6/12 follower open/turn-stop/obstacle/stall scenarios through real follow/formation/move-intent/PathService seams;
3. add NPC -> zombie/NPC/player miss-vs-hit combat controls, repeated hits, synchronized 1/3/6/12-attacker contacts, and kill/incapacitation transitions;
4. add canonical Core/mobile-group journey scenarios for far travel, time leap, player intercept/materialization, exit/abstraction, arrival, stall handoff, save/reload, and overlapping MP interest;
5. scale abstract travel to 1/10/50/100 groups and 1/3/6/12 members while distant groups remain compact/bodyless;
6. add large player-native inventory scenarios at 100/500/1000/2000 items;
7. add compact NPC inventory scale at 10/50/100/500 actors with representative 0/20/100/500 durable-item tiers;
8. exercise player -> many NPC and reverse transfers, mutation storms, subset materialization, inventory save/reload, and replication scale;
9. report inventory compact modes, total/per-actor encoded bytes, logical item counts, hydration/capture, persistence/network work, and same-frame high-water marks;
10. record profiler-OFF pre-fix operation/size baselines for all four workload families before changing follow/path, combat, abstract-travel, inventory compaction, persistence, or replication behavior.

Do not jump directly to pursuit-corridor caching, replan staggering, witness-scan changes, hit batching, travel polling changes, or request-budget tuning. All optimizations remain conditional on the measured baselines.

After the four isolated workload families have profiler-OFF baselines and evidence-backed fixes, L6 still requires the mandatory cross-system stress matrix before phase close: `COMBINED_SAVE_RELOAD_PRESSURE`, `COMBINED_MATERIALIZE_COMBAT`, `TRAVEL_MEMBER_DEATH_HANDOFF`, `TRAVEL_ARRIVAL_STORM`, `OBSERVATION_PROJECTION_LOAD`, `PLAYER_FAST_INTEREST_JUMP`, `PROVIDER_HANDOFF_TRAVEL`, `LONG_WORLD_ENDURANCE`, `COMBINED_INVENTORY_FOLLOW`, `COMBINED_INVENTORY_COMBAT`, `COMBINED_INVENTORY_MATERIALIZATION`, and `COMBINED_INVENTORY_SAVE_RELOAD`. Passing isolated workloads is not the L6 completion boundary.

### Dirty snapshot

This documentation pass owns only the following L6 job-document changes:

- `docs/Jobs/LightweightNPCRuntime/README.md`
- `docs/Jobs/LightweightNPCRuntime/ROADMAP.md`
- `docs/Jobs/LightweightNPCRuntime/ARCHITECTURE.md`
- `docs/Jobs/LightweightNPCRuntime/AGENT_RUNBOOK.md`
- `docs/Jobs/LightweightNPCRuntime/RUNTIME_SIMULATOR.md`
- `docs/Jobs/LightweightNPCRuntime/PROGRESS.md`
- new `docs/Jobs/LightweightNPCRuntime/FOLLOW_WALK_STUTTER.md`
- new `docs/Jobs/LightweightNPCRuntime/COMBAT_HIT_STUTTER.md`
- new `docs/Jobs/LightweightNPCRuntime/ABSTRACT_TRAVEL_HANDOFF_STUTTER.md`
- new docs/Jobs/LightweightNPCRuntime/INVENTORY_MODDATA_STRESS.md

Concurrent non-job-doc edits appeared during this documentation pass and were not modified/reverted here. Preserve and re-verify them before any staging/commit:

- Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Networking/ClientActions/PNC_ClientActions_Debug_Spawn.lua
- Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_Core.lua
- Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_Routing.lua
- Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Companions/PNC_DebugCompanionInitialization.lua
- Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua
- Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Registry/PNC_Registry/PNC_Registry_LoadDirty.lua
- Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ArchetypeDefinitions/Mechanic/PNC_Mechanic.lua
- docs/Systems/Persistence.md
- tests/pnc_actor_inventory_bridge_smoke.lua
- tests/pnc_client_debug_spawn_initialization_smoke.lua
- tests/pnc_lightweight_persistence_authority_smoke.lua
- tests/pnc_server_debug_command_handler_smoke.lua

Do not assume those concurrent edits belong to L6. Exact current Git/source and the owning agent/session must be reconciled before phase staging.

ProjectHoomans base HEAD is `fdcc073965e11682b411f41dc5a7e59f5a8d8c34`. PsychopatzCore is clean at `7ba3976943b4324a3f875e1db1b9cd87f1d467e6`. Preserve the dirty documentation; do not reset/stash/discard it.

Tooling ownership is clean: ProjectHoomans, psychopatzCore, and the Psychopatz bridge currently have zero root-owned paths. Continue executing remote repo/test/profiler commands as `psychopatz`.


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

## Core-backed recruitment closed

Project Hoomans adopts API-spawned NPCs into Core before registry insertion. Permanent recruitment publishes canonical affiliation and the personal ownership extension before installing follow. Starting companions use the same transaction on their first spawn. The Colonists roster consumes indexed community membership. Legacy records are processed by the bounded persistence pump and retired after the Core round trip and successful store save.

The headless suite covers failed and retried recruitment, multiple starters with authored and randomized identities, reconnect, dismissal and save reconstruction. The runtime matrix and NPC replication benchmark passed. Hoomans retains four documented unrelated baseline failures. Core retains the existing actor-discovery and generation parity failures in the focused set.

The tooling repair changed ownership on the 15 verified paths and preserved their modes. Both workspaces and the bridge were verified as UID 1000 with no root-owned files. The save's empty `mods.txt` is tracked independently in PROGRESS.

## Remaining User-Owned Scope

- **Native Project Zomboid SP/MP acceptance (not run automatically):**
  - Launch native SP & MP with profiler `OFF` (and optional bounded `COARSE` sanity check) across ordinary travel, combat, idle-away-from-NPCs, and populated regions.
  - Verify live FPS/frame-time feel under engine `IsoZombie` creation/rendering, Java pathfinder behavior, and chunk streaming/unloading around `L` active bodies vs large Core `N`.
  - Verify real MP server/client socket traffic, reconnect/detail inspection, and mixed-client compatibility if applicable.
  - Verify real SP/MP save/reload persistence endurance (companion states, injuries/equipment/jobs, sparse `ProjectHoomans.ActorExtension`, zero accumulated dirty backlog).
