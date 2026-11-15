# Modular Work Foundation & Zone-Based Farming Progress

## Parent Goal Status
`IN_PROGRESS` (Phase F1 accepted; continuing to Phase F2)

## Current Phase
`Phase F2 — Shared PNC.WorkOutputService & PNC.WorkToilRunner Primitives`

## Accepted Items
- Full repository audit of `server/PNC/Production/`, `server/PNC/Tasking/`, `server/PNC/Farming/`, `server/PNC/Fishing/`, `server/PNC/Lumber/`, and `shared/PNC/Core/Production/`.
- Created canonical goal documentation in `docs/Jobs/ModularWorkFoundationAndFarming/` (`ARCHITECTURE.md`, `ROADMAP.md`, `PROGRESS.md`, `AGENT_RUNBOOK.md`, `HANDOFF.md`).
- **Phase F1 (`Chunk F1A`) Accepted (`TEST_VERIFIED`):**
  - Extended `PNC_WorkDefinitions_Constants.lua` with `FISHING` and `FARMING` operations, `JOB_BY_OPERATION`, `CAPABILITY_BY_OPERATION`, `MANUAL_PROGRESS`, `USES_FATIGUE_GATE`, `UsesFatigueGate(operation)`, `EXECUTION_POLICY`, and `LOCATION_POLICY_BY_OPERATION`.
  - Registered `FARMING` digging tool requirements (`Base.HandFork`, `Base.Trowel`, `Base.Shovel`, `Base.Shovel2`, `Base.SnowShovel`, `Base.GardenFork`, `Base.GardenHoe`) in `PNC_JobRequirements.lua`.
  - Replaced hardcoded `LUMBER`/`CORPSE_HAUL` fatigue gate checks in `PNC_WorkService_Core.lua` and `PNC_WorkTaskProvider_Context.lua` with `PNC.WorkDefinitions.UsesFatigueGate(operation)`.
  - Added `PNC.WorkItemService.CanAcquireFromStorage(record, operation)` and `PrepareForWorker(order, record)` so unassigned orders (`requiredWorkerId = nil`) pass `workerAvailable` when colony storage holds a valid tool candidate, automatically queue `WORK_ITEM_PICKUP` on assignment, wake to `WAITING_FOR_WORKER` upon pickup completion, and return tools on completion/cancellation.

## Current Evidence
- `TEST_VERIFIED`: `python3 tests/run_tests.py pnc_job_requirements_smoke pnc_work_item_service_smoke pnc_work_item_logistics_smoke pnc_work_policy_smoke pnc_work_service_presence_boundary_smoke pnc_work_fatigue_gate_smoke` -> `PASS 6/6`.

## Known Gap
- Stockpile output hauling and live target approach/recovery are still duplicated inside `LumberService` (`PNC_LumberService_Execution_OutputDelivery_*.lua`) and ad-hoc chore executors; `PNC.WorkOutputService` and `PNC.WorkToilRunner` do not exist yet.

## Immediate Next Chunk
**Phase F2:** Create `server/PNC/Production/PNC_WorkOutputService.lua` and `server/PNC/Production/WorkService/PNC_WorkToilRunner.lua`, wire them into `PNC_ServerComposition.lua` / `PNC_WorkService.lua`, and verify both with dedicated smoke tests (`tests/pnc_work_output_service_smoke.lua` and `tests/pnc_work_toil_runner_smoke.lua`).

## Immediate Acceptance Criteria
1. `PNC.WorkOutputService` supports both ground-item capture and direct NPC-inventory output reservation, travel to `StockpileAccessService.FindNearest`, deposit into `ColonyStorageRepository`, and abstract output flush.
2. `PNC.WorkToilRunner` provides unified live target approach, arrival envelope checking, `PathService.GetMovementRecoveryState` stall/backoff observation, and standardized `WorkInputService` stockpile collection transitions.
3. Dedicated Phase F2 smoke tests and `pnc_production_foundation_smoke`, `pnc_production_lifecycle_smoke`, `pnc_work_behavior_progress_smoke` pass (`TEST_VERIFIED`).
