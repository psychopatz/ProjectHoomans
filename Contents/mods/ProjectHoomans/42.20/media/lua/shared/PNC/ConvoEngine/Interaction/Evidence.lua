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

function Evidence.MatchesMeaning(value, query)
    query = type(query) == "table" and query or {}
    if not contains(value.classes or {}, query.class) then return false end
    if query.relation and not contains((value.relations or {})[query.relationKind or "opens"] or {}, query.relation) then return false end
    if type(query.relations) ~= "table" or #query.relations == 0 then return true end
    for index = 1, math.min(#query.relations, Evidence.MAX_TERMS) do
        for _, kind in ipairs({ "opens", "addresses", "resolves", "violates", "explains" }) do
            if contains((value.relations or {})[kind] or {}, query.relations[index]) then return true end
        end
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
        relations = terms(query.relations), limit = Evidence.MAX_ROWS }
    local output, diagnostics, seen, buckets = {}, {}, {}, {}
    local matched = 0
    local function newer(a, b)
        if (a.occurredAt or 0) ~= (b.occurredAt or 0) then return (a.occurredAt or 0) > (b.occurredAt or 0) end
        if (a.sequence or 0) ~= (b.sequence or 0) then return (a.sequence or 0) > (b.sequence or 0) end
        if (a.ageHours or math.huge) ~= (b.ageHours or math.huge) then return (a.ageHours or math.huge) < (b.ageHours or math.huge) end
        return a.sourceRef < b.sourceRef
    end
    for index = 1, #adapters do
        local adapter = adapters[index]
        -- Addon-owned callbacks are an external failure boundary. A failed
        -- provider contributes no evidence and cannot authorize an effect.
        local adapterFilter = {}
        for key, value in pairs(filter) do adapterFilter[key] = value end
        adapterFilter.relations = terms(filter.relations)
        local ok, rows = pcall(adapter.Query, context, adapterFilter)
        diagnostics[#diagnostics + 1] = { providerID = adapter.id,
            sourceTier = adapter.sourceTier, status = ok and "queried" or "unavailable" }
        local bucket = {}
        if ok and type(rows) == "table" then
            for rowIndex = 1, math.min(#rows, Evidence.MAX_ROWS) do
                local row = Evidence.Normalize(rows[rowIndex], adapter.id, adapter.sourceTier)
                if row and not seen[row.sourceRef]
                    and (not filter.actorID or row.actorID == filter.actorID)
                    and (not filter.targetID or row.targetID == filter.targetID)
                    and Evidence.MatchesMeaning(row, filter) then
                    bucket[#bucket + 1], seen[row.sourceRef] = row, true
                end
            end
        end
        table.sort(bucket, newer)
        buckets[#buckets + 1] = bucket
        matched = matched + #bucket
        diagnostics[#diagnostics].rowsMatched = #bucket
        diagnostics[#diagnostics].providerLimited = ok and type(rows) == "table" and #rows > Evidence.MAX_ROWS or false
    end
    -- Reserve representation across providers before spending remaining rows.
    -- A busy earlier tier/domain cannot hide another owner's closing fact.
    for position = 1, Evidence.MAX_ROWS do
        for index = 1, #buckets do
            local row = buckets[index][position]
            if row and #output < limit then output[#output + 1] = row end
        end
        if #output >= limit then break end
    end
    table.sort(output, function(a, b)
        if a.sourceTier ~= b.sourceTier then return tiers[a.sourceTier] < tiers[b.sourceTier] end
        if a.providerID ~= b.providerID then return a.providerID < b.providerID end
        return newer(a, b)
    end)
    return { schemaVersion = 1, rows = output, providers = diagnostics, limit = limit,
        truncated = matched > #output, matched = matched }
end

return Evidence
