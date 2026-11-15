---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "F1"
phase_commit_message: "phase(F1): Declarative operation gates and unassigned order tool pickup"
updated_at: "2026-11-15T19:38:48.947878Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "F2"
chunk: "Phase F2"
retrieval_tier: "verify"
phase_commit_vector: "project-hoomans=self;psychopatz-core=e2a3deb56382c5895ddf60a9edfea48b2c23ccb1;dynamic-trading=4dcaa177bc59118e82e1681c57b742318de6fd62"
phase_residual_vector: "project-hoomans=cf413db54b4fd8a322026bc87c723e1aaf6cbd27175c5cd231673a1b1b23606f;psychopatz-core=6482f614997012392d1c8945a14e2c1b22d852eb282952e1caf14516a9e23b5d;dynamic-trading=966e2e178b133cb9e3b7a385f4875847d36cac48062e1698b5555dc0e827ff83"
residual_worktree_fingerprint: "cf413db54b4fd8a322026bc87c723e1aaf6cbd27175c5cd231673a1b1b23606f"
codebase_memory_indexed_commit: "539bcb63d49148b5468f0bf611efb8c355f2ceea"
---



# Session Handoff — ModularWorkFoundationAndFarming

## What became true

- Extended `PNC_WorkDefinitions_Constants.lua` with `FISHING` and `FARMING` operations, `JOB_BY_OPERATION`, `CAPABILITY_BY_OPERATION`, `MANUAL_PROGRESS`, `USES_FATIGUE_GATE`, `UsesFatigueGate(operation)`, `EXECUTION_POLICY`, and `LOCATION_POLICY_BY_OPERATION`.
- Registered `FARMING` digging tool requirements in `PNC_JobRequirements.lua`.
- Replaced hardcoded `LUMBER`/`CORPSE_HAUL` fatigue gate checks in `PNC_WorkService_Core.lua` and `PNC_WorkTaskProvider_Context.lua` with `PNC.WorkDefinitions.UsesFatigueGate(operation)`.
- Added `CanAcquireFromStorage` and `PrepareForWorker` so unassigned orders (`requiredWorkerId = nil`) pass `workerAvailable` when storage has a valid tool, queue `WORK_ITEM_PICKUP` on assignment, wake to `WAITING_FOR_WORKER` when collected, and queue `WORK_ITEM_RETURN` on completion.

## Remaining

- Phases F2 (`WorkOutputService` + `WorkToilRunner`), F3 (`Lumber`, `Fishing`, `CorpseHaul` unification), F4 (zone-based `Farming`), and F5 (UI/diagnostics, full suite, live harness acceptance).

## Resume

Use Codebase Memory at `verify` tier for `project-hoomans`.

Exact next action:

1. Inspect `PNC_LumberService_Execution_OutputDelivery_*.lua`, `PNC_ServerComposition.lua`, `PNC_PathService`, and `PNC_StockpileAccessService`, then implement `PNC.WorkOutputService` and `PNC.WorkToilRunner` with dedicated smoke tests.
2. Run Phase F2 smoke tests (`pnc_work_output_service_smoke`, `pnc_work_toil_runner_smoke`, `pnc_production_foundation_smoke`, `pnc_production_lifecycle_smoke`, `pnc_work_behavior_progress_smoke`).

## Evidence

- `TEST_VERIFIED`: `python3 tests/run_tests.py pnc_job_requirements_smoke pnc_work_item_service_smoke pnc_work_item_logistics_smoke pnc_work_policy_smoke pnc_work_service_presence_boundary_smoke pnc_work_fatigue_gate_smoke` -> `PASS 6/6`.

## Expensive discoveries worth preserving

- `PNC_ColonyUIShared.lua:262` ignores job requirement diagnostics unless `role == "primary_tool"`, so `FARMING` tool requirements must use `role = "primary_tool"` with `equipSlot = "primary"`.
- Holding `ClaimsByWorker[worker.id]` on the main order before `WORK_ITEM_PICKUP` causes a worker-claim deadlock (`WORKER_ALREADY_CLAIMED`); Pin-and-Prepare binds `autoAssignedWorker` + `requiredWorkerId` and defers claiming the main order until `WORK_ITEM_PICKUP` completes.

## Blockers / open decisions

- None. Unrelated dirty work in `docs/Jobs/*` (`UnifiedSemanticDialogueAuthority`, `PragmaticDialogueBeatDirector`, `SemanticSocialConversationDirector`) preserved untouched.

## Acceptance

Phase F2 delivers `PNC.WorkOutputService` and `PNC.WorkToilRunner`, wired into server composition, with all Phase F2 smoke tests passing.
