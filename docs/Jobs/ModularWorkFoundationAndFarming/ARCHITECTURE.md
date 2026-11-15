# Modular Work Foundation & Zone-Based Farming Architecture

## 1. Purpose & Core Invariant

All settlement and zone-based chores in ProjectHoomans (`LUMBER`, `FISHING`, `CORPSE_HAUL`, `FARMING`, `CRAFT`, `CONSTRUCT`, `RESEARCH`, `PROVISION_PICKUP`) MUST execute through a single server-authoritative work foundation (`PNC.WorkService` bridged into `PNC.Tasking` via `PNC_WorkTaskProvider`) rather than bespoke per-feature tasking providers or `FacilityJobs` seat piggybacks.

## 2. State Ownership Boundaries

| Domain / Service | Authoritative State Owned | Public Contract | Forbidden Actions |
| --- | --- | --- | --- |
| `PNC.WorkDefinitions` (`shared/PNC/Core/Production/WorkDefinition/`) | Declarative operation metadata (`OPERATION`, `JOB_BY_OPERATION`, `CAPABILITY_BY_OPERATION`, `USES_FATIGUE_GATE`, `EXECUTION_POLICY`, `LOCATION_POLICY_BY_OPERATION`, `MANUAL_PROGRESS`) | Read-only queries (`LocationPolicy`, `ExecutionPolicy`, `UsesFatigueGate`, `WorkRate`) | Hardcoding operation names inside `WorkService_Core` |
| `PNC.JobRequirements` & `PNC.WorkItemService` (`shared/PNC/Core/Production/WorkItems/` & `server/PNC/Production/`) | Reusable tool requirements (`primary_tool`, `digging_tool`, etc.), equipment leases, and stockpile tool pickup/return (`WORK_ITEM_PICKUP`, `WORK_ITEM_RETURN`) | `Check`, `CanAcquireFromStorage`, `PrepareOrder`, `Ensure`, `Release`, `ReturnToStorage` | Rejecting unassigned workers in `workerAvailable` when a valid tool exists in colony storage |
| `PNC.WorkInputService` (`server/PNC/Production/PNC_WorkInputService.lua`) | Consumable work-order material reservations, stockpile collection (`COLLECT_INPUTS`), staging, and consumption/rollback | `Bind`, `RequiresCollection`, `IsReady`, `Collect`, `Commit`, `Cancel` | Teleporting materials directly from `ColonyStorageRepository` into worker inventory during live execution without stockpile collection |
| `PNC.WorkOutputService` (`server/PNC/Production/PNC_WorkOutputService.lua`) | Produced/harvested item capture (from ground or worker inventory), stockpile output capacity reservation, travel-to-stockpile node resolution, and storage deposit | `EnsureOutputEffect`, `CaptureGroundOutput`, `CaptureInventoryOutput`, `TickLiveDelivery`, `FlushAbstractDelivery`, `ReleaseOutputCapacity` | Duplicating stockpile deposit state machines inside individual chores (`Lumber`, `Fishing`, `Farming`) |
| `PNC.WorkToilRunner` (`server/PNC/Production/WorkService/PNC_WorkToilRunner.lua`) | Standardized live/abstract step progression (`ENSURE_TOOLS` -> `COLLECT_INPUTS` -> `APPROACH_TARGET` -> `WORK_TARGET` -> `DELIVER_OUTPUTS`) and unified `PathService` movement-recovery observation | `ObserveLiveApproach`, `SetOrderPhase`, `RunToilStep` | Bespoke per-service distance watchdogs that race `PNC.PathService` |
| `PNC.WorkZoneService` (`server/PNC/Production/WorkZoneService/`) | Shared zone geometry (`PC_GridRegion`), `PC_ZoneRegistry` registration, bounded cursor tile scanning, per-spot/tile claim TTLs, and dual-mode worker dispatch (autonomous `WorkPolicy` + explicit `AssignWorker`) | `CreateZone`, `DeleteZone`, `DisableZone`, `AssignWorker`, `UnassignWorker`, `ClaimTarget`, `RenewTarget`, `ReleaseTarget`, `ScanStep` | Unbounded `IsoCell` scans or persisting live Java objects (`IsoTree`, `IsoObject`, `InventoryItem`) in ModData |
| `PNC.FarmingService` & `PNC.PZFarmingAdapter` (`server/PNC/Farming/`) | Farming zone/plot policy (`desiredCrop`, `policy` flags, `region`), bounded tile convergence against `SFarmingSystem.instance` (`NEEDS_PLOW`, `NEEDS_SEED`, `NEEDS_WATER`, `HARVESTABLE`), and deferred unloaded-square world effects | `CreateZone` / plot commands, `InspectZone`, `WorkService` target/execution/completion handlers | Requiring player pre-dug furrows, hard-blocking colonists via `affiliation.role == "farmer"`, or leaving harvested crops stranded in NPC inventory |

## 3. Dual Dispatch Modes (RimWorld Consistency)

Every zone-based chore (`LUMBER`, `FISHING`, `FARMING`, `CORPSE_HAUL`) supports two clean dispatch modes through `PNC.WorkService`:

1. **Autonomous Colony WorkGiver Mode (`NORMAL_WORK` / `HIGH_WORK`):**
   - Enabled zones belonging to a base/colony reconcile bounded, unassigned `WorkService` orders (`requiredWorkerId = nil`, `priority = 20..60`) ONLY when actionable work exists (e.g., unclaimed trees, available fishing spots with storage space, farm tiles needing plow/seed/water/harvest, corpses in hygiene zones).
   - Any colonist in the settlement with the corresponding job enabled (`WorkPolicy.GetPriority(record, job) > 0`) autonomously claims and executes the work order according to their 1..4 job priority matrix.
2. **Explicit Player Assignment Mode (`FORCED_ORDER`):**
   - When a player explicitly assigns a worker to a zone (`AssignWorker(zoneId, npcId)`), the order sets `requiredWorkerId = npcId`, `manual = true`, and `priority = 90` (`FORCED_ORDER`), pinning that worker until unassigned, disabled, or exhausted.

## 4. Standardized Toil Execution Contract (`PNC.WorkToilRunner`)

Every world-chore work order executes through deterministic, inspectable phases:

1. **`ENSURE_TOOLS`:** Verifies required durable tool via `WorkItemService`. If the assigned worker does not hold the tool in personal inventory, `WorkItemService` reserves it in `ColonyStorageService` and routes the worker through `WORK_ITEM_PICKUP` at the nearest `StockpileAccessService` node before approaching the work site.
2. **`COLLECT_INPUTS`:** For operations requiring consumable inputs (e.g., `FARMING` seed packets or water containers), reserves inputs via `WorkInputService`, paths live workers to the stockpile access node (`TRAVEL_TO_STOCKPILE`), and collects the items into the worker's inventory.
3. **`APPROACH_TARGET`:** Paths the live worker to the claimed world coordinate (`stationTarget`) and delegates stall/backoff/reset detection to `PNC.PathService.GetMovementRecoveryState`.
4. **`WORK_TARGET`:**
   - **Live Executor:** Faces target, plays domain animation scene / prop, checks `WorkFatigueGate`, and commits the authoritative engine mutation (`PZFarmingAdapter`, `IsoTree:WeaponHit`, `Fishing.RollAttempt`, `CorpseHaulService`).
   - **Abstract Executor:** Advances bounded elapsed-time progress using the same skill/tool rate rules, consumes inputs/tool condition, and either commits the domain state or registers an identity-checked `WorldEffectService` entry when the target square is unloaded.
5. **`DELIVER_OUTPUTS`:** Routes produced items (felled logs on ground, harvested crops, caught fish) through `PNC.WorkOutputService` to reserve stockpile capacity, walk to the stockpile access node (`TRAVEL_TO_STOCKPILE`), and deposit into `ColonyStorageRepository`.

## 5. Zone-Based Farming Convergence Rules

1. **Engine Truth Derivation (Principle 16):** ProjectHoomans persists only zone/plot geometry, `desiredCrop`, and automation policy (`autoPlow`, `autoPlant`, `autoWater`, `autoHarvest`, `autoReplant`). `SFarmingSystem.instance` owns actual tile state.
2. **Automatic Furrow Creation (`NEEDS_PLOW`):** When a tile inside an active farming zone has `not plant` (unplowed dirt/grass) and `autoPlow ~= false`, the tile is classified as `NEEDS_PLOW` (not permanently `blocked`). The farmer acquires a digging tool (or uses hands if configured), walks to `(tile.x, tile.y, tile.z)`, clears surface grass/plants if necessary, and calls `SFarmingSystem.instance:plow(square)`.
3. **Actionable Work Gating:** Farming work orders are queued/active ONLY when at least one tile in the zone has an actionable convergence state (`HARVESTABLE`, `NEEDS_WATER`, `NEEDS_SEED`, `NEEDS_PLOW`) whose required materials/tools are available or reservable. When all tiles are `GROWING`, no farming work order holds the worker.
4. **Harvest Stockpile Hauling:** Harvesting a tile captures the yielded crops/seeds into the worker's inventory and transitions into `WorkOutputService` so the harvest is deposited into colony storage.
