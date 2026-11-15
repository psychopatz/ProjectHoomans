---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "F3"
phase_commit_message: "phase(F3): phase(F3): Unify Lumber, Fishing, and CorpseHaul on shared work foundation"
updated_at: "2026-11-15T19:58:04.377141Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "F4"
chunk: "Phase F4"
retrieval_tier: "verify"
phase_commit_vector: "project-hoomans=self;psychopatz-core=e2a3deb56382c5895ddf60a9edfea48b2c23ccb1;dynamic-trading=4dcaa177bc59118e82e1681c57b742318de6fd62"
phase_residual_vector: "project-hoomans=c4b4b7535edc544638b9ec39c72f11c0572c04fb823cf65645f56bbfaafd13b9;psychopatz-core=8f81cddfa93f62381634923df5c6227f43359b963041a181e2e995f4f082e799;dynamic-trading=8a0fa0da519971def56422df4843fd38d6b93027dcf3a36926891007b461ebb9"
residual_worktree_fingerprint: "c4b4b7535edc544638b9ec39c72f11c0572c04fb823cf65645f56bbfaafd13b9"
codebase_memory_indexed_commit: "539bcb63d49148b5468f0bf611efb8c355f2ceea"
---



# Session Handoff — ModularWorkFoundationAndFarming

## What became true

- Refactored `LumberService` output capture/delivery and live approach watchdog onto `PNC.WorkOutputService` and `PNC.WorkToilRunner.ObserveLiveApproach`, with autonomous `NORMAL_WORK` zone orders alongside manual `FORCED_ORDER` jobs.
- Registered `FISHING` with `PNC.WorkService` via `PNC.FishingWorkAdapter` (+ `_OrderBridge.lua`), deferred legacy `PNC_FishingExecutor` registration in production, integrated `WorkToilRunner` + `WorkOutputService` into `PNC_FishingService_Work*.lua`, and wired `PNC_FishingWorkAdapter` into `PNC_ServerComposition.lua`.
- Integrated `WorkToilRunner.ObserveLiveApproach` into `PNC_CorpseHaulService_WorkAdapter_Tick.lua` during `SOURCE_APPROACH` and `DESTINATION_APPROACH`.
- Verified all 27 Lumber/Fishing/CorpseHaul/WorkOutput/WorkToil/Presence smoke tests (`PASS 27/27`).

## Remaining

- Phase F4 (rebuild zone-based `Farming` on `WorkService` + `WorkToilRunner` + `WorkInputService` + `WorkOutputService` with auto-plow and real `TickAbstract`).
- Phase F5 (UI/diagnostics, full regression battery, and live runtime/harness verification).

## Resume

Use Codebase Memory at `verify` tier for `project-hoomans`.

Exact next action:

1. Inspect `server/PNC/Farming/*.lua`, `PNC_FacilityJobs`, and `tests/pnc_farming_*.lua` / `tests/pnc_pz_farming_adapter_presence_boundary_smoke.lua`.
2. Remove the `affiliation.role == "farmer"` gate, add `CanPlowSquare`/`Plow`, add `CreateZone` zone-based farming + plot compatibility, register `FARMING` on `PNC.WorkService` (retiring `farm.work`), and route live & abstract farming through `WorkToilRunner`/`WorkInputService`/`WorkOutputService`.

## Evidence

- `TEST_VERIFIED`: `python3 tests/run_tests.py` across 27 Lumber, Fishing, CorpseHaul, WorkOutputService, WorkToilRunner, and WorkService presence-boundary smoke tests -> `PASS 27/27 in 0.28s`.
- `STATIC_VERIFIED`: `pz_verify.py --kahlua` across `PNC/Lumber`, `PNC/Fishing`, and `PNC_CorpseHaulService_WorkAdapter_Tick.lua` -> 0 Kahlua issues.

## Expensive discoveries worth preserving

- Isolated unit tests (`pnc_fishing_service_smoke`, `pnc_fishing_live_pipeline_smoke`) mock `PNC.Inventory` without loading `ColonyStorageRepository` or `PNC.WorkOutputService`; guarding `WorkOutputService` / `WorkToilRunner` calls in `Fishing` and `CorpseHaul` with availability checks preserves unit isolation while enabling unified pipeline behavior when loaded.
- `PNC_FishingService.lua` requires its submodules (`PNC_FishingService_WorkOutput`, `PNC_FishingService_Work`), while `PNC_FishingWorkAdapter.lua` loads `_OrderBridge` and is required from `PNC_ServerComposition.lua` before `PNC_FishingExecutor.lua`.

## Blockers / open decisions

- None. Unrelated dirty work in `docs/Jobs/*` and ConvoEngine/tools preserved untouched.

## Acceptance

Phase F4 delivers autonomous and assigned zone-based `FARMING` (auto-plow -> seed -> water -> harvest -> stockpile output + abstract execution) with passing farming smoke and presence-boundary tests.
