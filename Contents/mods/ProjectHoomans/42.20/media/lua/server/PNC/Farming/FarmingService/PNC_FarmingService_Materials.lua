-- Farming material acquisition and per-tile operation selection.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
local Service = PNC.FarmingService
local Internal = Service.Internal
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local Adapter = PNC.PZFarmingAdapter
local baseFor = Internal.BaseFor

local function itemFullType(item)
    local direct = tostring(item and (item.fullType or item.type) or "")
    if direct ~= "" then return direct end
    if item and type(item.getFullType) == "function" then
        local ok, fullType = pcall(item.getFullType, item)
        fullType = ok and tostring(fullType or "") or ""
        if fullType ~= "" then return fullType end
    end
    return nil
end

local function reservationItemFullType(reservation)
    local requirement = reservation and reservation.requirements
        and reservation.requirements[1] or nil
    local fullType = tostring(requirement and requirement.selectedType or "")
    return fullType ~= "" and fullType or nil
end

local function storageFor(facility)
    local base = baseFor(facility)
    if not base or not PNC.ColonyStorageRepository
        or not PNC.ColonyStorageRepository.GetPrimary
    then return nil end
    return PNC.ColonyStorageRepository.GetPrimary(base.factionId, base.colonyId)
end

local function retrieveMaterial(record, facility, itemTypes, runtime)
    if runtime and runtime.lastMaterialAttemptAt
        and PNC.Core.Now() - runtime.lastMaterialAttemptAt < 10000
    then return false, "MATERIAL_RETRY_DELAY" end
    if not record or not facility or not PNC.ColonyStorageService
        or not PNC.ColonyStorageService.ReserveProductionMaterials
        or not PNC.ColonyStorageService.CollectProductionReservation
    then return false, "MATERIAL_RETRIEVAL_UNAVAILABLE" end
    local storage = storageFor(facility)
    if not storage then return false, "STORAGE_NOT_FOUND" end
    runtime.lastMaterialAttemptAt = PNC.Core.Now()
    local reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        storage.id, {{ itemTypes = itemTypes, amount = 1 }},
        "farming:" .. tostring(facility.id))
    if not reservation then return false, reason or "MATERIALS_NOT_AVAILABLE" end
    local ok, details = PNC.ColonyStorageService.CollectProductionReservation(
        reservation.id, "farming:" .. tostring(facility.id), "FARMING",
        storage.id, record)
    if not ok then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return false, details or "MATERIAL_RETRIEVAL_FAILED"
    end
    if runtime then
        runtime.activityItemFullType = reservationItemFullType(reservation)
    end
    return true, "MATERIAL_RETRIEVED"
end

local function ensureSeed(record, facility, entry, runtime)
    local itemID, item = Adapter.FindSeed(record, nil, entry)
    if itemID then
        runtime.activityItemFullType = itemFullType(item)
        return true
    end
    return retrieveMaterial(record, facility, entry.seedTypes, runtime)
end

local function storageWaterTypes(storage)
    local output, seen = {}, {}
    local inventory = storage and storage.inventory
    local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
    for _, itemRecord in ipairs(inventory and inventory.records or {}) do
        local item = CoreInventory.decodeItem(itemRecord)
        local fullType = item and item.getFullType and item:getFullType() or nil
        if fullType and Adapter.IsWaterItem and Adapter.IsWaterItem(item)
            and not seen[fullType]
        then
            seen[fullType] = true
            output[#output + 1] = fullType
        end
    end
    return output
end

local function ensureWater(record, facility, runtime, body)
    local water = Adapter.FindWater(record, body)
    if water then
        runtime.activityItemFullType = itemFullType(water.item)
        return true
    end
    local storage = storageFor(facility)
    local types = storageWaterTypes(storage)
    if #types <= 0 then return false, "WATER_MATERIAL_MISSING" end
    return retrieveMaterial(record, facility, types, runtime)
end

local function operation(record, body, facility, plot, runtime, tile, inspection)
    local policy = Farming.NormalizePolicy(plot.policy)
    local desired = plot.desiredCrop
    if not desired then return false, "NO_CROP_ASSIGNED" end
    local entry = Catalog.Get(desired)
    if not entry then return false, "UNKNOWN_CROP" end
    if policy.autoHarvest and tile.status == "HARVESTABLE" then
        return Adapter.Harvest(record, body, tile)
    end
    local tileKey = tostring(tile.x) .. ":" .. tostring(tile.y) .. ":" .. tostring(tile.z)
    if policy.autoPlant and tile.status == "EMPTY_FURROW"
        and (not runtime.harvestedTiles or runtime.harvestedTiles[tileKey] ~= true
            or policy.autoReplant)
        and (inspection.empty > 0)
    then
        local supplied, reason = ensureSeed(record, facility, entry, runtime)
        if not supplied then return false, reason end
        return Adapter.Plant(record, body, plot, tile, desired)
    end
    if policy.autoWater and tile.status == "NEEDS_WATER" then
        local supplied, reason = ensureWater(record, facility, runtime, body)
        if not supplied then return false, reason end
        return Adapter.Water(record, body, tile)
    end
    return false, "NO_ACTION"
end

Internal.StorageFor = storageFor
Internal.RetrieveMaterial = retrieveMaterial
Internal.EnsureSeed = ensureSeed
Internal.StorageWaterTypes = storageWaterTypes
Internal.EnsureWater = ensureWater
Internal.Operation = operation

return Internal
