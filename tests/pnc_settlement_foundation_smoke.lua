local T = require "tests/support/test"

T.addPackagePaths()
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local sequence = 0
function ZombRand() sequence = sequence + 1; return sequence end
function getTimeInMillis() sequence = sequence + 1; return sequence end

local persistedModData = {}
ModData = {
    getOrCreate = function(key)
        persistedModData[key] = persistedModData[key] or {}
        return persistedModData[key]
    end,
}

require "PNC/Core/Base/PNC_Core"
require "PNC/Core/Events/PNC_EventDefinitions"
require "PNC/Core/Settlement/PNC_SettlementDefinitions"
require "PNC/Core/Farming/PNC_Farming"
require "PNC/Core/Farming/PNC_PlantingCatalog"
require "PNC/Core/Settlement/PNC_FacilityDefinitions"
require "PsychopatzCore/Events/PC_EventBus"
require "PNC/Settlement/PNC_SettlementRepository"
require "PNC/Settlement/PNC_BaseValidationService"
require "PNC/Settlement/PNC_BaseService"
require "PNC/Settlement/PNC_FacilityValidationService"
require "PNC/Settlement/PNC_FacilityCostService"
require "PNC/Settlement/PNC_FacilityService"
require "PNC/Settlement/PNC_InteractionTargetResolver"
require "PNC/Settlement/PNC_FacilityReservations"
require "PNC/Settlement/PNC_StockpileAccessService"

-- Match the Build 42 Kahlua sandbox for the settlement runtime path.
next = nil

PNC.BasePermissions = {
    CanManage = function() return true end,
    CanCreate = function() return true end,
}
PNC.SettlementRepository.Import({})
PNC.FacilityService.RebuildIndexes()
local constructionSequence = 0
PNC.ConstructionService = {
    QueueBuild = function(_, facility)
        constructionSequence = constructionSequence + 1
        facility.constructionState = "UNDER_CONSTRUCTION"
        facility.constructionWorkOrderId = "construction:"
            .. tostring(constructionSequence)
        return { id = facility.constructionWorkOrderId,
            operation = "CONSTRUCT" }
    end,
    QueueReconstruct = function(_, facility, change)
        constructionSequence = constructionSequence + 1
        facility.constructionState = "RECONSTRUCTING"
        facility.constructionWorkOrderId = "reconstruction:"
            .. tostring(constructionSequence)
        facility.pendingTestChange = change
        return { id = facility.constructionWorkOrderId,
            operation = "RECONSTRUCT" }
    end,
}

local money = {}
local inventory = {}
local function moneyItem()
    local item = {}
    function item:getFullType() return "Base.Money" end
    function item:getActualWeight() return 0 end
    function item:getWeight() return 0 end
    function item:getCondition() return 10 end
    function item:getConditionMax() return 10 end
    function item:getModData() return {} end
    function item:getContainer() return inventory end
    return item
end
money[1] = moneyItem()
local function javaList(values)
    return { size = function() return #values end,
        get = function(_, index) return values[index + 1] end }
end
function inventory:getItems() return javaList(money) end
function inventory:getItemsFromType(fullType)
    local values = fullType == "Base.Money" and money or {}
    return javaList(values)
end
function inventory:Remove(item)
    local index
    for index = #money, 1, -1 do
        if money[index] == item then table.remove(money, index); return end
    end
end
function inventory:AddItem(item) money[#money + 1] = item; return item end
local player = { getInventory = function() return inventory end }
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
CoreInventory.getItemTypeId("Base.Money", true)
local stockpileInventory = CoreInventory.createVirtualInventory()
T.truthy(stockpileInventory:add(moneyItem()), "stockpile placeholder money")
local stockpile = { id = "storage_test", ownerFactionId = "faction_test",
    inventory = stockpileInventory, revision = 0 }
local stockpileCommits = 0
PNC.ColonyStorageService = {
    ResolveForPlayer = function() return stockpile end,
    Internal = {
        CommitStorage = function(value)
            value.revision = value.revision + 1
            stockpileCommits = stockpileCommits + 1
        end,
        RecordActivity = function() end,
    },
}

local function rectangle(x1, y1, x2, y2, z)
    local rows = {}
    for y = y1, y2 do rows[y] = { x1, x2 } end
    return { levels = { [z or 0] = { rows = rows } } }
end

local created = PNC.BaseService.Create({}, {
    colonyId = "community_test", factionId = "faction_test",
    region = rectangle(0, 0, 9, 9), requestId = "create_base",
})
T.truthy(created.ok, "base creation")
local base = created.base
PNC.ResearchService = { Queries = { HasTechnology = function(_, id)
    return id == "hq:2"
end } }
T.equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 270,
    "starting territory")
local baseSnapshot = PNC.BaseService.BuildSnapshot(base)
T.equal(baseSnapshot.geometry.region.levels[0].rows[0][1], 0,
    "authoring snapshot includes canonical footprint")
local researchLevel = PNC.FacilityDefinitions.GetLevel(
    "research_facility", 1)
T.equal(researchLevel.componentLimits["research.room"], nil,
    "research room is not a functional component")
T.equal(researchLevel.componentLimits["work.research"].minCount, 1,
    "log table remains the research workstation component")
T.equal(researchLevel.componentLimits["work.research"].managed, true,
    "log table is managed by the facility")
T.equal(researchLevel.componentLimits["work.blueprint"], nil,
    "blueprint study no longer requires a virtual bench")
T.equal(researchLevel.componentLimits["work.reverse"], nil,
    "reverse engineering no longer requires a virtual lab")
local researchDefinition = PNC.FacilityDefinitions.Get("research_facility")
T.equal(researchDefinition.directWorkstation, true,
    "research facility uses the native workstation build flow")
T.equal(researchDefinition.entityScript, "Base.Log_Table",
    "research facility uses the native Log Table entity")
T.equal(researchDefinition.buildRecipeObjectInfoName, "Base.Log_Table",
    "research facility resolves the native Log Table recipe")
T.equal(researchDefinition.iconPath, nil,
    "research facility uses the native table icon")
local workshopLevel = PNC.FacilityDefinitions.GetLevel("workshop", 1)
T.equal(workshopLevel.componentLimits["workshop.room"], nil,
    "workshop room is not a functional component")
T.equal(workshopLevel.componentLimits["work.craft"].minCount, 1,
    "craft station remains a workshop component")
T.equal(workshopLevel.componentLimits["work.disassemble"].minCount, 1,
    "disassembly station remains a workshop component")
local waterLevel = PNC.FacilityDefinitions.GetLevel("water_collector", 1)
T.equal(waterLevel.componentLimits["water.spigot"].kind, "anchor",
    "water spigot is a physical interaction component")
T.equal(waterLevel.componentLimits["water.tank"].kind, "abstract",
    "water tanks use reusable abstract components")
T.equal(waterLevel.componentLimits["water.tank"].maxCount, 4,
    "water level one permits four tanks")
local waterLevelTen = PNC.FacilityDefinitions.GetLevel("water_collector", 10)
T.equal(waterLevelTen.componentLimits["water.catcher"].maxCount, 40,
    "water module limits scale through level ten")

local playerZoneConflict = PNC.BaseService.Create({}, {
    colonyId = "community_other", factionId = "faction_test",
    region = rectangle(5, 5, 7, 7), requestId = "player_zone_conflict",
})
T.equal(playerZoneConflict.reason, "PLAYER_ZONE_OCCUPIED",
    "new base cannot overlap an existing player zone")

PNC.Communities = {
    List = function()
        return { {
            id = "npc_community", status = "active",
            factionID = "faction_npc",
            home = { x = 30, y = 30, z = 0, radius = 4 },
        } }
    end,
}
local npcBaseConflict = PNC.BaseService.Create({}, {
    colonyId = "community_third", factionId = "faction_test",
    region = rectangle(29, 29, 31, 31), requestId = "npc_base_conflict",
})
T.equal(npcBaseConflict.reason, "NPC_BASE_OCCUPIED",
    "new base cannot overlap an NPC community")
PNC.Communities = nil

local safehouse = {
    getX = function() return 40 end,
    getY = function() return 40 end,
    getW = function() return 5 end,
    getH = function() return 5 end,
}
SafeHouse = {
    getSafehouseList = function()
        return { size = function() return 1 end,
            get = function(_, index) return index == 0 and safehouse or nil end }
    end,
}
local safehouseConflict = PNC.BaseService.Create({}, {
    colonyId = "community_fourth", factionId = "faction_test",
    region = rectangle(41, 41, 42, 42), requestId = "safehouse_conflict",
})
T.equal(safehouseConflict.reason, "PLAYER_ZONE_OCCUPIED",
    "new base cannot overlap a vanilla safehouse")
SafeHouse = nil

for index = 1, 13 do
    local built = PNC.BaseService.BuildBarricade({}, {
        baseId = base.id, expectedRevision = base.revision,
        requestId = "barricade_" .. tostring(index),
    })
    T.truthy(built.ok, "barricade " .. tostring(index))
end
T.equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 400,
    "HQ1 capped territory")
T.equal(PNC.BaseService.BuildBarricade({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "barricade_rejected" }).reason,
    "HQ_TERRITORY_LIMIT", "barricade hard limit")

local upgradedHQ = PNC.BaseService.UpgradeHQ({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "hq2" })
T.truthy(upgradedHQ.ok, "HQ upgrade")
T.equal(PNC.BaseService.UpgradeHQ({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "hq3_locked" }).reason,
    "TECHNOLOGY_REQUIRED", "HQ upgrade requires its researched capability")
T.equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 400,
    "HQ upgrade grants no territory")
T.truthy(PNC.BaseService.BuildBarricade({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "barricade_14" }).ok,
    "post-upgrade barricade")
T.equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 410,
    "post-upgrade territory")

local expanded = PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "expand",
    regionDelta = rectangle(10, 0, 10, 4) })
T.truthy(expanded.ok, "connected expansion")
T.equal(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "remote",
    regionDelta = rectangle(20, 20, 21, 21) }).reason,
    "BASE_DISCONNECTED", "remote island")
T.equal(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "diagonal",
    regionDelta = rectangle(11, 5, 11, 5) }).reason,
    "BASE_DISCONNECTED", "diagonal-only expansion")

T.equal(PNC.FacilityService.Create(player, { baseId = base.id,
    definitionId = "barracks", expectedRevision = base.revision,
    component = { kind = "region", role = "facility.footprint",
        region = rectangle(0, 0, 3, 3, 0) },
}).reason, "STOCKPILE_REQUIRED", "stockpile gates every other facility")

local stockpileResult = PNC.FacilityService.Create(player, {
    baseId = base.id, definitionId = "stockpile",
    expectedRevision = base.revision,
    component = { kind = "region", role = "storage.stockpile",
        region = rectangle(9, 9, 9, 9, 0) },
})
T.truthy(stockpileResult.ok, "bootstrap stockpile creation")
local stockpileFacility = stockpileResult.facility
T.equal(#stockpileFacility.componentIds, 0,
    "component ids remain a keyed collection")
stockpileFacility.constructionState = "BUILT"
PNC.FacilityService.RefreshState(stockpileFacility)
T.equal(stockpileFacility.cachedState, "OPERATIONAL",
    "built stockpile is operational")
local stockpileComponentId
for componentId, _ in pairs(stockpileFacility.componentIds) do
    local component = PNC.SettlementRepository.GetComponent(componentId)
    if component and component.role == "storage.stockpile" then
        stockpileComponentId = componentId
    end
end
local stockpileEdit = PNC.FacilityService.SetComponent(player, {
    facilityId = stockpileFacility.id,
    expectedRevision = stockpileFacility.revision,
    component = { id = stockpileComponentId, kind = "region",
        role = "storage.stockpile", region = rectangle(9, 8, 9, 8, 0) },
})
T.truthy(stockpileEdit.ok and stockpileEdit.pendingComponent,
    "stockpile can move outside its old footprint through reconstruction")
T.truthy(PNC.FacilityService.FinalizeSetComponent(stockpileFacility.id,
    stockpileEdit.pendingComponent), "stockpile edit completes")
T.equal(stockpileFacility.constructionRegion.levels[0].rows[8][1], 9,
    "completed stockpile move replaces its construction footprint")
T.equal(PNC.FacilityService.RemoveComponent(player, {
    facilityId = stockpileFacility.id,
    expectedRevision = stockpileFacility.revision,
    componentId = stockpileComponentId,
}).reason, "STOCKPILE_CANNOT_DECONSTRUCT",
    "stockpile component cannot be deconstructed")
T.equal(PNC.FacilityService.Destroy(player, {
    facilityId = stockpileFacility.id,
    expectedRevision = stockpileFacility.revision,
}).reason, "STOCKPILE_CANNOT_DECONSTRUCT",
    "stockpile facility cannot be deconstructed")
local access = PNC.StockpileAccessService.FindNearest(base.id, 0, 0, 0)
T.equal(access.facilityId, stockpileFacility.id,
    "stockpile facility supplies the collection access target")
stockpileFacility.constructionState = "RECONSTRUCTING"
local rebuildingAccess = PNC.StockpileAccessService.FindNearest(base.id, 0, 0, 0)
T.equal(rebuildingAccess.facilityId, stockpileFacility.id,
    "stockpile remains a collection target during its own upgrade")
stockpileFacility.constructionState = "BUILT"
T.equal(PNC.FacilityService.Create(player, {
    baseId = base.id, definitionId = "stockpile",
    expectedRevision = base.revision,
    component = { kind = "region", role = "storage.stockpile",
        region = rectangle(8, 9, 8, 9, 0) },
}).reason, "STOCKPILE_ALREADY_EXISTS", "stockpile is singleton")

local barracksResult = PNC.FacilityService.Create(player, { baseId = base.id,
    definitionId = "barracks", expectedRevision = base.revision,
    component = { kind = "region", role = "facility.footprint",
        region = rectangle(0, 0, 3, 3, 0) } })
T.truthy(barracksResult.ok, "barracks creation")
T.equal(barracksResult.workOrder.operation, "CONSTRUCT",
    "facility creation queues construction")
T.equal(barracksResult.facility.cachedState, "UNDER_CONSTRUCTION",
    "facility remains unusable during construction")
local barracks = barracksResult.facility
T.equal(barracksResult.component, nil,
    "construction does not create functional components")
local barracksWorkZone
for componentId, _ in pairs(barracks.componentIds) do
    local component = PNC.SettlementRepository.GetComponent(componentId)
    if component and component.role == "work.zone" then
        barracksWorkZone = component
    end
end
T.equal(barracksWorkZone, nil,
    "bedroom creation does not add a work zone")
T.equal(PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision,
    component = { kind = "anchor", role = "sleep.bed",
        x = 0, y = 0, z = 0 } }).reason,
    "FACILITY_NOT_BUILT", "components stay locked during construction")
-- Simulate an older save that still contains the universal work-zone record.
local staleWorkZone = { id = "stale_bedroom_work_zone", facilityId = barracks.id,
    kind = "region", role = "work.zone", region = rectangle(0, 4, 0, 4, 0) }
PNC.SettlementRepository.State.components[staleWorkZone.id] = staleWorkZone
barracks.componentIds[staleWorkZone.id] = true
barracks.constructionState = "BUILT"
PNC.FacilityService.RefreshState(barracks)
T.equal(PNC.SettlementRepository.GetComponent(staleWorkZone.id), nil,
    "index rebuild removes an obsolete bedroom work zone")

for index = 1, 4 do
    local bed = PNC.FacilityService.SetComponent({}, {
        facilityId = barracks.id, expectedRevision = barracks.revision,
        component = { kind = "anchor", role = "sleep.bed",
            x = index - 1, y = 0, z = 0,
            targetResolver = "worldObject", objectTag = "bed" },
    })
    T.truthy(bed.ok, "bed assignment " .. tostring(index))
    T.truthy(PNC.FacilityService.FinalizeSetComponent(
        barracks.id, bed.pendingComponent),
        "bed assignment completes construction " .. tostring(index))
end
T.equal(barracks.cachedState, "OPERATIONAL", "barracks state")
local workTarget = PNC.FacilityService.ResolveWorkTarget(barracks)
T.equal(workTarget.role, "facility.footprint",
    "bedroom work target falls back to its room footprint")
T.equal(PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision, component = {
        kind = "anchor", role = "sleep.bed", x = 3, y = 1, z = 0,
    } }).reason, "FACILITY_COMPONENT_LIMIT", "level one bed limit")
local upgrade = PNC.FacilityService.Upgrade({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision })
T.truthy(upgrade.ok, "barracks level two queued")
T.equal(barracks.level, 1, "upgrade waits for construction work")
T.truthy(PNC.FacilityService.FinalizeUpgrade(barracks.id, 2),
    "barracks level two completed")
local fifthBedOrder = PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision, component = {
        kind = "anchor", role = "sleep.bed", x = 3, y = 1, z = 0,
    } })
T.truthy(fifthBedOrder.ok, "fifth bed after upgrade")
T.truthy(PNC.FacilityService.FinalizeSetComponent(
    barracks.id, fifthBedOrder.pendingComponent),
    "fifth bed construction completes")

local researchResult = PNC.FacilityService.Create(player, {
    baseId = base.id, definitionId = "research_facility",
    expectedRevision = base.revision,
    component = { kind = "region", role = "facility.footprint",
        region = rectangle(7, 7, 7, 7) },
    nativeBuild = true,
})
T.truthy(researchResult.ok,
    "research facility accepts a native table construction footprint")
local researchFacility = researchResult.facility
researchFacility.constructionState = "BUILT"
PNC.FacilityService.RefreshState(researchFacility)
local researchStation
for componentId, _ in pairs(researchFacility.componentIds) do
    local component = PNC.SettlementRepository.GetComponent(componentId)
    if component and component.role == "work.research" then
        researchStation = component
    end
end
T.equal(researchStation and researchStation.tileCount, 1,
    "native Log Table occupies one fixed tile")
T.equal(researchStation and researchStation.managedByFacility, true,
    "native Log Table anchor is managed by the facility")
T.equal(researchFacility.workstationPlacement.entityScript, "Base.Log_Table",
    "native Log Table placement is persisted on the facility")
T.equal(researchFacility.cachedState, "OPERATIONAL",
    "one Log Table makes all research lanes operational")
local researchTarget = PNC.FacilityService.ResolveWorkTarget(researchFacility)
T.equal(researchTarget.role, "work.research",
    "native workstation target keeps its physical work role")
T.equal(researchTarget.componentId, researchStation.id,
    "native workstation target points to the managed Log Table anchor")
T.equal(#PNC.FacilityService.ListByCapability(base.id, "work.blueprint"), 1,
    "shared Log Table exposes blueprint activity")
T.equal(#PNC.FacilityService.ListByCapability(base.id, "work.reverse"), 1,
    "shared Log Table exposes reverse-engineering activity")
local refreshedResearch = PNC.FacilityService.ListByCapability(
    base.id, "work.research")
T.equal(#refreshedResearch, 1,
    "native Log Table is independently usable")
T.equal(researchFacility.cachedState, "OPERATIONAL",
    "completed research facility remains operational")
local retiredRoomId = "legacy:workshop.room"
researchFacility.componentIds[retiredRoomId] = true
PNC.SettlementRepository.State.components[retiredRoomId] = {
    id = retiredRoomId, facilityId = researchFacility.id,
    kind = "region", role = "workshop.room",
    region = rectangle(7, 7, 8, 8),
}
PNC.FacilityService.RebuildIndexes()
T.equal(PNC.SettlementRepository.State.components[retiredRoomId], nil,
    "retired room component is removed from saved settlement state")
T.equal(researchFacility.componentIds[retiredRoomId], nil,
    "retired room component is removed from its facility")
local retiredResearchBenchId = "legacy:research.bench"
researchFacility.componentIds[retiredResearchBenchId] = true
PNC.SettlementRepository.State.components[retiredResearchBenchId] = {
    id = retiredResearchBenchId, facilityId = researchFacility.id,
    kind = "anchor", role = "work.blueprint", x = 7, y = 7, z = 0,
}
PNC.FacilityService.RebuildIndexes()
T.equal(PNC.SettlementRepository.State.components[retiredResearchBenchId], nil,
    "retired virtual research bench is removed from saved settlement state")
T.equal(researchFacility.componentIds[retiredResearchBenchId], nil,
    "retired virtual research bench is removed from its facility")

local farmResult = PNC.FacilityService.Create(player, { baseId = base.id,
    definitionId = "farm", expectedRevision = base.revision,
    component = { kind = "region", role = "facility.footprint",
        region = rectangle(5, 5, 6, 6) } })
T.truthy(farmResult.ok, "farm creation")
local farm = farmResult.facility
farm.constructionState = "BUILT"
PNC.FacilityService.RefreshState(farm)
T.equal(#money, 1, "construction no longer consumes player inventory")
T.equal(stockpileInventory:count("Base.Money"), 1,
    "construction materials remain reserved until work completes")
T.equal(stockpileCommits, 0, "facility creation does not commit materials")
T.truthy(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "farm_land",
    regionDelta = rectangle(10, 0, 11, 9) }).ok, "farm territory expansion")
farm.constructionRegion = rectangle(0, 0, 11, 9, 0)
local plotOne = rectangle(0, 0, 3, 3, 0)
local plotOrder = PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        kind = "region", role = "growing.plot", region = plotOne,
    } })
T.truthy(plotOrder.ok and plotOrder.component, "growing plot assigns immediately")

local farmComponentId = plotOrder.component.id
local plotTwo = PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        kind = "region", role = "growing.plot", region = rectangle(4, 0, 7, 3, 0),
    } })
T.truthy(plotTwo.ok, "second growing plot fits level one slots")
T.equal(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        kind = "region", role = "growing.plot", region = rectangle(8, 0, 11, 3, 0),
    } }).reason, "FACILITY_COMPONENT_LIMIT", "farm level plot slots")
T.equal(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        id = farmComponentId, kind = "region", role = "growing.plot",
        region = rectangle(0, 0, 4, 3, 0),
    } }).reason, "GROWING_PLOT_WIDTH_LIMIT", "plot width limit")
T.truthy(PNC.FacilityService.Upgrade({}, { facilityId = farm.id,
    expectedRevision = farm.revision }).ok, "farm level two queued")
T.truthy(PNC.FacilityService.FinalizeUpgrade(farm.id, 2),
    "farm level two completed")
T.truthy(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        id = farmComponentId, kind = "region", role = "growing.plot",
        region = rectangle(0, 0, 3, 3, 0),
    } }).ok, "growing plot edits without reconstruction")
T.equal(farm.constructionState, "BUILT",
    "growing plot edits do not create construction work")
T.equal(PNC.SettlementRepository.GetComponent(farmComponentId).tileCount, 16,
    "growing plot edit commits immediately")
T.equal(farm.constructionState, "BUILT",
    "completed zone reconstruction unlocks facility")

local activity = PNC.FacilityService.AcquireActivity(base.id, "npc_test", "sleep")
T.truthy(activity.ok and activity.target, "activity reservation")
T.truthy(PNC.FacilityReservations.Complete(activity.reservationId),
    "reservation completion")

local stockpile = PNC.StockpileAccessService.Create({}, { baseId = base.id,
    expectedRevision = base.revision, x = 1, y = 1, z = 0, storageId = "storage_test" })
T.truthy(stockpile.ok, "stockpile access node")
T.equal(PNC.StockpileAccessService.HasArrived(stockpile.node, 2, 1, 0), true,
    "radius arrival")

local before = base.revision
T.equal(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = before - 1, requestId = "stale",
    regionDelta = rectangle(10, 5, 10, 5) }).reason,
    "REVISION_CONFLICT", "optimistic revision")
T.equal(base.revision, before, "rejected edit is atomic")

local persisted = PNC.SettlementRepository.Export()
T.equal(persisted.schemaVersion, 1, "persistence schema")
T.equal(persisted.facilities[barracks.id].cachedState, nil,
    "derived facility state is not persisted")
T.equal(persisted.components[farmComponentId].tileCount, nil,
    "derived tile count is not persisted")
T.equal(persisted.reservations, nil, "reservations are runtime only")
T.truthy(PNC.SettlementRepository.Save(), "settlement state saves to ModData")
T.truthy(persistedModData[PNC.SettlementRepository.MODDATA_KEY]
    .bases[base.id], "saved ModData contains base")
PNC.SettlementRepository.State = {
    schemaVersion = 1, bases = {}, facilities = {}, components = {},
    stockpileNodes = {}, zones = {},
}
PNC.SettlementRepository.Loaded = false
T.truthy(PNC.SettlementRepository.Load(true), "settlement state reloads")
T.truthy(PNC.SettlementRepository.GetBase(base.id),
    "base survives a simulated restart")
T.truthy(PNC.SettlementRepository.Import(persisted), "persistence reload")
PNC.FacilityService.RebuildIndexes()
T.equal(PNC.SettlementRepository.GetFacility(barracks.id).cachedState,
    "OPERATIONAL", "derived state rebuilt after load")
T.finish("pnc_settlement_foundation_smoke")

T.finish("pnc_settlement_foundation_smoke")
