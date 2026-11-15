# Modular Work Foundation & Zone-Based Farming Progress

## Parent Goal Status
`IN_PROGRESS` (Phase F2 accepted; continuing to Phase F3)

## Current Phase
`Phase F3 — Unify Lumber, Fishing & CorpseHaul Onto Foundation`

## Accepted Items
- Full repository audit of `server/PNC/Production/`, `server/PNC/Tasking/`, `server/PNC/Farming/`, `server/PNC/Fishing/`, `server/PNC/Lumber/`, and `shared/PNC/Core/Production/`.
- Created canonical goal documentation in `docs/Jobs/ModularWorkFoundationAndFarming/` (`ARCHITECTURE.md`, `ROADMAP.md`, `PROGRESS.md`, `AGENT_RUNBOOK.md`, `HANDOFF.md`).
- **Phase F1 (`Chunk F1A`) Accepted (`TEST_VERIFIED`):**
  - Extended `PNC_WorkDefinitions_Constants.lua` with `FISHING` and `FARMING` operations, `JOB_BY_OPERATION`, `CAPABILITY_BY_OPERATION`, `MANUAL_PROGRESS`, `USES_FATIGUE_GATE`, `UsesFatigueGate(operation)`, `EXECUTION_POLICY`, and `LOCATION_POLICY_BY_OPERATION`.
  - Registered `FARMING` digging tool requirements (`Base.HandFork`, `Base.Trowel`, `Base.Shovel`, `Base.Shovel2`, `Base.SnowShovel`, `Base.GardenFork`, `Base.GardenHoe`) in `PNC_JobRequirements.lua`.
  - Replaced hardcoded `LUMBER`/`CORPSE_HAUL` fatigue gate checks in `PNC_WorkService_Core.lua` and `PNC_WorkTaskProvider_Context.lua` with `PNC.WorkDefinitions.UsesFatigueGate(operation)`.
  - Added `PNC.WorkItemService.CanAcquireFromStorage(record, operation)` and `PrepareForWorker(order, record)` so unassigned orders (`requiredWorkerId = nil`) pass `workerAvailable` when colony storage holds a valid tool candidate, automatically queue `WORK_ITEM_PICKUP` on assignment, wake to `WAITING_FOR_WORKER` upon pickup completion, and return tools on completion/cancellation.
- **Phase F2 Accepted (`TEST_VERIFIED`):**
  - Implemented modular `PNC.WorkOutputService` (`server/PNC/Production/PNC_WorkOutputService.lua` + `WorkOutputService/{CaptureGround,CaptureInventory,Deposit,Storage,LiveTick,Abstract}.lua`) supporting `EnsureOutputEffect`, `SetOutputEffectState`, `CaptureGroundOutput`, `CaptureInventoryOutput`, `TickLiveDelivery`, `FlushAbstractDelivery`, and `ReleaseOutputCapacity`.
  - Implemented `PNC.WorkToilRunner` (`server/PNC/Production/WorkService/PNC_WorkToilRunner.lua` + `WorkToilRunner/{Steps,Approach}.lua`) providing standardized `ENSURE_TOOLS -> COLLECT_INPUTS -> APPROACH_TARGET -> WORK_TARGET -> DELIVER_OUTPUTS` lifecycle orchestration, `SetOrderPhase`, `ObserveLiveApproach`, `PathService.GetMovementRecoveryState` stall/backoff coordination, and `WorkInputService` collection transitions.
  - Wired both modules in `server/PNC/Production/PNC_Production.lua` without disturbing `pnc_work_service_presence_boundary_smoke`.
  - Verified all new Lua modules pass `pz_verify.py --kahlua --tokens` with 0 errors/warnings and 0 bloated files.

## Current Evidence
- `TEST_VERIFIED`: `python3 tests/run_tests.py pnc_work_output_service_smoke pnc_work_toil_runner_smoke pnc_production_foundation_smoke pnc_production_lifecycle_smoke pnc_work_behavior_progress_smoke pnc_work_service_presence_boundary_smoke` -> `PASS 6/6`.
- `STATIC_VERIFIED`: `pz_verify.py --kahlua --tokens` across `WorkOutputService/`, `WorkToilRunner/`, `PNC_WorkOutputService.lua`, and `PNC_WorkToilRunner.lua` -> `kahlua:0 files  bloat:0 files`.

## Known Gap
- `Lumber`, `Fishing`, and `CorpseHaul` still carry duplicated output-delivery/travel-recovery loops and standalone `Tasking` provider registrations (`PNC_LumberExecutor`, `PNC_FishingExecutor`) rather than delegating to `PNC.WorkOutputService` and `PNC.WorkToilRunner` under `PNC.WorkService` (`NORMAL_WORK` vs `FORCED_ORDER`).

## Immediate Next Chunk
**Phase F3:** Migrate `LumberService` output delivery & travel watchdog onto `PNC.WorkOutputService` & `PNC.WorkToilRunner` (retiring `PNC_LumberExecutor` provider registration, enabling autonomous `NORMAL_WORK` alongside `FORCED_ORDER`), register `FISHING` in `PNC.WorkService` (routing catches via `WorkOutputService` and retiring `PNC_FishingExecutor`), and align `CorpseHaulService_WorkAdapter` with `WorkToilRunner`.

## Immediate Acceptance Criteria
1. `LumberService` delegates output capture/delivery and live approach recovery to `PNC.WorkOutputService` and `PNC.WorkToilRunner` while supporting both autonomous `NORMAL_WORK` and manual zone assignment (`FORCED_ORDER`).
2. `FISHING` registers in `PNC.WorkService` and delivers catches via `PNC.WorkOutputService` (`NPC_INVENTORY` live / ColonyStorage abstract), with standalone `PNC_FishingExecutor` / `PNC_LumberExecutor` Tasking provider registrations retired cleanly.
3. Focused Lumber, Fishing, CorpseHaul, and WorkService smoke tests pass (`TEST_VERIFIED`).
