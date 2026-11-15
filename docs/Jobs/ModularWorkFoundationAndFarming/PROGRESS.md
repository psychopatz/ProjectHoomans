# Modular Work Foundation & Zone-Based Farming Progress

## Parent Goal Status
`IN_PROGRESS` (Phase F4 accepted; continuing to Phase F5)

## Current Phase
`Phase F5 — UI/Debug Diagnostics, Full Regression & Acceptance`

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

- **Phase F4 Accepted (`TEST_VERIFIED`):**
  - Removed the `affiliation.role == "farmer"` gate across `PNC_FarmingService_Provider.lua` and `PNC_FarmingWorkAdapter_OrderBridge.lua`; any colonist with `WorkPolicy.IsEnabled(record, Farming.FARMER_JOB)` can perform `FARMING`.
  - Extended `shared/PNC/Core/Farming/PNC_Farming.lua` (`autoPlow = true`, `ZoneInfo`, `MAX_ZONE_*` bounds) and `PZFarmingAdapter` (`CanPlowSquare`, `Plow`, `InspectZone`, unplowed arable `ValidatePlotRegion` + `NEEDS_PLOW` classification).
  - Added zone-based `PNC_FarmingService_Zones.lua` (`CreateZone`, `GetZone`, `ListZones`, `SetZoneDesiredCrop`, `SetZonePolicy`, `AssignWorker`), split `PNC_FarmingService_AbstractTicks.lua` for real abstract growth/input consumption/output deposit via `PNC.WorkOutputService.FlushAbstractDelivery`, and updated `PNC_FarmingService_Materials.lua` + `_Snapshots.lua`.
  - Created `PNC.FarmingWorkAdapter` (`PNC_FarmingWorkAdapter.lua`, `_Selection.lua`, `_OrderBridge.lua`, `_Actions.lua`, `_Execution.lua`), wired into `PNC_ServerComposition.lua`, registering `"FARMING"` in `PNC.WorkService` (and deferring legacy `"farm.work"` when unified adapter + service are active) so colonists acquire tools (`WorkItemService`), collect seeds/water (`WorkInputService`), walk/animate through `Plow -> Seed -> Water -> Harvest` (`WorkToilRunner`), and deposit harvests (`WorkOutputService`).
  - Added `tests/pnc_farming_work_adapter_smoke.lua` and updated `pnc_farming_mechanics_smoke`, `pnc_farming_provider_smoke`, `pnc_farming_service_presence_boundary_smoke`, and `pnc_pz_farming_adapter_presence_boundary_smoke`.

## Current Evidence
- `TEST_VERIFIED`: `python3 tests/run_tests.py` across 14 Phase F4 farming & unified work foundation smoke tests -> `PASS 14/14 in 0.19s`.
- `STATIC_VERIFIED`: `pz_verify.py --kahlua --tokens` across all 21 files under `server/PNC/Farming/` and `PNC_Farming.lua` -> 0 Kahlua issues, 0 bloated files.

## Known Gap
- UI / debug inspection and `PNC_SettlementManagement_FacilityActions_Area.lua` arable-soil plot/zone designation compatibility need Phase F5 verification, along with full project regression (`python3 tests/run_tests.py`) and live/runtime harness availability check.

## Immediate Next Chunk
**Phase F5:** Audit and update UI/debug diagnostics and `PNC_SettlementManagement_FacilityActions_Area.lua`, verify translations/`--i18n`, run full `ProjectHoomans` test suite and static verification, check local PZ runtime harness status (without launching native PZ unless authorized), and reconcile final `PROGRESS.md`/`HANDOFF.md` checkpoint.

## Immediate Acceptance Criteria
1. Colony management / work UI & debug snapshots expose unified `FARMING`, `LUMBER`, `FISHING`, and `CORPSE_HAUL` statuses, active toil phases, and waiting reasons cleanly, and settlement farming designation supports unplowed arable soil without requiring pre-built furrows.
2. Full `python3 tests/run_tests.py` suite passes with zero regressions and zero Kahlua/token-bloat/i18n findings across Phase F1–F5 changes.
3. `PROGRESS.md` and `HANDOFF.md` accurately reflect final developer-verified evidence and any remaining user-owned live SP/MP validation gate.
