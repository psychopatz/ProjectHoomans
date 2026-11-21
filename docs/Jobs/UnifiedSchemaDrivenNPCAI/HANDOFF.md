---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "U0"
phase_commit_message: "phase(U0): complete Stage 0 live audit, prerequisite matrix, and manifest freeze"
phase_commit_vector: "psychopatz-core=e7149129f10da87c28b56d6359aac3ff461eba09;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
updated_at: "2026-11-21T20:02:43.628064Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "Phase U1"
chunk: "U1A"
retrieval_tier: "verify"
---


# Session Handoff: UnifiedSchemaDrivenNPCAI

## What became true

- Phase U0 live codebase discovery completed across `ProjectHoomans`, `psychopatzCore`, `DynamicTrading`, and `pz-java-baseline`.
- Prerequisite readiness verified: `LightweightNPCRuntime` (L0–L6), `Portable Social State` (P0–P12/H0–H8/DT0–DT6), `PortableActorLifecycleGC` (L0–L9), and `ModularWorkFoundationAndFarming` (F1–F5) are developer-complete; `ConvoEngine` S13D–S13F (`psychopatzCore`) is gated as U5a before Phase U5 Dialogue Director work.
- Build 42 Java constraints (`setVariable` MP server no-op on `IsoZombie`, `faceLocationF` zero-delta log guard, `CanSee` FOV absence, `WorldSoundManager` server `chunk.soundList` gap) and `KnoxVox` absence verified and captured in `ARCHITECTURE.md`.
- Frozen cross-repo Phase U1–U6 ownership manifest and exact verification commands recorded in `ROADMAP.md` and `AGENT_RUNBOOK.md`.

## Remaining

- Execute Phase U1 (RimWorld Work Foundation Unification) in `ProjectHoomans`: `PNC.Tasking.Claims`, lease/rollback claim cleanup, `WorkToilRunner.AbortOrder`, 4-chore `WorkService.RegisterReconciler` unification, and removal of standalone chore polling loops.

## Resume

Exact next action:

1. Create `PNC_Tasking_Claims.lua` and integrate `ReleaseByLease`/rollback/reconciliation into `PNC_Tasking`, `PNC_TaskLeaseService_Release`, `PNC_Tasking_Assignment`, and `PNC_Tasking_Pump_Reconciliation`.
2. Add `WorkToilRunner.AbortOrder`, bridge Work/WorkZone/Lumber/CorpseHaul claims, and unify `FARMING`/`FISHING`/`LUMBER`/`CORPSE_HAUL` reconcilers onto `WorkService.RegisterReconciler`.
3. Run `u1_work_foundation`, `mp_server_file_guard`, `work`, `farming`, `lumber`, `fishing`, `corpse`, and `tasking` Lua suites plus `pz-verify` Kahlua check.

## Evidence

- `CODE_VERIFIED`: Git branches/HEADs (`ProjectHoomans` `main` @ `cbf62c1aedbb57cf486503ae707c8ca6a457e2a6`, `psychopatzCore` `main` @ `e7149129f10da87c28b56d6359aac3ff461eba09`, `DynamicTrading` `main` @ `2b66a9583fcbe3d9e915b6c16ab9d6851d053eab`), zero production edits in U0.
- `CODE_VERIFIED`: Live module/symbol audits across `PNC.Tasking`, `WorkService`, `CodeBuilder`, `PsychopatzSocial`, `DTCommon`/`DTAbstract`, and `pz-java-baseline`.

## Expensive discoveries worth preserving

- `PNC_WorkZoneService_Claims.lua` adds `ttlSeconds` directly to `Internal.now()` (`expiresAt = at + ttl`), which tests stub in seconds (`clock = 100`); bridging to `PNC.Tasking.Claims` must pass explicit `at`/`expiresAt` in the caller's unit or use matching units.
- `tests/pnc_mp_server_file_guard_smoke.lua` enforces exact server `.lua` count (`1059`); adding `PNC_Tasking_Claims.lua` requires reviewing its `AllowsServerCode()` guard and updating the count to `1060`.
- `reconcile.py:90` expects `"do not edit by hand."` (lowercase) while `social_policy_compiler.py:25` emits `"... DO NOT EDIT."`; fix during U2.

## Blockers / open decisions

- None for U1–U4. (`ConvoEngine` S13D–S13F is sequenced cleanly as gate U5a before Phase U5.)

## Acceptance

- Phase U0 checkpoint verified cleanly via `checkpoint.py verify`, then proceed immediately to Phase U1 execution.
