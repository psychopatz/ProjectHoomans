# Modular Work Foundation & Zone-Based Farming Progress

## Parent Goal Status
`IN_PROGRESS` (Phase F3 accepted; continuing to Phase F4)

## Current Phase
`Phase F4 — Rebuild Farming as a Zone-Based Chore on Unified Foundation`

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

- **Phase F3 Accepted (`TEST_VERIFIED`):**
  - Refactored `LumberService` output capture/delivery (`OutputCapture`, `OutputDelivery_Pickup`, `OutputDelivery_Deposit`) and live tree approach watchdog (`TreeWork`) onto `PNC.WorkOutputService` and `PNC.WorkToilRunner.ObserveLiveApproach`, adding autonomous `NORMAL_WORK` zone orders alongside manual `FORCED_ORDER` orders (`PNC_LumberWorkAdapter_{OrderBridge,Lifecycle}.lua`).
  - Added `PNC.FishingWorkAdapter` (`PNC_FishingWorkAdapter.lua` + `_OrderBridge.lua`), deferred standalone `PNC_FishingExecutor` provider registration when `PNC.WorkService` is active, integrated `WorkToilRunner.ObserveLiveApproach` and `WorkOutputService` catch delivery/flush (`PNC_FishingService_WorkOutput.lua` + `PNC_FishingService_Work.lua`), and wired `PNC_FishingWorkAdapter` into `PNC_ServerComposition.lua`.
  - Integrated `PNC.WorkToilRunner.ObserveLiveApproach` into `PNC_CorpseHaulService_WorkAdapter_Tick.lua` for `SOURCE_APPROACH` and `DESTINATION_APPROACH`.
  - Added `tests/pnc_fishing_work_adapter_smoke.lua` and verified Kahlua compatibility across all Phase F3 modules.

## Current Evidence
- `TEST_VERIFIED`: `python3 tests/run_tests.py pnc_lumber_*_smoke pnc_fishing_*_smoke pnc_corpse_haul_*_smoke pnc_work_output_service_smoke pnc_work_toil_runner_smoke pnc_work_service_presence_boundary_smoke` (27 tests) -> `PASS 27/27`.
- `STATIC_VERIFIED`: `pz_verify.py --kahlua` across `PNC/Lumber`, `PNC/Fishing`, and `PNC_CorpseHaulService_WorkAdapter_Tick.lua` -> 0 Kahlua issues.

## Known Gap
- `Farming` is still tied to `FacilityJobs` (`farm.work`), requires `affiliation.role == "farmer"`, lacks `PZFarmingAdapter.CanPlowSquare`/`Plow` support on unplowed dirt/grass, does not collect seeds/water/tools physically via `WorkInputService`/`WorkItemService` or haul harvests via `WorkOutputService`, and lacks real `TickAbstract` progression.

## Immediate Next Chunk
**Phase F4:** Remove the `affiliation.role == "farmer"` gate, add `PZFarmingAdapter.CanPlowSquare` & `Plow`, add zone-based farming (`CreateZone` + plot compatibility), register `FARMING` with `PNC.WorkService` (retiring `FacilityJobs` `"farm.work"`), execute `Plow -> Plant -> Water -> Harvest` through `WorkToilRunner` + `WorkInputService` + `WorkOutputService`, and implement real `TickAbstract` progression.

## Immediate Acceptance Criteria
1. Any colonist with `WorkPolicy.IsEnabled(record, "Farmer")` can claim a `FARMING` order on a zone containing actionable tiles (`NEEDS_PLOW`, `NEEDS_SEED`, `NEEDS_WATER`, `HARVESTABLE`), acquire a digging tool + seeds/water from colony storage, walk to tiles, plow/plant/water/harvest, and deposit harvests into storage.
2. Zones with only well-watered `GROWING` tiles do not keep colonists pinned to active `FARMING` orders.
3. Abstract farming advances growth/state and deposits outputs into `ColonyStorageRepository` without stalling in `WAITING_FOR_WORLD`, with `pnc_farming_mechanics_smoke`, `pnc_farming_provider_smoke`, and `pnc_pz_farming_adapter_presence_boundary_smoke` passing.
