-- PNC inventory normalization, runtime state, revisions, and base records.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
Inventory.Internal = Inventory.Internal or {}
local Internal = Inventory.Internal

function Internal.normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

function Internal.shallowArrayCopy(source)
    local output = {}
    local i
    if type(source) ~= "table" then
        return output
    end
    for i = 1, #source do
        output[i] = source[i]
    end
    return output
end

function Internal.getRuntimeState(record)
    if not record then
        return nil
    end
    record.runtime = record.runtime or {}
    record.runtime.inventory = record.runtime.inventory or {
        nextItemSerial = 0,
        opLog = {},
    }
    record.runtime.inventory.nextItemSerial = math.max(0,
        math.floor(tonumber(record.runtime.inventory.nextItemSerial) or 0))
    record.runtime.inventory.opLog = type(record.runtime.inventory.opLog) == "table"
        and record.runtime.inventory.opLog
        or {}
    return record.runtime.inventory
end

function Internal.nextItemID(record)
    local runtime = Internal.getRuntimeState(record)
    runtime.nextItemSerial = runtime.nextItemSerial + 1
    return "item_" .. tostring(runtime.nextItemSerial)
end

function Internal.refreshNextItemSerial(record, inv)
    local runtime = Internal.getRuntimeState(record)
    local maxSerial = 0
    local itemID
    local serial
    if not runtime or not inv or type(inv.items) ~= "table" then
        return
    end
    for itemID, _ in pairs(inv.items) do
        if type(itemID) == "string" then
            serial = tonumber(string.match(itemID, "^item_(%d+)$"))
            if serial and serial > maxSerial then
                maxSerial = serial
            end
        end
    end
    runtime.nextItemSerial = math.max(maxSerial, tonumber(runtime.nextItemSerial) or 0)
end

function Internal.buildOperation(op, data)
    local payload = { op = op }
    local key
    if type(data) == "table" then
        for key, _ in pairs(data) do
            payload[key] = data[key]
        end
    end
    return payload
end

function Internal.bumpRevision(record, ops, reason)
    local inv = record.inventory
    local runtime = Internal.getRuntimeState(record)
    local extra
    local i
    if type(ops) ~= "table" or #ops <= 0 then
        return inv and inv.revision or 0
    end
    inv.revision = math.max(0, math.floor(tonumber(inv.revision) or 0)) + 1
    inv.lastMutationReason = Internal.normalizeString(reason) or "mutation"
    for i = 1, #ops do
        runtime.opLog[#runtime.opLog + 1] = {
            revision = inv.revision,
            op = ops[i],
        }
    end
    extra = #runtime.opLog - (PNC.Const.INVENTORY_OPLOG_MAX or 32)
    while extra > 0 do
        table.remove(runtime.opLog, 1)
        extra = extra - 1
    end
    return inv.revision
end

function Internal.buildBaseCarryWeight(record)
    local skills = PNC.Skills
    local strength = skills and skills.GetLevel and skills.GetLevel(record, "Strength") or 2
    local fitness = skills and skills.GetLevel and skills.GetLevel(record, "Fitness") or 2
    return math.max(6, 6 + (tonumber(strength) or 0) + ((tonumber(fitness) or 0) * 0.5))
end

function Internal.createBaseInventory(record)
    local maxWeight = Internal.buildBaseCarryWeight(record)
    return {
        revision = 0,
        deltaMode = "template_plus_delta",
        cachedWeight = 0,
        maxWeight = maxWeight,
        rootMaxWeight = maxWeight,
        equipped = { primary = nil, secondary = nil, bag = nil },
        worn = {},
        attached = {},
        items = {},
        containers = {
            root = { maxWeight = maxWeight, items = {} },
        },
        template = {
            archetypeID = record and record.archetypeID or "General",
            seed = record and record.identitySeed or 1,
            generatorVersion = PNC.Const and PNC.Const.GENERATOR_VERSION or 1,
        },
    }
end

function Internal.countMapEntries(map)
    local count = 0
    for _, _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end
