local Projection = require "PNC/Semantics/PNC_SemanticCognitionProjection_Core"
require "PNC/Semantics/PNC_SemanticCognitionProjection_Codec"
require "PNC/Semantics/PNC_SemanticCognitionProjection_Operations"

local Internal = Projection.Internal or {}
local boundedString = Internal.boundedString
local identifier = Internal.identifier
local subject = Internal.subject
local prefer = Internal.prefer
local pruneFacts = Internal.pruneFacts
local decodeScope = Internal.decodeScope
local scopeIncludes = nil

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
    local compact = type(incoming) == "table"
        and incoming.c == Projection.COMPACT_VERSION
    local replace = type(incoming) == "table"
        and (incoming.replace == true or compact and incoming.x == true)
    local scope = type(incoming) == "table" and incoming.scope or nil
    if scope == nil and compact then
        scope = decodeScope(incoming.q)
    end
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
        if current.identitySeed == nil and received.identitySeed ~= nil then
            current.identitySeed = received.identitySeed
            return current, true, "identity_seed_added"
        end
        return current, false, "stale_projection"
    end
    current.npcID = received.npcID
    current.revision = math.max(current.revision, received.revision)
    current.updatedAt = received.updatedAt or current.updatedAt
    if received.identitySeed ~= nil
        and received.identitySeed ~= current.identitySeed
    then
        current.identitySeed = received.identitySeed
        changed = true
    end
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
