local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function truthy(value, message)
    if not value then error(message or "expected truthy value") end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua",
    "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    package.path,
}, ";")

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
truthy(stockpileInventory:add(moneyItem()), "stockpile placeholder money")
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
truthy(created.ok, "base creation")
local base = created.base
PNC.ResearchService = { Queries = { HasTechnology = function(_, id)
    return id == "hq:2"
end } }
equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 270,
    "starting territory")
local baseSnapshot = PNC.BaseService.BuildSnapshot(base)
equal(baseSnapshot.geometry.region.levels[0].rows[0][1], 0,
    "authoring snapshot includes canonical footprint")
local researchLevel = PNC.FacilityDefinitions.GetLevel(
    "research_facility", 1)
equal(researchLevel.componentLimits["research.room"], nil,
    "research room is not a functional component")
equal(researchLevel.componentLimits["work.research"].minCount, 1,
    "research station remains a research component")
equal(researchLevel.componentLimits["work.blueprint"].minCount, 1,
    "architect bench is required for blueprint study")
equal(researchLevel.componentLimits["work.reverse"].minCount, 1,
    "lab is required for reverse engineering")
local workshopLevel = PNC.FacilityDefinitions.GetLevel("workshop", 1)
equal(workshopLevel.componentLimits["workshop.room"], nil,
    "workshop room is not a functional component")
equal(workshopLevel.componentLimits["work.craft"].minCount, 1,
    "craft station remains a workshop component")
equal(workshopLevel.componentLimits["work.disassemble"].minCount, 1,
    "disassembly station remains a workshop component")
local waterLevel = PNC.FacilityDefinitions.GetLevel("water_collector", 1)
equal(waterLevel.componentLimits["water.spigot"].kind, "anchor",
    "water spigot is a physical interaction component")
equal(waterLevel.componentLimits["water.tank"].kind, "abstract",
    "water tanks use reusable abstract components")
equal(waterLevel.componentLimits["water.tank"].maxCount, 4,
    "water level one permits four tanks")
local waterLevelTen = PNC.FacilityDefinitions.GetLevel("water_collector", 10)
equal(waterLevelTen.componentLimits["water.catcher"].maxCount, 40,
    "water module limits scale through level ten")

local playerZoneConflict = PNC.BaseService.Create({}, {
    colonyId = "community_other", factionId = "faction_test",
    region = rectangle(5, 5, 7, 7), requestId = "player_zone_conflict",
})
equal(playerZoneConflict.reason, "PLAYER_ZONE_OCCUPIED",
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
equal(npcBaseConflict.reason, "NPC_BASE_OCCUPIED",
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
equal(safehouseConflict.reason, "PLAYER_ZONE_OCCUPIED",
    "new base cannot overlap a vanilla safehouse")
SafeHouse = nil

for index = 1, 13 do
    local built = PNC.BaseService.BuildBarricade({}, {
        baseId = base.id, expectedRevision = base.revision,
        requestId = "barricade_" .. tostring(index),
    })
    truthy(built.ok, "barricade " .. tostring(index))
end
equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 400,
    "HQ1 capped territory")
equal(PNC.BaseService.BuildBarricade({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "barricade_rejected" }).reason,
    "HQ_TERRITORY_LIMIT", "barricade hard limit")

local upgradedHQ = PNC.BaseService.UpgradeHQ({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "hq2" })
truthy(upgradedHQ.ok, "HQ upgrade")
equal(PNC.BaseService.UpgradeHQ({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "hq3_locked" }).reason,
    "TECHNOLOGY_REQUIRED", "HQ upgrade requires its researched capability")
equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 400,
    "HQ upgrade grants no territory")
truthy(PNC.BaseService.BuildBarricade({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "barricade_14" }).ok,
    "post-upgrade barricade")
equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 410,
    "post-upgrade territory")

local expanded = PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "expand",
    regionDelta = rectangle(10, 0, 10, 4) })
truthy(expanded.ok, "connected expansion")
equal(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "remote",
    regionDelta = rectangle(20, 20, 21, 21) }).reason,
    "BASE_DISCONNECTED", "remote island")
equal(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "diagonal",
    regionDelta = rectangle(11, 5, 11, 5) }).reason,
    "BASE_DISCONNECTED", "diagonal-only expansion")

local barracksResult = PNC.FacilityService.Create(player, { baseId = base.id,
    definitionId = "barracks", expectedRevision = base.revision,
    component = { kind = "region", role = "sleep.area",
        region = rectangle(0, 0, 3, 3, 0) } })
truthy(barracksResult.ok, "barracks creation")
equal(barracksResult.workOrder.operation, "CONSTRUCT",
    "facility creation queues construction")
equal(barracksResult.facility.cachedState, "UNDER_CONSTRUCTION",
    "facility remains unusable during construction")
local barracks = barracksResult.facility
equal(barracksResult.component, nil,
    "construction does not create functional components")
equal(PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision,
    component = { kind = "anchor", role = "sleep.bed",
        x = 0, y = 0, z = 0 } }).reason,
    "FACILITY_NOT_BUILT", "components stay locked during construction")
barracks.constructionState = "BUILT"
PNC.FacilityService.RefreshState(barracks)
local roomOrder = PNC.FacilityService.SetComponent({}, {
    facilityId = barracks.id, expectedRevision = barracks.revision,
    component = { kind = "region", role = "sleep.area",
        region = rectangle(0, 0, 3, 3, 0) },
})
truthy(roomOrder.ok, "room assignment queues construction")
truthy(PNC.FacilityService.FinalizeSetComponent(
    barracks.id, roomOrder.pendingComponent),
    "room assignment completes construction")

for index = 1, 4 do
    local bed = PNC.FacilityService.SetComponent({}, {
        facilityId = barracks.id, expectedRevision = barracks.revision,
        component = { kind = "anchor", role = "sleep.bed",
            x = index - 1, y = 0, z = 0,
            targetResolver = "worldObject", objectTag = "bed" },
    })
    truthy(bed.ok, "bed assignment " .. tostring(index))
    truthy(PNC.FacilityService.FinalizeSetComponent(
        barracks.id, bed.pendingComponent),
        "bed assignment completes construction " .. tostring(index))
end
equal(barracks.cachedState, "OPERATIONAL", "barracks state")
local workTarget = PNC.FacilityService.ResolveWorkTarget(barracks)
equal(workTarget.role, "sleep.bed", "facility work prefers an anchor target")
equal(PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision, component = {
        kind = "anchor", role = "sleep.bed", x = 3, y = 1, z = 0,
    } }).reason, "FACILITY_COMPONENT_LIMIT", "level one bed limit")
local upgrade = PNC.FacilityService.Upgrade({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision })
truthy(upgrade.ok, "barracks level two queued")
equal(barracks.level, 1, "upgrade waits for construction work")
truthy(PNC.FacilityService.FinalizeUpgrade(barracks.id, 2),
    "barracks level two completed")
local fifthBedOrder = PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision, component = {
        kind = "anchor", role = "sleep.bed", x = 3, y = 1, z = 0,
    } })
truthy(fifthBedOrder.ok, "fifth bed after upgrade")
truthy(PNC.FacilityService.FinalizeSetComponent(
    barracks.id, fifthBedOrder.pendingComponent),
    "fifth bed construction completes")

local researchResult = PNC.FacilityService.Create(player, {
    baseId = base.id, definitionId = "research_facility",
    expectedRevision = base.revision,
    component = { kind = "region", role = "facility.footprint",
        region = rectangle(7, 7, 8, 8) },
})
truthy(researchResult.ok,
    "research facility accepts a non-component construction footprint")
local researchFacility = researchResult.facility
researchFacility.constructionState = "BUILT"
PNC.FacilityService.RefreshState(researchFacility)
local stationOrder = PNC.FacilityService.SetComponent({}, {
    facilityId = researchFacility.id,
    expectedRevision = researchFacility.revision,
    component = { kind = "anchor", role = "work.research",
        x = 7, y = 7, z = 0 },
})
truthy(stationOrder.ok, "research station assignment")
truthy(PNC.FacilityService.FinalizeSetComponent(
    researchFacility.id, stationOrder.pendingComponent),
    "research station construction completes")
equal(PNC.FacilityService.SetComponent({}, {
    facilityId = researchFacility.id,
    expectedRevision = researchFacility.revision,
    component = { kind = "anchor", role = "work.research",
        x = 6, y = 7, z = 0 },
}).reason, "OUTSIDE_FACILITY",
    "station assignment stays inside its facility footprint")
local researchStation
for componentId, _ in pairs(researchFacility.componentIds) do
    local component = PNC.SettlementRepository.GetComponent(componentId)
    if component and component.role == "work.research" then
        researchStation = component
    end
end
equal(researchStation and researchStation.tileCount, 1,
    "ordinary facility anchors occupy one fixed tile")
equal(researchFacility.cachedState, "NEEDS_ASSIGNMENT",
    "research facility remains incomplete without architect bench and lab")
local architectOrder = PNC.FacilityService.SetComponent({}, {
    facilityId = researchFacility.id,
    expectedRevision = researchFacility.revision,
    component = { kind = "anchor", role = "work.blueprint",
        x = 8, y = 7, z = 0 },
})
truthy(architectOrder.ok, "architect bench assignment")
truthy(PNC.FacilityService.FinalizeSetComponent(
    researchFacility.id, architectOrder.pendingComponent),
    "architect bench construction completes")
local laboratoryOrder = PNC.FacilityService.SetComponent({}, {
    facilityId = researchFacility.id,
    expectedRevision = researchFacility.revision,
    component = { kind = "anchor", role = "work.reverse",
        x = 7, y = 8, z = 0 },
})
truthy(laboratoryOrder.ok, "laboratory assignment")
truthy(PNC.FacilityService.FinalizeSetComponent(
    researchFacility.id, laboratoryOrder.pendingComponent),
    "laboratory construction completes")
equal(researchFacility.cachedState, "OPERATIONAL",
    "all three research lanes complete the facility")
equal(#PNC.FacilityService.ListByCapability(base.id, "work.blueprint"), 1,
    "architect bench exposes blueprint activity")
equal(#PNC.FacilityService.ListByCapability(base.id, "work.reverse"), 1,
    "laboratory exposes reverse-engineering activity")
local refreshedResearch = PNC.FacilityService.ListByCapability(
    base.id, "work.research")
equal(#refreshedResearch, 1,
    "assigned research station is independently usable")
equal(researchFacility.cachedState, "OPERATIONAL",
    "completed research facility remains operational")
local retiredRoomId = "legacy:workshop.room"
researchFacility.componentIds[retiredRoomId] = true
PNC.SettlementRepository.State.components[retiredRoomId] = {
    id = retiredRoomId, facilityId = researchFacility.id,
    kind = "region", role = "workshop.room",
    region = rectangle(7, 7, 8, 8),
}
PNC.FacilityService.RebuildIndexes()
equal(PNC.SettlementRepository.State.components[retiredRoomId], nil,
    "retired room component is removed from saved settlement state")
equal(researchFacility.componentIds[retiredRoomId], nil,
    "retired room component is removed from its facility")

local farmResult = PNC.FacilityService.Create(player, { baseId = base.id,
    definitionId = "farm", expectedRevision = base.revision,
    component = { kind = "region", role = "farm.field",
        region = rectangle(5, 5, 6, 6) } })
truthy(farmResult.ok, "farm creation")
local farm = farmResult.facility
farm.constructionState = "BUILT"
PNC.FacilityService.RefreshState(farm)
equal(#money, 1, "construction no longer consumes player inventory")
equal(stockpileInventory:count("Base.Money"), 1,
    "construction materials remain reserved until work completes")
equal(stockpileCommits, 0, "facility creation does not commit materials")
truthy(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "farm_land",
    regionDelta = rectangle(10, 0, 11, 9) }).ok, "farm territory expansion")
farm.constructionRegion = rectangle(0, 0, 11, 9, 0)
local field93 = rectangle(0, 0, 9, 8, 0)
field93.levels[0].rows[9] = { 0, 2 }
local field93Order = PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        kind = "region", role = "farm.field", region = field93,
    } })
truthy(field93Order.ok, "93 tile farm")
truthy(PNC.FacilityService.FinalizeSetComponent(
    farm.id, field93Order.pendingComponent),
    "93 tile farm construction completes")

local farmComponentId
for id, _ in pairs(farm.componentIds) do farmComponentId = id end
local field117 = rectangle(0, 0, 11, 8, 0)
field117.levels[0].rows[9] = { 0, 8 }
equal(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        id = farmComponentId, kind = "region", role = "farm.field", region = field117,
    } }).reason, "FACILITY_AREA_TOO_LARGE", "farm level tile limit")
truthy(PNC.FacilityService.Upgrade({}, { facilityId = farm.id,
    expectedRevision = farm.revision }).ok, "farm level two queued")
truthy(PNC.FacilityService.FinalizeUpgrade(farm.id, 2),
    "farm level two completed")
truthy(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        id = farmComponentId, kind = "region", role = "farm.field", region = field117,
    } }).ok, "farm expansion queues reconstruction after upgrade")
equal(farm.constructionState, "RECONSTRUCTING",
    "zone edit waits for constructor work")
equal(PNC.SettlementRepository.GetComponent(farmComponentId).tileCount, 93,
    "old zone stays canonical until reconstruction completes")
truthy(PNC.FacilityService.FinalizeSetComponent(farm.id,
    farm.pendingTestChange.component), "finish reconstructed zone")
equal(PNC.SettlementRepository.GetComponent(farmComponentId).tileCount, 117,
    "new zone commits after constructor work")
equal(farm.constructionState, "BUILT",
    "completed zone reconstruction unlocks facility")

local activity = PNC.FacilityService.AcquireActivity(base.id, "npc_test", "sleep")
truthy(activity.ok and activity.target, "activity reservation")
truthy(PNC.FacilityReservations.Complete(activity.reservationId),
    "reservation completion")

local stockpile = PNC.StockpileAccessService.Create({}, { baseId = base.id,
    expectedRevision = base.revision, x = 1, y = 1, z = 0, storageId = "storage_test" })
truthy(stockpile.ok, "stockpile access node")
equal(PNC.StockpileAccessService.HasArrived(stockpile.node, 2, 1, 0), true,
    "radius arrival")

local before = base.revision
equal(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = before - 1, requestId = "stale",
    regionDelta = rectangle(10, 5, 10, 5) }).reason,
    "REVISION_CONFLICT", "optimistic revision")
equal(base.revision, before, "rejected edit is atomic")

local persisted = PNC.SettlementRepository.Export()
equal(persisted.schemaVersion, 1, "persistence schema")
equal(persisted.facilities[barracks.id].cachedState, nil,
    "derived facility state is not persisted")
equal(persisted.components[farmComponentId].tileCount, nil,
    "derived tile count is not persisted")
equal(persisted.reservations, nil, "reservations are runtime only")
truthy(PNC.SettlementRepository.Save(), "settlement state saves to ModData")
truthy(persistedModData[PNC.SettlementRepository.MODDATA_KEY]
    .bases[base.id], "saved ModData contains base")
PNC.SettlementRepository.State = {
    schemaVersion = 1, bases = {}, facilities = {}, components = {},
    stockpileNodes = {}, zones = {},
}
PNC.SettlementRepository.Loaded = false
truthy(PNC.SettlementRepository.Load(true), "settlement state reloads")
truthy(PNC.SettlementRepository.GetBase(base.id),
    "base survives a simulated restart")
truthy(PNC.SettlementRepository.Import(persisted), "persistence reload")
PNC.FacilityService.RebuildIndexes()
equal(PNC.SettlementRepository.GetFacility(barracks.id).cachedState,
    "OPERATIONAL", "derived state rebuilt after load")

print("pnc_settlement_foundation_smoke: ok")
