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
equal(PNC.BaseService.GetTerritorySummary(base).territoryCapacity, 270,
    "starting territory")
local baseSnapshot = PNC.BaseService.BuildSnapshot(base)
equal(baseSnapshot.geometry.region.levels[0].rows[0][1], 0,
    "authoring snapshot includes canonical footprint")

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
    definitionId = "barracks", expectedRevision = base.revision })
truthy(barracksResult.ok, "barracks creation")
equal(barracksResult.cost.receipts, nil,
    "native material receipts do not enter network result")
equal(barracksResult.cost.costs[1].allocations[1].sourceId, "player",
    "player material source quoted first")
local barracks = barracksResult.facility
truthy(PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision, component = {
        kind = "region", role = "sleep.area", region = rectangle(0, 0, 3, 3, 1),
    } }).ok, "upstairs sleeping area")

for index = 1, 4 do
    local bed = PNC.FacilityService.SetComponent({}, {
        facilityId = barracks.id, expectedRevision = barracks.revision,
        component = { kind = "anchor", role = "sleep.bed",
            x = index - 1, y = 0, z = index % 2,
            targetResolver = "worldObject", objectTag = "bed" },
    })
    truthy(bed.ok, "bed assignment " .. tostring(index))
end
equal(barracks.cachedState, "OPERATIONAL", "barracks state")
local workTarget = PNC.FacilityService.ResolveWorkTarget(barracks)
equal(workTarget.role, "sleep.bed", "facility work prefers an anchor target")
equal(PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision, component = {
        kind = "anchor", role = "sleep.bed", x = 4, y = 0, z = 1,
    } }).reason, "FACILITY_COMPONENT_LIMIT", "level one bed limit")
truthy(PNC.FacilityService.Upgrade({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision }).ok, "barracks level two")
truthy(PNC.FacilityService.SetComponent({}, { facilityId = barracks.id,
    expectedRevision = barracks.revision, component = {
        kind = "anchor", role = "sleep.bed", x = 4, y = 0, z = 1,
    } }).ok, "fifth bed after upgrade")

local farmResult = PNC.FacilityService.Create(player, { baseId = base.id,
    definitionId = "farm", expectedRevision = base.revision })
truthy(farmResult.ok, "farm creation")
equal(farmResult.cost.costs[1].allocations[2].sourceId, "stockpile",
    "stockpile material source quoted")
equal(farmResult.cost.costs[1].allocations[2].quantity, 1,
    "stockpile funds construction remainder")
local farm = farmResult.facility
equal(#money, 0, "facility construction consumes placeholder money")
equal(stockpileInventory:count("Base.Money"), 0,
    "facility construction consumes stockpile remainder")
equal(stockpileCommits, 1, "stockpile material commit")
equal(PNC.FacilityService.Create(player, { baseId = base.id,
    definitionId = "farm", expectedRevision = base.revision }).reason,
    "INSUFFICIENT_BUILD_MATERIALS", "facility material requirement")
truthy(PNC.BaseService.Expand({}, { baseId = base.id,
    expectedRevision = base.revision, requestId = "farm_land",
    regionDelta = rectangle(10, 0, 11, 9) }).ok, "farm territory expansion")
local field93 = rectangle(0, 0, 9, 8, 0)
field93.levels[0].rows[9] = { 0, 2 }
truthy(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        kind = "region", role = "farm.field", region = field93,
    } }).ok, "93 tile farm")

local farmComponentId
for id, _ in pairs(farm.componentIds) do farmComponentId = id end
local field117 = rectangle(0, 0, 11, 8, 0)
field117.levels[0].rows[9] = { 0, 8 }
equal(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        id = farmComponentId, kind = "region", role = "farm.field", region = field117,
    } }).reason, "FACILITY_AREA_TOO_LARGE", "farm level tile limit")
truthy(PNC.FacilityService.Upgrade({}, { facilityId = farm.id,
    expectedRevision = farm.revision }).ok, "farm level two")
truthy(PNC.FacilityService.SetComponent({}, { facilityId = farm.id,
    expectedRevision = farm.revision, component = {
        id = farmComponentId, kind = "region", role = "farm.field", region = field117,
    } }).ok, "farm expansion after upgrade")

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
truthy(PNC.SettlementRepository.Import(persisted), "persistence reload")
PNC.FacilityService.RebuildIndexes()
equal(PNC.SettlementRepository.GetFacility(barracks.id).cachedState,
    "OPERATIONAL", "derived state rebuilt after load")

print("pnc_settlement_foundation_smoke: ok")
