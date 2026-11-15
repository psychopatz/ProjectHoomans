# Modular Work Foundation & Zone-Based Farming Progress

## Parent Goal Status
`READY_FOR_USER_LIVE_ACCEPTANCE` (Phases F1–F5 developer work verified and committed; only user-owned native SP/MP runtime verification remains because the local PZ JVM/profiler bridge is disconnected)

## Current Phase
`Phase F5 Complete (Developer-Side) — Ready for User-Owned Live SP/MP Acceptance`

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

- **Phase F5 Accepted (`TEST_VERIFIED`, Developer-Side Complete):**
  - Updated `PNC_WorkService_Snapshots.lua` (`BuildTaskSnapshot`, `BuildActionInformation`) so `FARMING`, `FISHING`, `CORPSE_HAUL`, `LUMBER`, and all `WorkService` operations expose unified `phase`, `toilPhase`, `waitingFor`, `waitingReason`, `blockedReason`, and `activityItemFullType` (`WorkItemService` tool lookup fallback).
  - Updated `PNC_NameplatePresentation_Actions.lua`, `PNC_ColonistActivityPresentation.lua`, and `PNC_ColonistActivities_Core.lua` to render `FARMING`, `FISHING`, and `CORPSE_HAUL` action labels, active toil phases, and waiting/blocked reasons cleanly.
  - Updated `PNC_SettlementManagement_FacilityActions_Area.lua` (`growing.plot`) and `EN`/`TL` `Settlement.json` + `Tasks.json` catalogs so UI plot designation accepts unplowed arable soil alongside cultivated furrows (`FARMLAND_REQUIRED` when barren) and all new UI action/job keys exist in both English and Tagalog.
  - Updated `tests/pnc_mp_server_file_guard_smoke.lua` (`1033 -> 1057` guarded server files) and added `tests/pnc_work_ui_diagnostics_smoke.lua` and `tests/pnc_work_zone_service_smoke.lua`.
  - Delivered `PNC.WorkZoneService` (`PNC_WorkZoneService.lua` + `WorkZoneService/{Registry,Claims,Dispatch}.lua`) owning `PC_GridRegion` normalization, `PC_ZoneRegistry` sync, bounded cursor `ScanStep`, per-target TTL `ClaimTarget`/`RenewTarget`/`ReleaseTarget`, and dual-mode `ResolveDispatchMode` (`FORCED_ORDER` vs `NORMAL_WORK`), wired in `PNC_Production.lua` and integrated into `PNC_FarmingService_Zones.lua`.

## Current Evidence
- `TEST_VERIFIED`: `python3 tests/run_tests.py pnc_work_zone_service_smoke pnc_mp_server_file_guard_smoke pnc_farming_work_adapter_smoke pnc_farming_service_presence_boundary_smoke pnc_work_service_presence_boundary_smoke pnc_composition_bootstrap_smoke pnc_job_requirements_smoke pnc_work_item_service_smoke pnc_work_item_logistics_smoke pnc_work_policy_smoke pnc_work_ui_diagnostics_smoke` -> `PASS 11/11 in 0.58s`.
- `TEST_VERIFIED`: Full suite `python3 tests/run_tests.py` -> `1027/1028` passed (`pnc_mp_server_file_guard_smoke` passed across all 1057 server Lua files). The single failure (`pnc_population_director_smoke.lua:316`) loads zero files from any Phase F1–F5 subsystem and is an unrelated pre-existing failure in world bootstrap tests.
- `STATIC_VERIFIED`: `pz_verify.py --kahlua --tokens` reported 0 Kahlua issues and 0 bloated files across `WorkZoneService/`, `PNC_WorkZoneService.lua`, `PNC_FarmingService_Zones.lua`, and `PNC_Production.lua` (plus 0 Kahlua issues across 286 files in Phases F1–F5); `python3 -m json.tool` validated all 4 updated `EN`/`TL` JSON catalogs.
- `ENVIRONMENT_OFFLINE`: `analyze_profiler.py bridge status` / `process status` reported `{ "configured": false, "connected": false, "state": "disconnected" }` — native Project Zomboid is not running, and live SP/MP runtime testing belongs to the user.

## Known Gap
- Only user-owned live Project Zomboid SP/MP verification (`Console` clean, UI growing plot designation on unplowed dirt/grass, live NPC tool/seed/water collection, plow/plant/water/harvest, wood chopping, fishing, and corpse hauling in-engine) remains because live JVM execution is offline.

## Immediate Next Chunk
**User-Owned Acceptance:** Optionally launch Project Zomboid (SP/MP) and verify in-game zone/plot designation, colonist Farming/Lumber/Fishing/CorpseHaul execution, nameplates, and `console.txt`.

## Immediate Acceptance Criteria
1. All developer-side gates (Phases F1–F5 unit/integration tests, MP server guard across 1053 files, Kahlua static verification, EN/TL JSON validation) are verified and committed on `main`.
2. User validates live SP/MP engine execution in Project Zomboid when ready.
