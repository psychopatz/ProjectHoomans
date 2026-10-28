-- Runtime read model and bounded adapter seam for InteractionProviders.
-- Owns no facts, storage, gameplay mutations or text interpretation.
local Evidence = { MAX_ROWS = 16, MAX_ADAPTERS = 16, MAX_TERMS = 8 }
local adapters = {}
local tiers = { SESSION = 1, TODAY = 2, DURABLE = 3 }

local function text(value)
    if type(value) ~= "string" or value == "" then return nil end
    return string.sub(value, 1, 128)
end

local function number(value, maximum)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then return nil end
    return math.max(0, math.min(maximum, value))
end

local function terms(value)
    local output, seen = {}, {}
    if type(value) ~= "table" then return output end
    for index = 1, math.min(#value, Evidence.MAX_TERMS) do
        local term = text(value[index])
        if term and not seen[term] then
            output[#output + 1], seen[term] = term, true
        end
    end
    table.sort(output)
    return output
end

local function contains(values, wanted)
    if not wanted then return true end
    for index = 1, #values do
        if values[index] == wanted then return true end
    end
    return false
end

function Evidence.Normalize(value, providerID, tier)
    if type(value) ~= "table" or not text(value.sourceRef)
        or not tiers[tier or value.sourceTier] then return nil end
    local relations = {}
    for _, kind in ipairs({ "opens", "addresses", "resolves", "violates", "explains" }) do
        relations[kind] = terms(type(value.relations) == "table"
            and value.relations[kind] or nil)
    end
    return {
        schemaVersion = 1, sourceRef = text(value.sourceRef),
        providerID = text(providerID) or "unknown",
        sourceTier = tier or value.sourceTier,
        actorID = text(value.actorID), targetID = text(value.targetID),
        eventType = text(value.eventType), classes = terms(value.classes),
        relations = relations, tags = terms(value.tags),
        retentionSalience = number(value.retentionSalience, 255),
        confidence = number(value.confidence, 1),
        effectiveStrength = number(value.effectiveStrength, 1),
        ageHours = number(value.ageHours, 100000000),
        occurredAt = number(value.occurredAt, 100000000),
        sequence = number(value.sequence, 100000000),
        topic = text(value.topic), visibility = text(value.visibility),
        provenance = text(value.provenance),
    }
end

function Evidence.Register(spec)
    if type(spec) ~= "table" or not text(spec.id)
        or not tiers[spec.sourceTier] or type(spec.Query) ~= "function" then
        return false, "evidence_adapter_invalid"
    end
    for index = 1, #adapters do
        if adapters[index].id == text(spec.id) then return false, "evidence_adapter_duplicate" end
    end
    if #adapters >= Evidence.MAX_ADAPTERS then return false, "evidence_adapter_limit" end
    adapters[#adapters + 1] = { id = text(spec.id), sourceTier = spec.sourceTier, Query = spec.Query }
    table.sort(adapters, function(a, b)
        if a.sourceTier == b.sourceTier then return a.id < b.id end
        return tiers[a.sourceTier] < tiers[b.sourceTier]
    end)
    return true
end

function Evidence.Query(context, query)
    query = type(query) == "table" and query or {}
    local limit = math.floor(number(query.limit, Evidence.MAX_ROWS) or Evidence.MAX_ROWS)
    local filter = { relation = text(query.relation), relationKind = text(query.relationKind),
        class = text(query.class), actorID = text(query.actorID), targetID = text(query.targetID),
        limit = Evidence.MAX_ROWS }
    local output, diagnostics, seen = {}, {}, {}
    for index = 1, #adapters do
        local adapter = adapters[index]
        -- Addon-owned callbacks are an external failure boundary. A failed
        -- provider contributes no evidence and cannot authorize an effect.
        local adapterFilter = {}
        for key, value in pairs(filter) do adapterFilter[key] = value end
        local ok, rows = pcall(adapter.Query, context, adapterFilter)
        diagnostics[#diagnostics + 1] = { providerID = adapter.id,
            sourceTier = adapter.sourceTier, status = ok and "queried" or "unavailable" }
        if ok and type(rows) == "table" then
            for rowIndex = 1, math.min(#rows, Evidence.MAX_ROWS) do
                local row = Evidence.Normalize(rows[rowIndex], adapter.id, adapter.sourceTier)
                if row and not seen[row.sourceRef]
                    and (not filter.actorID or row.actorID == filter.actorID)
                    and (not filter.targetID or row.targetID == filter.targetID)
                    and contains(row.classes, filter.class)
                    and (not filter.relation or contains(
                        row.relations[filter.relationKind or "opens"] or {}, filter.relation))
                    and #output < limit then
                    output[#output + 1], seen[row.sourceRef] = row, true
                end
            end
        end
    end
    return { schemaVersion = 1, rows = output, providers = diagnostics, limit = limit }
end

return Evidence
