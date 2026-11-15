-- Farming WorkService target resolution and next actionable-tile/input selection.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingWorkAdapter = PNC.FarmingWorkAdapter or {}
PNC.FarmingWorkAdapter.Internal = PNC.FarmingWorkAdapter.Internal or {}

local Internal = PNC.FarmingWorkAdapter.Internal
local Service = PNC.FarmingService
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local FarmingAdapter = PNC.PZFarmingAdapter
local SettlementRepo = PNC.SettlementRepository

function Internal.RecordFor(npcId)
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
end

function Internal.IsCamped(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.IsCamped
        and PNC.HomeDutyService.IsCamped(record) == true
end

function Internal.BaseForTarget(target)
    if not target then return nil end
    if target.baseId and PNC.BaseService and PNC.BaseService.Get then
        local b = PNC.BaseService.Get(target.baseId)
        if b then return b end
    end
    local cid = target.colonyId or target.ownerId
    if cid and PNC.BaseService and PNC.BaseService.GetForColony then
        return PNC.BaseService.GetForColony(cid)
    end
    return nil
end

function Internal.ResolveTarget(order)
    local payload = order and order.payload or nil
    if payload and payload.zoneId and Service and Service.GetZone then
        return Service.GetZone(payload.zoneId), "zone"
    end
    if payload and payload.plotId and SettlementRepo and SettlementRepo.GetComponent then
        local plot = SettlementRepo.GetComponent(payload.plotId)
        local facility = payload.facilityId and SettlementRepo.GetFacility
            and SettlementRepo.GetFacility(payload.facilityId) or nil
        if plot then
            if facility and not plot.baseId then plot.baseId = facility.baseId end
            return plot, "plot", facility
        end
    end
    return nil, nil
end

function Internal.SelectNextTile(target, inspection)
    if not target or not inspection then return nil, nil end
    local policy = Farming.NormalizePolicy(target.policy)
    local tiles = inspection.tiles or {}
    if policy.autoHarvest then
        for _, t in ipairs(tiles) do
            if t.status == "HARVESTABLE" or t.canHarvest == true then return t, "HARVEST" end
        end
    end
    if policy.autoWater then
        for _, t in ipairs(tiles) do
            if t.status == "NEEDS_WATER" or (t.state == "seeded"
                and (tonumber(t.waterLvl) or 0) < 100 and t.canHarvest ~= true)
            then
                return t, "WATER"
            end
        end
    end
    if policy.autoPlant then
        for _, t in ipairs(tiles) do
            if t.status == "EMPTY_FURROW" or t.state == "plow" then return t, "PLANT" end
        end
    end
    if policy.autoPlow then
        for _, t in ipairs(tiles) do
            if t.status == "NEEDS_PLOW" or t.state == "unplowed" then return t, "PLOW" end
        end
    end
    return nil, nil
end

function Internal.RequiredInputSpec(action, target, record, body)
    if not target then return nil, nil end
    if action == "PLANT" then
        local entry = target.desiredCrop and Catalog and Catalog.Get
            and Catalog.Get(target.desiredCrop) or nil
        if not entry then return nil, "UNKNOWN_CROP" end
        if FarmingAdapter and FarmingAdapter.FindSeed
            and FarmingAdapter.FindSeed(record, body, entry)
        then
            return nil, nil
        end
        return { { itemTypes = entry.seedTypes, amount = 1 } }, "seed"
    end
    if action == "WATER" then
        if FarmingAdapter and FarmingAdapter.FindWater
            and FarmingAdapter.FindWater(record, body)
        then
            return nil, nil
        end
        local waterTypes
        if Service and Service.Internal and Service.Internal.StorageWaterTypes then
            local storage = Service.Internal.StorageFor
                and Service.Internal.StorageFor(target) or nil
            waterTypes = storage and Service.Internal.StorageWaterTypes(storage) or {}
        end
        if not waterTypes or #waterTypes < 1 then
            waterTypes = { "Base.WateringCan", "Base.WateringCanFull",
                "Base.BucketWaterFull", "Base.WaterBottleFull" }
        end
        return { { itemTypes = waterTypes, amount = 1 } }, "water"
    end
    return nil, nil
end

return Internal
