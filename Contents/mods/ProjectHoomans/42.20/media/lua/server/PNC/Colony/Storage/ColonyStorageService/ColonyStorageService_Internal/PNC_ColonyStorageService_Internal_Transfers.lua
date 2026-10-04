if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal
local Definitions = Internal.Definitions
local Repository = Internal.Repository
local CoreInventory = Internal.CoreInventory
local C = Internal.Constants

Service.OutputCapacityReservations = Service.OutputCapacityReservations or {}

local function storageKey(storage)
    return tostring(storage and storage.id or storage or "")
end

local function recordWeight(records)
    local required = 0
    for index = 1, #(records or {}) do
        required = required + (tonumber(records[index][C.UNIT_WEIGHT]) or 0)
            * (tonumber(records[index][C.QUANTITY]) or 0)
    end
    return required
end

local function reservedWeight(storage, exceptOwner)
    local key = storageKey(storage)
    local total = 0
    for owner, reservation in pairs(Service.OutputCapacityReservations) do
        if tostring(owner) ~= tostring(exceptOwner or "")
            and reservation.storageKey == key
        then
            total = total + (tonumber(reservation.weight) or 0)
        end
    end
    return total
end

-- Storage revisions are the shared, item-agnostic invalidation signal for
-- every job system. Consumers compare this scalar instead of rescanning
-- inventory rows or checking a particular item type.
function Internal.GetStorageRevision(storage)
    return math.max(0, math.floor(tonumber(storage and storage.revision) or 0))
end

function Internal.HasStorageChanged(storageID, observedRevision)
    local storage = Repository.Get(storageID)
    if not storage then return false, nil end
    return Internal.GetStorageRevision(storage)
        ~= tonumber(observedRevision), storage
end

function Internal.Preflight(storage, records, reservationOwner)
    local required = recordWeight(records)
    local capacity = Definitions.GetCapacity(storage.tier)
    local used = storage.inventory:getWeight()
    local reserved = reservedWeight(storage, reservationOwner)
    local details = {
        requiredWeight = required,
        availableWeight = math.max(0, capacity - used - reserved),
        usedWeight = used,
        capacity = capacity,
        reservedWeight = reserved,
    }
    if used + reserved + required > capacity + 0.000001 then
        Service.Metrics.capacityRejects = Service.Metrics.capacityRejects + 1
        return false, "storage_full", details
    end
    return true, nil, details
end

function Internal.ReserveOutputCapacity(storage, records, owner)
    if not storage or not owner then
        return false, "storage_reservation_invalid"
    end
    local ok, reason, details = Internal.Preflight(storage, records, owner)
    if not ok then return false, reason, details end
    local key = tostring(owner)
    Service.OutputCapacityReservations[key] = {
        storageKey = storageKey(storage),
        weight = details.requiredWeight,
    }
    details.reservationOwner = key
    return true, "reserved", details
end

function Internal.ReleaseOutputCapacity(owner)
    if not owner then return false end
    local key = tostring(owner)
    if not Service.OutputCapacityReservations[key] then return false end
    Service.OutputCapacityReservations[key] = nil
    return true
end

function Internal.CommitStorage(storage)
    storage.revision = Internal.GetStorageRevision(storage) + 1
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

function Internal.TransferIntoStorage(storage, source, quantity, reservationOwner)
    local preview, reason = source:preview()
    if not preview then return false, reason end
    local ok, _, details = Internal.Preflight(storage, preview, reservationOwner)
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
