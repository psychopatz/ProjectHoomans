--[[
    PNC Inventory Payloads
    Compact summaries and full/incremental network representations.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Core = PNC.Core

local function buildIdentityMetadata(record)
    local factionID = record and record.affiliation
        and record.affiliation.factionID or record and record.factionID
    local faction
    local factionName
    if factionID and PNC.Factions then
        if type(PNC.Factions.GetPresentation) == "function" then
            faction = PNC.Factions.GetPresentation(factionID)
        elseif type(PNC.Factions.Get) == "function" then
            faction = PNC.Factions.Get(factionID)
        end
    end
    factionName = faction and tostring(faction.name or "")
        or record and (record.factionName
            or record.corpse and record.corpse.factionName) or nil
    return {
        npcId = record and tostring(record.id or "") or "",
        displayName = record and tostring(
            record.name or record.displayName or "Unknown NPC"
        ) or "Unknown NPC",
        factionID = factionID and tostring(factionID) or nil,
        factionName = factionName ~= "" and factionName or nil,
    }
end

local function buildSummaryPayload(record, inv)
    local raw = record and record.persistedInventory or nil
    local persistedSummary = raw and (raw.summary or raw.inventorySummary) or nil
    local persistedBaseline = raw and raw[4] or nil
    local persistedGenerator = raw and raw.template and tonumber(raw.template.generatorVersion) or nil
    local currentGenerator = PNC.Const and tonumber(PNC.Const.GENERATOR_VERSION) or 1
    local summary
    local templateRef = record and record.inventoryTemplateRef or nil
    local runtime = record and record.runtime or nil
    local cacheKey
    if not templateRef and type(persistedBaseline) == "table" then
        templateRef = persistedBaseline.templateRef
    end
    if not inv and type(record and record.inventory) ~= "table"
        and type(persistedSummary) == "table"
        and persistedGenerator == currentGenerator
    then
        summary = Core.DeepCopy(persistedSummary)
        summary.templateRef = summary.templateRef or templateRef
        return summary
    end
    inv = inv or Inventory.EnsureRecordInventory(record)
    if not inv then
        return nil
    end
    cacheKey = tostring(inv.revision or 0)
        .. "|" .. tostring(templateRef or "")
    if runtime
        and runtime.inventorySummaryCacheKey == cacheKey
        and type(runtime.inventorySummaryCache) == "table"
    then
        return Core.DeepCopy(runtime.inventorySummaryCache)
    end
    local encumbrance = Inventory.GetEncumbranceState(record, inv)
    summary = {
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
        templateRef = inv.template and inv.template.templateRef or templateRef,
    }
    if runtime then
        runtime.inventorySummaryCacheKey = cacheKey
        runtime.inventorySummaryCache = summary
    end
    return Core.DeepCopy(summary)
end

function Inventory.BuildSummaryPayload(record)
    return buildSummaryPayload(record)
end

function Inventory.BuildFullPayload(record)
    if Inventory.AdvanceFoodLifecycle
        and type(isServer) == "function" and isServer() == true
    then
        Inventory.AdvanceFoodLifecycle(record)
    end
    local inv = Inventory.EnsureRecordInventory(record)
    local items = {}
    local containers = {}
    local id
    if not inv then
        return nil
    end
    for id, _ in pairs(inv.items or {}) do
        items[id] = Internal.itemToNetworkPayload(inv.items[id])
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
        summary = buildSummaryPayload(record, inv),
        identityMetadata = buildIdentityMetadata(record),
        equipped = Core.DeepCopy(inv.equipped or {}),
        worn = Core.DeepCopy(inv.worn or {}),
        attached = Core.DeepCopy(inv.attached or {}),
        items = items,
        containers = containers,
    }
end

function Inventory.BuildDeltaPayload(record, sinceRevision)
    if Inventory.AdvanceFoodLifecycle
        and type(isServer) == "function" and isServer() == true
    then
        Inventory.AdvanceFoodLifecycle(record)
    end
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
            identityMetadata = buildIdentityMetadata(record),
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
            identityMetadata = buildIdentityMetadata(record),
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
                    identityMetadata = buildIdentityMetadata(record),
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
            identityMetadata = buildIdentityMetadata(record),
        }
    end
    return {
        npcId = record.id,
        fromRevision = sinceRevision,
        inventoryRevision = inv.revision,
        ops = payload,
        summary = Inventory.BuildSummaryPayload(record),
        identityMetadata = buildIdentityMetadata(record),
        equipment = Core.DeepCopy(record.equipment or {}),
    }
end
