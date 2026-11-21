---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "U3"
phase_commit_message: "phase(U3): unify Sims band-gated autonomy, co-presence situations, and Colonists debug diagnostics"
phase_commit_vector: "psychopatz-core=010a6260cabe39f210095ba3d1bfb710d35b98cf;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
updated_at: "2026-11-21T20:34:17.195132Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "Phase U4"
chunk: "U4A"
retrieval_tier: "verify"
---



# Session Handoff: UnifiedSchemaDrivenNPCAI

## What became true

- Phase U3 (`ProjectHoomans`) implemented and verified:
  - Created `server/PNC/Tasking/Autonomy/{PNC_AutonomyScorer,PNC_CoPresenceService,PNC_AutonomyTaskProvider}.lua` driven by compiled `PNC.AutonomyAd.Registry` (`PNC_SharedComposition_Final.lua`, `PNC_TaskProviders.lua`) with piecewise curves, trait/mood/distance weights, hysteresis (`enter`/`exit`), cooldowns, `<= 64` evaluation cap, zero-alloc Debug-OFF scoring, bounded (`<= 16`) `SpatialIndex.QueryNPCs`/distance-first `CoPresenceService` routing into `SceneAdopters.SubmitSocial`, and `PNC.Tasking.Claims` ownership.
  - Refactored `PNC_AmbientFacilityService` (`IsEligible`, read-only `PreviewSeat`, `AcquireSeat`, `StartSeat`, `StopSeat`), removed `PNC_LivingRoomService` dead `Registry.ForEach` polling loop, guarded `PNC_Server_SubsystemPumps` ambient pump when `autonomy` provider is registered, exposed `PNC_RoamingSeatService` helpers, updated `PNC_RoamAmbientTick` & `PNC_BehaviorSystem_Tick_Ownership` for `taskLeaseId` cleanup/anti-double-tick, exempted `Const.ORDER_ROAM` in `PNC_Tasking_Evaluation.H.ExternalCurrent`, routed behavior callers through `AMBIENT_OPPORTUNITY`, and wired `HydrateOnPromotion` in `PNC_Persistence_CoreProvider`.
  - Extended `PNC_Tasking_Queries.BuildBrain`, `PNC_ColonistWindow`, and `PNC_ColonistDebugRows` to expose `activeBand`, `claims`, `leaseClaims`, `autonomyDiagnostics`, and Co-Presence status on `"debug"` tab with zero Debug-OFF overhead.
- Phase U2 (`psychopatzCore` @ `010a6260cabe39f210095ba3d1bfb710d35b98cf` + `ProjectHoomans` @ `13ca3255df7dab59202ba2322920239a83f3f7d0`) and Phase U1 (`a598e8b9c1e2fe86b505e543b73cd63f52dfd2a5`) committed and checkpoint-verified.

## Remaining

- Execute Phase U4 (`GTA V / RDR2 Behavioral Reactivity & Secondary Channel`) across `psychopatzCore` (`PsychopatzShockingEventBus`) first and `ProjectHoomans` second.
- Execute Phase U5 (`S13D–S13F Gate + Dialogue Director & RDR2 Street Interaction`) and Phase U6 (`Scale Proof & Final Acceptance`).

## Resume

Exact next action:

1. Inspect `psychopatzCore` (`Kernel/PC_CapabilityCatalog.lua`, `Composition/PC_SharedComposition.lua`, existing event bus patterns) and `ProjectHoomans` (`Perception/`, `Awareness/`, `PNC_SocialEventHooks_CombatAdapter_Awareness.lua`, `AnimSets/`, `PNC_NPCVoiceCatalog.lua`) to freeze the exact Phase U4 design plan.
2. Implement `PsychopatzShockingEventBus` in `psychopatzCore` first (omitted from `DynamicTrading` packs), then `PerceptionService` + `ClueMemory` + `ReactionPolicy` providers + `AgitationService` + scenarios + Secondary Channel in `ProjectHoomans`.

## Evidence

- `TEST_VERIFIED` (U3): `u3_autonomy` (1/1), `follow_need_preemption` (1/1), `mp_server_file_guard` (1/1, 1063 files), `seating` (1/1), `roam_ambient` (1/1), `roaming_floor_seat` (1/1), `colonist_ui` (1/1), `colonist_activities` (1/1), `colonist_task` (1/1), `tasking` (8/8), `composition_bootstrap` (1/1), `seated_threat` (1/1), `player_roam` (1/1) — 20/20 PASS.
- `TEST_VERIFIED` (U2): `psychopatzCore` `python3 -m unittest` 30/30 OK; Core Lua social tests 5/5 PASS; `reconcile.py --check` clean; `convo_engine_naming_audit.py --summary` (`ok=true, activeCurrentPsdlIdentityCount=0`); `DynamicTrading` 92/92 PASS; `PASS generated_ai_ir_registries_lua_load`.
- `TEST_VERIFIED` (U1): `u1_work_foundation` + focused work/farming/lumber/fishing/corpse/tasking suites — 81/81 PASS.
- `STATIC_ONLY`: `pz-verify --kahlua --severity ERROR` 0 errors on all 24 U3 production Lua files, all U1 files, `PsychopatzSocial*.lua`, and all 6 U2 generated `ProjectHoomans` Lua files.

## Expensive discoveries worth preserving

- `PNC_TaskIntent.Normalize` creates a clean normalized table keeping only core intent fields (`taskId`, `npcId`, `kind`, `sourceDomain`, `sourceRef`, `precedence`, `capability`, `urgency`, `workPriority`, `interruptPolicy`, `revision`, `createdAt`) — custom keys on candidate tables are stripped before `Assign`.
- `PNC_Tasking_Evaluation.H.ExternalCurrent` previously treated `orderSpec.kind == "roam"` as `FORCED_ORDER` (preventing `OPTIONAL`/`IDLE` autonomy from running for roamers); exempting `Const.ORDER_ROAM` alongside `colony_home`, `follow`, `camp`, and `guard` fixes Tasking arbitration cleanly.
- `tests/pnc_composition_bootstrap_smoke.lua` asserts `sharedCalls[#sharedCalls] == "PNC/Semantics/PNC_CoreSemanticPack"`, so shared composition additions in `PNC_SharedComposition_Final.lua` must be inserted before `PNC_CoreSemanticPack`.
- `tests/pnc_mp_server_file_guard_smoke.lua` now enforces `1063` server `.lua` files (`+3` for `Autonomy/*`).
- `AmbientFacilityService` `AcquireActivity` / `CampResourceService.AcquireSeat` allocate live `FacilityReservations` immediately; autonomy candidate generation must stay read-only (`PreviewSeat`) and acquire seats only inside `Assign`.

## Blockers / open decisions

- None for U4 (`ConvoEngine` S13D–S13F gate applies immediately before U5).

## Acceptance

- Phase U3 local commit + `checkpoint.py verify` green, then enter Phase U4 planning.
