--[[
    PNC Inventory Payloads
    Compact summaries and full/incremental network representations.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Core = PNC.Core

function Inventory.BuildSummaryPayload(record)
    local raw = record and record.persistedInventory or nil
    local persistedSummary = raw and (raw.summary or raw.inventorySummary) or nil
    local persistedGenerator = raw and raw.template and tonumber(raw.template.generatorVersion) or nil
    local currentGenerator = PNC.Const and tonumber(PNC.Const.GENERATOR_VERSION) or 1
    local inv
    if type(record and record.inventory) ~= "table"
        and type(persistedSummary) == "table"
        and persistedGenerator == currentGenerator
    then
        return Core.DeepCopy(persistedSummary)
    end
    inv = Inventory.EnsureRecordInventory(record)
    if not inv then
        return nil
    end
    local encumbrance = Inventory.GetEncumbranceState(record)
    return {
        revision = inv.revision,
        usedWeight = tonumber(inv.cachedWeight) or 0,
        maxWeight = tonumber(inv.maxWeight) or 0,
        remainingWeight = tonumber(inv.remainingWeight) or 0,
        encumbranceRatio = encumbrance and encumbrance.ratio or 0,
        encumbranceLevel = encumbrance and encumbrance.level or "normal",
        itemCount = tonumber(inv.itemCount) or Internal.countMapEntries(inv.items),
        containerCount = tonumber(inv.containerCount) or Internal.countMapEntries(inv.containers),
        signature = inv.signature,
        persistenceMode = inv.persistenceMode,
    }
end

function Inventory.BuildFullPayload(record)
    local inv = Inventory.EnsureRecordInventory(record)
    local items = {}
    local containers = {}
    local id
    if not inv then
        return nil
    end
    for id, _ in pairs(inv.items or {}) do
        items[id] = Internal.itemToPayload(inv.items[id])
    end
    for id, _ in pairs(inv.containers or {}) do
        containers[id] = {
            maxWeight = tonumber(inv.containers[id].maxWeight) or 0,
            items = Internal.shallowArrayCopy(inv.containers[id].items),
        }
    end
    return {
        revision = inv.revision,
        persistenceMode = inv.persistenceMode,
        template = Core.DeepCopy(inv.template or {}),
        summary = Inventory.BuildSummaryPayload(record),
        equipped = Core.DeepCopy(inv.equipped or {}),
        worn = Core.DeepCopy(inv.worn or {}),
        attached = Core.DeepCopy(inv.attached or {}),
        items = items,
        containers = containers,
    }
end

function Inventory.BuildDeltaPayload(record, sinceRevision)
    local runtime = Internal.getRuntimeState(record)
    local inv = Inventory.EnsureRecordInventory(record)
    local payload = {}
    local entry
    local i
    sinceRevision = tonumber(sinceRevision) or 0
    if not inv or not runtime or type(runtime.opLog) ~= "table" then
        return nil
    end
    if sinceRevision > (tonumber(inv.revision) or 0) then
        return {
            npcId = record.id,
            fromRevision = sinceRevision,
            inventoryRevision = inv.revision,
            fullRequired = true,
        }
    end
    if sinceRevision == (tonumber(inv.revision) or 0) then
        return {
            npcId = record.id,
            fromRevision = sinceRevision,
            inventoryRevision = inv.revision,
            ops = {},
            summary = Inventory.BuildSummaryPayload(record),
            equipment = Core.DeepCopy(record.equipment or {}),
        }
    end
    if #runtime.opLog <= 0
        or (tonumber(runtime.opLog[1] and runtime.opLog[1].revision) or 0) > (sinceRevision + 1)
    then
        return {
            npcId = record.id,
            fromRevision = sinceRevision,
            inventoryRevision = inv.revision,
            fullRequired = true,
        }
    end
    local expectedRevision = sinceRevision
    for i = 1, #runtime.opLog do
        entry = runtime.opLog[i]
        if entry and (tonumber(entry.revision) or 0) > sinceRevision then
            if tonumber(entry.revision) ~= expectedRevision
                and tonumber(entry.revision) ~= expectedRevision + 1
            then
                return {
                    npcId = record.id,
                    fromRevision = sinceRevision,
                    inventoryRevision = inv.revision,
                    fullRequired = true,
                }
            end
            payload[#payload + 1] = Core.DeepCopy(entry.op)
            if tonumber(entry.revision) == expectedRevision + 1 then
                expectedRevision = tonumber(entry.revision)
            end
        end
    end
    if #payload <= 0 or expectedRevision ~= tonumber(inv.revision) then
        return {
            npcId = record.id,
            fromRevision = sinceRevision,
            inventoryRevision = inv.revision,
            fullRequired = true,
        }
    end
    return {
        npcId = record.id,
        fromRevision = sinceRevision,
        inventoryRevision = inv.revision,
        ops = payload,
        summary = Inventory.BuildSummaryPayload(record),
        equipment = Core.DeepCopy(record.equipment or {}),
    }
end
