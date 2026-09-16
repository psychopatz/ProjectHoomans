-- Bounded, versioned NPC-cognition facts.
--
-- This is a data contract, not a parser and not a gameplay action API.  The
-- authoritative cognition service owns writes; clients receive a filtered
-- projection for the active conversation and may only read it.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = PNC.Semantics.CognitionProjection or {}
PNC.Semantics.CognitionProjection = Projection

Projection.VERSION = 1
Projection.MAX_FACTS = 64
Projection.MAX_VALUE_DEPTH = 3
Projection.MAX_VALUE_FIELDS = 24
Projection.MAX_STRING_LENGTH = 128
Projection.KEY_SEPARATOR = "|"

local VALID_STATUS = {
    known = true,
    unknown = true,
    ambiguous = true,
}

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function boundedString(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or Projection.MAX_STRING_LENGTH)
end

local function identifier(value)
    if type(value) == "table" then
        value = value.id or value.entityID or value.npcID or value.key
    end
    return boundedString(value, Projection.MAX_STRING_LENGTH)
end

local function subject(value)
    value = boundedString(value, Projection.MAX_STRING_LENGTH)
    if not value then return nil end
    value = string.upper(value)
    if string.find(value, "[^%w_%.%-]") then return nil end
    return value
end

local function safeCopy(value, depth, budget)
    local valueType = type(value)
    local output
    local key
    local item
    local copiedKey
    local copiedItem
    if value == nil then return nil, true end
    if valueType == "string" then
        value = boundedString(value, Projection.MAX_STRING_LENGTH)
        return value, value ~= nil
    end
    if valueType == "boolean" then return value, true end
    if valueType == "number" then
        value = finite(value)
        return value, value ~= nil
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        return nil, false
    end
    depth = tonumber(depth) or 0
    budget = budget or { count = 0, seen = {} }
    if depth >= Projection.MAX_VALUE_DEPTH or budget.seen[value] then
        return nil, false
    end
    budget.seen[value] = true
    output = {}
    for key, item in pairs(value) do
        budget.count = budget.count + 1
        if budget.count > Projection.MAX_VALUE_FIELDS
            or (type(key) ~= "string" and type(key) ~= "number")
        then
            budget.seen[value] = nil
            return nil, false
        end
        copiedKey, item = safeCopy(key, depth + 1, budget)
        if item ~= true then
            budget.seen[value] = nil
            return nil, false
        end
        copiedItem, item = safeCopy(value[key], depth + 1, budget)
        if item ~= true then
            budget.seen[value] = nil
            return nil, false
        end
        output[copiedKey] = copiedItem
    end
    budget.seen[value] = nil
    return output, true
end

local function normalizeConfidence(value, status)
    value = finite(value)
    if value == nil then
        value = status == "known" and 0.75 or 0
    end
    return math.max(0, math.min(1, value))
end

local function normalizeTime(value, fallback)
    value = finite(value)
    if value == nil then value = finite(fallback) end
    return value and math.max(0, value) or nil
end

local function normalizeStatus(raw)
    local status = tostring(raw or "")
    if status == "" then return "unknown" end
    return VALID_STATUS[status] and status or nil
end

local function statusFor(source)
    local status = normalizeStatus(source and source.status)
    if status ~= "unknown" or source == nil
        or source.status ~= nil
    then
        return status
    end
    if source.known == true then return "known" end
    if source.ambiguous == true then return "ambiguous" end
    return status
end

local function copyOptional(source, field)
    local value = source and source[field] or nil
    if value == nil then return nil, true end
    return safeCopy(value)
end

function Projection.Key(rawSubject, rawTargetID)
    local normalizedSubject = subject(rawSubject)
    local targetID = identifier(rawTargetID)
    if not normalizedSubject then return nil end
    return normalizedSubject .. Projection.KEY_SEPARATOR
        .. tostring(targetID or "*")
end

local function keyParts(key)
    local separator = string.find(tostring(key or ""),
        Projection.KEY_SEPARATOR, 1, true)
    local rawSubject
    local rawTarget
    if not separator then return nil, nil end
    rawSubject = string.sub(key, 1, separator - 1)
    rawTarget = string.sub(key, separator + 1)
    if rawTarget == "*" then rawTarget = nil end
    return subject(rawSubject), identifier(rawTarget)
end

function Projection.NormalizeFact(raw, fallbackSubject, fallbackTargetID)
    local source = type(raw) == "table" and raw or nil
    local normalizedSubject
    local targetID
    local status
    local value
    local valueValid
    local location
    local locationValid
    local event
    local eventValid
    local evidence
    local evidenceValid
    local observedAt
    if not source then return nil, "invalid_fact" end
    normalizedSubject = subject(source.subject or fallbackSubject)
    targetID = identifier(source.targetID or source.target or fallbackTargetID)
    status = statusFor(source)
    if not status then return nil, "invalid_fact_status" end
    if source.value ~= nil then
        value, valueValid = safeCopy(source.value)
        if not valueValid then return nil, "unsafe_fact_value" end
    end
    location, locationValid = copyOptional(source, "location")
    event, eventValid = copyOptional(source, "event")
    evidence, evidenceValid = copyOptional(source, "evidence")
    if not locationValid or not eventValid or not evidenceValid then
        return nil, "unsafe_fact_metadata"
    end
    if not normalizedSubject then return nil, "fact_subject_required" end
    observedAt = normalizeTime(
        source.observedAt or source.lastObservedAt,
        source.recordedAt
    )
    local output = {
        schemaVersion = Projection.VERSION,
        key = Projection.Key(normalizedSubject, targetID),
        subject = normalizedSubject,
        targetID = targetID,
        targetName = boundedString(source.targetName),
        status = status,
        value = value,
        location = location,
        event = event,
        source = boundedString(source.source) or "unknown",
        sourceID = boundedString(source.sourceID),
        evidence = evidence,
        confidence = normalizeConfidence(source.confidence, status),
        observedAt = observedAt,
        recordedAt = normalizeTime(source.recordedAt, observedAt),
        expiresAt = normalizeTime(source.expiresAt),
        clientVisible = source.clientVisible ~= false,
    }
    if output.expiresAt ~= nil and output.observedAt ~= nil
        and output.expiresAt < output.observedAt
    then
        output.expiresAt = output.observedAt
    end
    return output
end

local function prefer(left, right)
    local leftObserved = tonumber(left and left.observedAt) or -1
    local rightObserved = tonumber(right and right.observedAt) or -1
    local leftConfidence = tonumber(left and left.confidence) or 0
    local rightConfidence = tonumber(right and right.confidence) or 0
    local leftSource = tostring(left and left.source or "")
    local rightSource = tostring(right and right.source or "")
    if rightObserved ~= leftObserved then
        return rightObserved > leftObserved and right or left
    end
    if rightConfidence ~= leftConfidence then
        return rightConfidence > leftConfidence and right or left
    end
    if rightSource ~= leftSource then
        return rightSource < leftSource and right or left
    end
    return tostring(right and right.key or "")
            < tostring(left and left.key or "") and right or left
end

local function factPriority(fact)
    return (tonumber(fact and fact.confidence) or 0) * 1000000
        + (tonumber(fact and fact.observedAt) or 0)
end

local function pruneFacts(facts)
    local count = 0
    local key
    local fact
    local weakestKey
    local weakest
    for key, fact in pairs(facts or {}) do
        count = count + 1
        if not weakest
            or factPriority(fact) < factPriority(weakest)
            or (factPriority(fact) == factPriority(weakest)
                and tostring(key) > tostring(weakestKey))
        then
            weakestKey = key
            weakest = fact
        end
    end
    if count > Projection.MAX_FACTS and weakestKey then
        facts[weakestKey] = nil
        return true
    end
    return false
end

function Projection.Normalize(raw, npcID)
    local source = type(raw) == "table" and raw or {}
    local output = {
        schemaVersion = Projection.VERSION,
        npcID = identifier(npcID or source.npcID),
        revision = math.max(0, math.floor(finite(source.revision) or 0)),
        updatedAt = normalizeTime(source.updatedAt),
        facts = {},
    }
    local candidates = type(source.facts) == "table"
        and source.facts or {}
    local keys = {}
    local key
    local item
    local fallbackSubject
    local fallbackTargetID
    local normalized
    local existing
    for key, item in pairs(candidates) do
        fallbackSubject, fallbackTargetID = keyParts(key)
        normalized = Projection.NormalizeFact(
            item, fallbackSubject, fallbackTargetID)
        if normalized then
            existing = output.facts[normalized.key]
            output.facts[normalized.key] = existing
                and prefer(existing, normalized) or normalized
        end
    end
    for key, _ in pairs(output.facts) do keys[#keys + 1] = key end
    table.sort(keys)
    while #keys > Projection.MAX_FACTS do
        output.facts[keys[#keys]] = nil
        table.remove(keys)
    end
    return output
end

function Projection.Serialize(raw, npcID)
    local normalized = Projection.Normalize(raw, npcID)
    local hasFacts = false
    local _
    if type(normalized) ~= "table" then return nil end
    for _, _ in pairs(normalized.facts) do
        hasFacts = true
        break
    end
    if not hasFacts then return nil end
    return normalized
end

function Projection.Get(raw, rawSubject, rawTargetID, worldAgeHours)
    local projection = type(raw) == "table" and raw or nil
    local key = Projection.Key(rawSubject, rawTargetID)
    local fallbackKey = Projection.Key(rawSubject, nil)
    local fact
    local expiresAt
    local now
    if not projection or type(projection.facts) ~= "table" or not key then
        return nil, "fact_unavailable"
    end
    fact = projection.facts[key] or projection.facts[fallbackKey]
    if not fact then return nil, "fact_unavailable" end
    expiresAt = tonumber(fact.expiresAt)
    now = finite(worldAgeHours)
    if expiresAt ~= nil and now ~= nil and now >= expiresAt then
        return nil, "fact_expired"
    end
    return fact
end

function Projection.Upsert(raw, rawFact, npcID)
    local projection = Projection.Normalize(raw, npcID)
    local fact
    local current
    local selected
    if not projection then return false, "invalid_projection" end
    fact = Projection.NormalizeFact(rawFact)
    if not fact then return false, "invalid_fact" end
    current = projection.facts[fact.key]
    if current then
        selected = prefer(current, fact)
        if selected == current then return false, "stale_fact", current end
    else
        selected = fact
    end
    projection.facts[fact.key] = selected
    projection.revision = projection.revision + 1
    projection.updatedAt = fact.recordedAt or fact.observedAt
        or projection.updatedAt
    pruneFacts(projection.facts)
    return true, selected, projection
end

function Projection.Remove(raw, rawSubject, rawTargetID, npcID)
    local projection = Projection.Normalize(raw, npcID)
    local key = Projection.Key(rawSubject, rawTargetID)
    if not projection or not key or not projection.facts[key] then
        return false, "fact_not_found", projection
    end
    projection.facts[key] = nil
    projection.revision = projection.revision + 1
    return true, "removed", projection
end

local function publicLocation(raw)
    local location = type(raw) == "table" and raw or nil
    local output
    local value
    if not location then return nil end
    output = {}
    value = boundedString(location.label)
    if value then output.label = value end
    value = boundedString(location.distanceBand)
    if value then output.distanceBand = value end
    value = boundedString(location.precision)
    if value then output.precision = value end
    for _, _ in pairs(output) do return output end
    return nil
end

local function publicFact(fact)
    local output = {
        schemaVersion = Projection.VERSION,
        key = fact.key,
        subject = fact.subject,
        targetID = fact.targetID,
        targetName = fact.targetName,
        status = fact.status,
        source = fact.source,
        confidence = fact.confidence,
        observedAt = fact.observedAt,
        recordedAt = fact.recordedAt,
        expiresAt = fact.expiresAt,
    }
    if fact.value ~= nil then output.value = fact.value end
    if fact.location ~= nil then
        output.location = publicLocation(fact.location)
    end
    if fact.event ~= nil then output.event = fact.event end
    return output
end

local function scopeIncludes(fact, rawScope)
    local scope = type(rawScope) == "table" and rawScope or {}
    local requestedSubject = subject(scope.subject)
    local requestedTarget = identifier(scope.targetID or scope.target)
    local subjects = scope.subjects
    local hasSubjectFilter = requestedSubject ~= nil
    local subjectMatches = requestedSubject == nil
        or fact.subject == requestedSubject
    local normalizedSubject
    local index
    if type(subjects) == "table" then
        for index = 1, math.min(8, #subjects) do
            normalizedSubject = subject(subjects[index])
            if normalizedSubject then
                hasSubjectFilter = true
                if fact.subject == normalizedSubject then
                    subjectMatches = true
                end
            end
        end
    end
    if hasSubjectFilter and not subjectMatches then return false end
    if requestedTarget ~= nil
        and tostring(fact.targetID or "") ~= tostring(requestedTarget)
    then
        return false
    end
    return true
end

function Projection.BuildClientProjection(raw, npcID, options)
    local normalized = Projection.Normalize(raw, npcID)
    local output = {
        schemaVersion = Projection.VERSION,
        npcID = normalized.npcID,
        revision = normalized.revision,
        updatedAt = normalized.updatedAt,
        replace = true,
        facts = {},
    }
    local subjects = {}
    local requestedSubject = type(options) == "table"
        and subject(options.subject) or nil
    local directSubject = requestedSubject
    local targetID = type(options) == "table"
        and identifier(options.targetID or options.target) or nil
    local requestedSubjects = type(options) == "table"
        and options.subjects or nil
    local scopeSubjects = {}
    local key
    local fact
    local include
    local index
    local subjectCount = 0
    if requestedSubject then subjects[requestedSubject] = true end
    if type(requestedSubjects) == "table" then
        for index = 1, math.min(8, #requestedSubjects) do
            requestedSubject = subject(requestedSubjects[index])
            if requestedSubject and not subjects[requestedSubject] then
                subjects[requestedSubject] = true
            end
        end
    end
    for requestedSubject, _ in pairs(subjects) do
        subjectCount = subjectCount + 1
        scopeSubjects[#scopeSubjects + 1] = requestedSubject
    end
    table.sort(scopeSubjects)
    output.scope = {
        targetID = targetID,
    }
    if subjectCount == 1 and directSubject ~= nil
    then
        output.scope.subject = scopeSubjects[1]
    elseif subjectCount > 0 then
        output.scope.subjects = scopeSubjects
    end
    for key, fact in pairs(normalized.facts) do
        include = subjectCount == 0
        if not include and subjects[fact.subject] then
            include = true
        end
        if include and targetID ~= nil then
            include = tostring(fact.targetID or "") == tostring(targetID)
        end
        if include and fact.clientVisible ~= false then
            output.facts[key] = publicFact(fact)
        end
    end
    return output
end

function Projection.Merge(existing, incoming, npcID)
    local replace = type(incoming) == "table" and incoming.replace == true
    local scope = type(incoming) == "table" and incoming.scope or nil
    local current = Projection.Normalize(existing, npcID)
    local received = Projection.Normalize(incoming, npcID)
    local key
    local fact
    local previous
    local selected
    local changed = false
    if not received.npcID then
        return nil, false, "npc_id_required"
    end
    if current.npcID and tostring(current.npcID) ~= tostring(received.npcID) then
        return nil, false, "npc_id_mismatch"
    end
    if (tonumber(received.revision) or 0) < (tonumber(current.revision) or 0) then
        return current, false, "stale_projection"
    end
    current.npcID = received.npcID
    current.revision = math.max(current.revision, received.revision)
    current.updatedAt = received.updatedAt or current.updatedAt
    if replace then
        for key, previous in pairs(current.facts) do
            if scopeIncludes(previous, scope)
                and received.facts[key] == nil
            then
                current.facts[key] = nil
                changed = true
            end
        end
    end
    for key, fact in pairs(received.facts) do
        previous = current.facts[key]
        selected = previous and prefer(previous, fact) or fact
        if selected ~= previous then
            current.facts[key] = selected
            changed = true
        end
    end
    pruneFacts(current.facts)
    return current, changed, changed and nil or "unchanged"
end

return Projection
