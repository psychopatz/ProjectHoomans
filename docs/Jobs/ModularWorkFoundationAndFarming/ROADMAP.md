# Modular Work Foundation & Zone-Based Farming Roadmap

## Parent Objective

Deliver a unified, RimWorld-consistent server-authoritative work foundation (`PNC.WorkService` + `PNC.WorkItemService` + `PNC.WorkInputService` + `PNC.WorkOutputService` + `PNC.WorkToilRunner` + `PNC.WorkZoneService`) and rebuild `Farming` on top of it as a true zone-based chore (like `Lumber`) where colonists automatically acquire tools/seeds/water from stockpiles, physically walk to tiles to plow/seed/water/harvest without requiring pre-built player furrows, haul outputs back to colony storage, and maintain full Live/Abstract execution parity across `Farming`, `Lumber`, `Fishing`, and `CorpseHaul`.

## Why

Currently, world chores in ProjectHoomans are split across three incompatible architectures:
1. `Farming` piggybacks on `PNC.FacilityJobs` (`farm.work`), hard-blocks colonists unless `affiliation.role == "farmer"`, requires players to manually dig furrows beforehand (`FARMING_FURROW_REQUIRED`), teleports seeds/water from storage without stockpile travel, mutates tiles from the facility anchor without walking to each tile, leaves harvested crops stuck in NPC inventory, and has a no-op `TickAbstract`.
2. `Fishing` runs a standalone `PNC_FishingExecutor` provider outside `WorkService` at hardcoded `FORCED_ORDER` precedence and leaves caught fish in personal inventory.
3. `Lumber` and `CorpseHaul` use `WorkService`, but `Lumber` traps 770+ lines of stockpile output delivery and travel-recovery code inside private `LumberService` modules, while `WorkService_Core` and `WorkItemService.PrepareOrder` have a Catch-22 that blocks unassigned colony orders (`requiredWorkerId = nil`) from acquiring tools from colony storage.

## Current Verified Baseline

- Repository: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main` @ `d45a2c6af097eddd5baef1e9ba94950b577bc8e6`, Build `42.20`).
- `PNC_WorkService_Core.lua:171` rejects workers who do not already hold a required tool in personal inventory, while `PNC_WorkItemService_Logistics.lua:249` (`PrepareOrder`) returns early when `not order.requiredWorkerId`.
- `PNC_FarmingService_Provider.lua:23-35` blocks any colonist whose `affiliation.role` is not `"farmer"`, and `PNC_PZFarmingAdapter_Inspection.lua:55-60` treats unplowed tiles as `NOT_FURROW` (`blocked`) with no plow operation in `PNC_FarmingService_Materials.lua`.
- Unrelated dirty worktree paths exist on `main` for `UnifiedSemanticDialogueAuthority` (S10A conversation/codebuilder files) and must be preserved untouched.

## Scope

1. **Phase F1 — WorkService & Tool/Input Logistics Foundation:** Declarative operation metadata in `PNC.WorkDefinitions` and stockpile-aware tool eligibility/acquisition in `WorkItemService` + `WorkService` for both unassigned (`requiredWorkerId = nil`) and assigned work orders.
2. **Phase F2 — Shared `WorkOutputService`, `WorkToilRunner`, and `WorkZoneService` Primitives:** Extract reusable ground/inventory output hauling to stockpiles, standardized live approach/stall recovery, and shared zone/claim/autonomous-WorkGiver helpers.
3. **Phase F3 — Unify `Lumber`, `Fishing`, and `CorpseHaul` on the Foundation:** Refactor `Lumber` to use `WorkOutputService` and `WorkToilRunner` (removing dead `PNC_LumberExecutor.lua`), migrate `Fishing` into `WorkService` with stockpile fish delivery and autonomous + manual priority support, and align `CorpseHaul` with the shared toil/recovery helpers.
4. **Phase F4 — Zone-Based `Farming` on the Unified Foundation:** Convert `Farming` into a zone-based `WorkService` operation (`FARMING`) that automatically plows unplowed dirt/grass tiles (`NEEDS_PLOW`), physically collects tools/seeds/water from stockpiles, walks to individual tiles to plow/seed/water/harvest, hauls harvested crops/seeds to colony storage via `WorkOutputService`, only advertises work when tiles have actionable tasks, and supports full `TickAbstract` parity.
5. **Phase F5 — UI/Debug Diagnostics, Test Suite & Live Harness Acceptance:** Expose unified work/toil/zone diagnostics in Colony/Colonist UI, pass all unit/smoke suites, and verify live zone farming + chore execution in `pz-runtime-harness`.

## Non-Goals

- Modifying unrelated Conversation / ConvoEngine / S10A dialogue files currently dirty in the worktree.
- Inventing a second crop biology simulation outside Project Zomboid's `SFarmingSystem`.

## Architecture Constraints

See `docs/Jobs/ModularWorkFoundationAndFarming/ARCHITECTURE.md`.

---

## Phases (Vertical Slices)

### Phase F1: WorkService & Tool/Input Logistics Foundation
- **Purpose:** Eliminate hardcoded operation checks in `WorkService` and fix the `WorkItemService` + `WorkService` Catch-22 so any qualified colonist can claim a tool-requiring work order (`LUMBER`, `FISHING`, `FARMING`) whenever the tool is either in their inventory OR available in colony storage, then physically pick it up via `WORK_ITEM_PICKUP`.
- **Dependencies:** None.
- **Implementation Responsibilities:**
  - Extend `PNC_WorkDefinitions_Constants.lua` with `FARMING` and `FISHING` operations, `JOB_BY_OPERATION`, `CAPABILITY_BY_OPERATION`, `USES_FATIGUE_GATE`, `EXECUTION_POLICY`, and `LOCATION_POLICY_BY_OPERATION`.
  - Add `PNC.JobRequirements` definitions for `FARMING` (digging tool candidates for plowing: `Base.HandFork`, `Base.Trowel`, `Base.Shovel`, `Base.Shovel2`, `Base.SnowShovel`, `Base.GardenFork`, `Base.GardenHoe`).
  - Add `WorkItemService.CanAcquireFromStorage(record, operation)` and update `WorkService_Core.lua` (`workerAvailable`) and `WorkItemService_Logistics.lua` (`PrepareOrder` / post-assignment hook) so unassigned colony orders can be claimed by workers who can acquire the required tool from storage, automatically triggering `WORK_ITEM_PICKUP`.
- **Acceptance Gates:**
  - An unassigned `LUMBER`, `FISHING`, or `FARMING` order in `WorkService` is assignable to a colonist with empty personal inventory when a valid tool exists in `ColonyStorageRepository`.
  - Claiming the order queues/executes `WORK_ITEM_PICKUP` at the stockpile node before work execution and returns the tool on completion/cancellation according to return policy.
- **Evidence Required:** `TEST_VERIFIED` via `tests/pnc_work_item_logistics_smoke.lua`, `tests/pnc_job_requirements_smoke.lua`, and `tests/pnc_work_policy_smoke.lua`.
- **Exit Condition:** All Phase F1 smoke tests pass with zero regressions.

### Phase F2: Shared `PNC.WorkOutputService` & `PNC.WorkToilRunner` Primitives
- **Purpose:** Provide one canonical implementation for hauling produced/harvested items (from ground or NPC inventory) to colony stockpiles and one canonical helper for live world-target approach + `PathService` stall recovery.
- **Dependencies:** Phase F1.
- **Implementation Responsibilities:**
  - Create `server/PNC/Production/PNC_WorkOutputService.lua` (extracted and generalized from `PNC_LumberService_Execution_OutputDelivery_*.lua`) supporting both ground-item pickup and direct NPC-inventory output reservation, travel to `StockpileAccessService.FindNearest`, deposit animation, `ColonyStorageService.TransferIntoStorage`, and abstract output flush.
  - Create `server/PNC/Production/WorkService/PNC_WorkToilRunner.lua` providing unified live target approach, arrival envelope checking, `PathService.GetMovementRecoveryState` stall/backoff observation, and standardized `WorkInputService` stockpile collection transitions.
- **Acceptance Gates:**
  - Both ground-spawned outputs and inventory-added outputs reserve stockpile capacity, walk live workers to the nearest stockpile node, deposit into `ColonyStorageRepository`, and flush cleanly in abstract mode.
- **Evidence Required:** `TEST_VERIFIED` via dedicated `tests/pnc_work_output_service_smoke.lua` and `tests/pnc_work_toil_runner_smoke.lua`.
- **Exit Condition:** Shared output and toil runner modules are wired into `PNC_ServerComposition.lua` / `PNC_WorkService.lua` and verified by smoke tests.

### Phase F3: Migrate `Lumber`, `Fishing`, and `CorpseHaul` to the Unified Foundation
- **Purpose:** Eliminate the split chore execution patterns across `Lumber`, `Fishing`, and `CorpseHaul`.
- **Dependencies:** Phase F2.
- **Implementation Responsibilities:**
  - Refactor `LumberService` output delivery and live travel watchdog to delegate to `PNC.WorkOutputService` and `PNC.WorkToilRunner`; retire dead `PNC_LumberExecutor.lua` provider registration and support autonomous colony `LUMBER` orders (`NORMAL_WORK`) alongside explicit `AssignWorker` (`FORCED_ORDER`).
  - Register `FISHING` in `PNC.WorkService` via a `PNC_FishingWorkAdapter` (replacing standalone `PNC_FishingExecutor` tasking registration), routing caught fish through `PNC.WorkOutputService` to colony storage when inventory fills or job completes, and supporting both autonomous `Fishing` work priority and explicit zone assignment.
  - Align `CorpseHaulService_WorkAdapter` approach/recovery checks with `WorkToilRunner`.
- **Acceptance Gates:**
  - `Lumber`, `Fishing`, and `CorpseHaul` all execute as `WorkService` operations bridged through `PNC_WorkTaskProvider`.
  - Caught fish and felled logs are delivered to colony storage through `PNC.WorkOutputService`.
- **Evidence Required:** `TEST_VERIFIED` across `pnc_lumber_*_smoke.lua`, `pnc_fishing_*_smoke.lua`, and `pnc_corpse_haul_*_smoke.lua`.
- **Exit Condition:** All Lumber, Fishing, and CorpseHaul smoke tests pass on the unified foundation.

### Phase F4: Rebuild `Farming` as a Zone-Based Chore on the Unified Foundation
- **Purpose:** Make Farming work seamlessly like Chop Wood (`Lumber`): zone-based, autonomous or assigned, automatically plowing unplowed ground, collecting tools/seeds/water physically from stockpiles, walking to each tile, hauling harvests to storage, and supporting abstract execution.
- **Dependencies:** Phase F3.
- **Implementation Responsibilities:**
  - Remove the `affiliation.role == "farmer"` hard gate so any colonist with `WorkPolicy.IsEnabled(record, "Farmer")` can farm.
  - Add `PZFarmingAdapter.CanPlowSquare` and `PZFarmingAdapter.Plow(record, body, tile)` so unplowed dirt/grass tiles inside a farming zone/plot are reported as `NEEDS_PLOW` (`policy.autoPlow ~= false`) and tilled automatically using a digging tool from `WorkItemService`.
  - Support zone-based farming (`PNC.FarmingService.CreateZone` / zone geometry + backward compatibility with existing growing plot regions) and register `FARMING` with `PNC.WorkService` (retiring the `FacilityJobs` `"farm.work"` seat piggyback).
  - Route `FARMING` execution through `WorkToilRunner`:
    1. Only queue/activate `FARMING` orders when `InspectPlot`/`InspectZone` finds actionable tiles (`HARVESTABLE`, `NEEDS_WATER`, `NEEDS_SEED`, `NEEDS_PLOW`).
    2. Physically collect seeds/water/digging tools from colony storage at the stockpile access node (no teleporting).
    3. Walk the live NPC to the specific target tile `(tile.x + 0.5, tile.y + 0.5, tile.z)`, play the farming animation, and execute `Plow`, `Plant`, `Water`, or `Harvest`.
    4. Route harvested crops/seeds through `PNC.WorkOutputService` into `ColonyStorageRepository`.
    5. Implement real `TickAbstract` progression (consuming storage seeds/water, advancing tile state or queuing `WorldEffectService` mutations, and depositing harvest into storage).
- **Acceptance Gates:**
  - A colonist with `Farmer` enabled in `WorkPolicy` (even without `affiliation.role == "farmer"`) claims a `FARMING` work order on a designated zone of raw dirt/grass tiles, fetches a trowel/shovel and seeds from storage, walks to each tile to plow and plant, waters dry tiles, harvests mature crops, and deposits the harvest into colony storage.
  - When all tiles in the zone are `GROWING` and well-watered, no active `FARMING` order holds the colonist.
  - Abstract farming progresses and mutates state/storage without stalling in `WAITING_FOR_WORLD`.
- **Evidence Required:** `TEST_VERIFIED` via updated and expanded `pnc_farming_mechanics_smoke.lua`, `pnc_farming_provider_smoke.lua`, and `pnc_pz_farming_adapter_presence_boundary_smoke.lua`.
- **Exit Condition:** All Farming and Production smoke suites pass.

### Phase F5: UI/Debug Diagnostics, Full Regression & Live Harness Acceptance
- **Purpose:** Verify end-to-end observability in Colony/Colonist UI and prove live runtime behavior.
- **Dependencies:** Phase F4.
- **Implementation Responsibilities:**
  - Ensure `ColonyManagement` snapshots and Colonist work debug views display unified `FARMING`, `LUMBER`, `FISHING`, and `CORPSE_HAUL` order statuses, active toil phases, and waiting/rejection reasons.
  - Run the full relevant Lua smoke test battery and execute live verification via `pz-runtime-harness` when available.
- **Acceptance Gates:**
  - All work/chore smoke tests pass (`TEST_VERIFIED`) and live/harness verification (`HARNESS_VERIFIED` / `GUI_VERIFIED`) confirms colonists autonomously plow, plant, water, harvest, chop wood, fish, and haul outputs to storage.
- **Evidence Required:** `TEST_VERIFIED` + `HARNESS_VERIFIED` (or explicit environment blocker record if JVM harness is offline).
- **Exit Condition:** Parent objective complete and ready for user acceptance.
