if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal
local Definitions = Internal.Definitions
local Repository = Internal.Repository
local CoreInventory = Internal.CoreInventory
local C = Internal.Constants

function Internal.Preflight(storage, records)
    local required = 0
    for index = 1, #(records or {}) do
        required = required + (tonumber(records[index][C.UNIT_WEIGHT]) or 0)
            * (tonumber(records[index][C.QUANTITY]) or 0)
    end
    local capacity = Definitions.GetCapacity(storage.tier)
    local used = storage.inventory:getWeight()
    local details = {
        requiredWeight = required,
        availableWeight = math.max(0, capacity - used),
        usedWeight = used,
        capacity = capacity,
    }
    if used + required > capacity + 0.000001 then
        Service.Metrics.capacityRejects = Service.Metrics.capacityRejects + 1
        return false, "storage_full", details
    end
    return true, nil, details
end

function Internal.CommitStorage(storage)
    storage.revision = storage.revision + 1
    storage.inventory.maxWeight = Definitions.GetCapacity(storage.tier)
    Repository.MarkDirty()
    if PNC.SupplyIndex and PNC.SupplyIndex.Invalidate then
        PNC.SupplyIndex.Invalidate(storage)
    end
    if PNC.ProvisionScheduler and PNC.ProvisionScheduler.MarkFactionDirty
        and storage.ownerFactionId
    then
        PNC.ProvisionScheduler.MarkFactionDirty(storage.ownerFactionId)
    end
end

function Internal.TransferIntoStorage(storage, source, quantity)
    local preview, reason = source:preview()
    if not preview then return false, reason end
    local ok, _, details = Internal.Preflight(storage, preview)
    if not ok then return false, "storage_full", details end
    ok, reason = CoreInventory.transfer(
        source, storage.inventory, nil, quantity or #preview)
    if not ok then return false, reason, details end
    if source.mirrorShortfall then
        details.liveMirrorShortfall = source.mirrorShortfall
    end
    Internal.CommitStorage(storage)
    Service.Metrics.deposits = Service.Metrics.deposits + 1
    return true, "deposited", details
end

return Internal
