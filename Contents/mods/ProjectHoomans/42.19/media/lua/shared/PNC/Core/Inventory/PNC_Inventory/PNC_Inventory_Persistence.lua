-- PNC inventory persistence facade.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Core = PNC.Core

require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_DeltaCodec"

function Inventory.Serialize(record)
    local inv = Inventory.EnsureRecordInventory(record)
    local payload
    if not inv then return nil end
    if inv.deltaMode == "template_plus_delta" then
        return {
            revision = inv.revision,
            deltaMode = inv.deltaMode,
            maxWeight = inv.maxWeight,
            cachedWeight = inv.cachedWeight,
            template = {
                archetypeID = record.archetypeID,
                seed = record.identitySeed,
                generatorVersion = PNC.Const and PNC.Const.GENERATOR_VERSION or 1,
            },
            delta = Internal.buildCompactDelta(record, inv),
            summary = Inventory.BuildSummaryPayload(record),
        }
    end
    payload = Inventory.BuildFullPayload(record)
    payload.maxWeight = inv.maxWeight
    payload.cachedWeight = inv.cachedWeight
    return payload
end

function Inventory.Deserialize(record, rawInventory)
    local inv
    if not record then return nil end
    if type(rawInventory) ~= "table" then
        return Inventory.CreateFromTemplate(record)
    end
    if Internal.normalizeString(rawInventory.deltaMode) == "template_plus_delta"
        and not rawInventory.items
    then
        inv = Inventory.CreateFromTemplate(record, { keepRevision = rawInventory.revision })
        inv.deltaMode = "template_plus_delta"
        inv.maxWeight = tonumber(rawInventory.maxWeight) or inv.maxWeight
        inv.cachedWeight = tonumber(rawInventory.cachedWeight) or inv.cachedWeight
        Internal.applySavedDelta(record, inv, rawInventory.delta)
        Inventory.SyncEquipmentFromInventory(record)
        Inventory.RebuildCaches(record)
        return inv
    end
    record.inventory = {
        revision = tonumber(rawInventory.revision) or 0,
        deltaMode = "template_plus_delta",
        cachedWeight = tonumber(rawInventory.cachedWeight) or 0,
        maxWeight = Internal.buildBaseCarryWeight(record),
        rootMaxWeight = Internal.buildBaseCarryWeight(record),
        template = type(rawInventory.template) == "table"
            and Core.DeepCopy(rawInventory.template)
            or {
                archetypeID = record.archetypeID,
                seed = record.identitySeed,
            },
        equipped = type(rawInventory.equipped) == "table" and Core.DeepCopy(rawInventory.equipped) or {},
        worn = type(rawInventory.worn) == "table" and Core.DeepCopy(rawInventory.worn) or {},
        attached = type(rawInventory.attached) == "table" and Core.DeepCopy(rawInventory.attached) or {},
        items = type(rawInventory.items) == "table" and Core.DeepCopy(rawInventory.items) or {},
        containers = type(rawInventory.containers) == "table" and Core.DeepCopy(rawInventory.containers) or {},
    }
    inv = Inventory.EnsureRecordInventory(record)
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    Internal.refreshNextItemSerial(record, inv)
    return inv
end
