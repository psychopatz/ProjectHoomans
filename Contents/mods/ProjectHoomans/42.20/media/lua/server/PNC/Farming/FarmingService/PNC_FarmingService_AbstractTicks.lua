-- Abstract farming progression (plow -> seed -> water -> growth -> harvest to storage).

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
local Service = PNC.FarmingService
local Internal = Service.Internal
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local Adapter = PNC.PZFarmingAdapter
local facilityFor = Internal.FacilityFor
local plotFor = Internal.PlotFor

local function facilityRef(target)
    return (target.facilityId and facilityFor and facilityFor(target.facilityId))
        or { id = target.id, baseId = target.baseId, colonyId = target.colonyId,
             factionId = target.factionId }
end

local function resolveAbstractTarget(record, lease, explicitTarget)
    if type(explicitTarget) == "table" then return explicitTarget end
    local payload = lease and lease.payload or nil
    if payload and payload.zoneId and Service.GetZone then
        return Service.GetZone(payload.zoneId)
    end
    local runtime = record and record.runtime and record.runtime.facilityActivity or nil
    local fid = (payload and payload.facilityId) or (lease and lease.facilityId)
        or (runtime and runtime.facilityId)
    local pid = (payload and payload.plotId) or (lease and lease.componentId)
        or (runtime and runtime.componentId)
    local facility = fid and facilityFor and facilityFor(fid) or nil
    return facility and plotFor and plotFor(facility, pid) or nil
end

local function advanceAbstractGrowth(target, entry, now)
    local stepMs = tonumber(target.abstractGrowthStepMs)
        or math.max(5000, math.floor((tonumber(entry.timeToGrow) or 20) * 1000))
    local targetLevel = tonumber(entry.harvestLevel or entry.fullGrown) or 4
    for _, tile in ipairs(Internal.EnsureAbstractTiles(target)) do
        if tile.state == "seeded" and not tile.canHarvest
            and (tonumber(tile.waterLvl) or 0) > 0
            and now - (tonumber(tile.lastGrowAt) or 0) >= stepMs
        then
            tile.lastGrowAt = now
            tile.nbOfGrow = (tonumber(tile.nbOfGrow) or 0) + 1
            if tile.nbOfGrow >= targetLevel then tile.canHarvest = true end
        end
    end
end

local function consumeAbstractSeed(record, target, entry, runtime)
    local supply = PNC.SupplyInventory
    if Adapter and Adapter.FindSeed and supply and supply.RemoveCoreItemIds then
        local itemId = Adapter.FindSeed(record, nil, entry)
        if itemId and supply.RemoveCoreItemIds(record, { itemId }, "farming_seed") then
            return true
        end
    end
    if not Internal.RetrieveMaterial then return false, "SEED_MATERIAL_MISSING" end
    local ok, reason = Internal.RetrieveMaterial(
        record, facilityRef(target), entry.seedTypes, runtime or {})
    if ok and Adapter and Adapter.FindSeed and supply and supply.RemoveCoreItemIds then
        local itemId = Adapter.FindSeed(record, nil, entry)
        if itemId then supply.RemoveCoreItemIds(record, { itemId }, "farming_seed") end
    end
    return ok, reason
end

local function consumeAbstractWater(record, target, runtime)
    if Adapter and Adapter.FindWater and Adapter.FindWater(record, nil) then
        return true
    end
    local ref = facilityRef(target)
    local storage = Internal.StorageFor and Internal.StorageFor(ref) or nil
    if storage and Internal.StorageWaterTypes and Internal.RetrieveMaterial then
        local types = Internal.StorageWaterTypes(storage)
        if #types > 0 then
            return Internal.RetrieveMaterial(record, ref, types, runtime or {})
        end
    end
    return false, "WATER_MATERIAL_MISSING"
end

local function depositAbstractHarvest(record, target, entry)
    local cropType = tostring(entry.vegetableName or entry.typeOfSeed or "Cabbages")
    if not string.find(cropType, "%.") then cropType = "Base." .. cropType end
    local qty = math.max(1, math.floor(tonumber(target.abstractHarvestYield) or 2))
    local items = { { fullType = cropType, quantity = qty } }
    if PNC.WorkOutputService and PNC.WorkOutputService.FlushAbstractDelivery then
        local effect = PNC.WorkOutputService.EnsureOutputEffect(target, "FARMING", {})
        effect.state = "PENDING"
        return PNC.WorkOutputService.FlushAbstractDelivery(target, record, effect, items, {
            deliveryTarget = "AUTO", fallbackToInventory = true,
            activityTag = "farming", reason = "farming_harvest",
        })
    end
    return true, "ABSTRACT_HARVESTED"
end

local function setRuntimeOp(runtime, op)
    if runtime then runtime.phase, runtime.lastFarmingOperation = "WORKING", op end
end

---Advances abstract farming state (plow -> seed -> water -> grow -> harvest to storage).
function Service.TickAbstract(record, lease, explicitTarget)
    local runtime = record and record.runtime and record.runtime.facilityActivity or nil
    local target = resolveAbstractTarget(record, lease, explicitTarget)
    if not target then
        if runtime then runtime.phase, runtime.lastFarmingReason = "WAITING_FOR_WORLD", "FARM_TARGET_MISSING" end
        return false, false, "FARM_TARGET_MISSING"
    end
    local entry = target.desiredCrop and Catalog and Catalog.Get and Catalog.Get(target.desiredCrop) or nil
    if not entry then return false, false, "NO_CROP_ASSIGNED" end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    advanceAbstractGrowth(target, entry, now)
    local policy = Farming.NormalizePolicy(target.policy)
    for _, tile in ipairs(Internal.EnsureAbstractTiles(target)) do
        if policy.autoHarvest and tile.state == "seeded" and tile.canHarvest then
            local ok, rsn = depositAbstractHarvest(record, target, entry)
            if not ok then return false, false, rsn or "HARVEST_STORAGE_FAILED" end
            if entry.growBack then
                tile.canHarvest = false
                tile.nbOfGrow = math.max(1, (tonumber(tile.nbOfGrow) or 2) - 2)
            else
                tile.state, tile.typeOfSeed, tile.canHarvest, tile.nbOfGrow, tile.waterLvl = "plow", nil, false, 0, 0
            end
            setRuntimeOp(runtime, "HARVESTED")
            return true, not Internal.HasActionableAbstractTiles(target), "HARVESTED"
        elseif policy.autoPlant and tile.state == "plow" then
            local ok, rsn = consumeAbstractSeed(record, target, entry, runtime)
            if not ok then return false, false, rsn or "SEED_MATERIAL_MISSING" end
            tile.state, tile.typeOfSeed, tile.nbOfGrow, tile.canHarvest = "seeded", entry.typeOfSeed, 0, false
            tile.waterLvl, tile.lastGrowAt = tonumber(entry.waterLvl) or 70, now
            setRuntimeOp(runtime, "PLANTED")
            return true, not Internal.HasActionableAbstractTiles(target), "PLANTED"
        elseif policy.autoWater and tile.state == "seeded" and (tonumber(tile.waterLvl) or 0) < 100 then
            local ok, rsn = consumeAbstractWater(record, target, runtime)
            if not ok then return false, false, rsn or "WATER_MATERIAL_MISSING" end
            tile.waterLvl = 100
            setRuntimeOp(runtime, "WATERED")
            return true, not Internal.HasActionableAbstractTiles(target), "WATERED"
        elseif policy.autoPlow and tile.state == "unplowed" then
            tile.state = "plow"
            setRuntimeOp(runtime, "PLOWED")
            return true, not Internal.HasActionableAbstractTiles(target), "PLOWED"
        end
    end
    if runtime then runtime.phase, runtime.lastFarmingReason = "WAITING_FOR_CROP_STATE", "NO_ACTION" end
    return true, true, "FARMING_NO_ACTIONABLE_WORK"
end

return Service
