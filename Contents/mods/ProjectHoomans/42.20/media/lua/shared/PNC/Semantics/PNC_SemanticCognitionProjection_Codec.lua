local Projection = require "PNC/Semantics/PNC_SemanticCognitionProjection_Core"
local Internal = Projection.Internal or {}
local safeCopy = Internal.safeCopy
local boundedString = Internal.boundedString
local identifier = Internal.identifier
local subject = Internal.subject
local STATUS_TO_CODE = Internal.statusToCode
local CODE_TO_STATUS = Internal.codeToStatus
local COMPACT_FACT_FIELD = Internal.compactFactField
local COMPACT_FACT_FIELD_NAME = Internal.compactFactFieldName
local COMPACT_SCOPE_FIELD = Internal.compactScopeField

local function appendCompactPair(target, code, value)
    target[#target + 1] = code
    target[#target + 1] = value
end

local function encodeFact(fact)
    local defaultConfidence = fact.status == "known" and 0.75 or 0
    -- Each row starts with subject and status, then stores compact field-code /
    -- value pairs. This stays a dense array while omitting nil/default fields.
    local row = { fact.subject, STATUS_TO_CODE[fact.status] or 1 }
    if fact.targetID ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.TARGET_ID, fact.targetID)
    end
    if fact.targetName ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.TARGET_NAME, fact.targetName)
    end
    if fact.value ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.VALUE, fact.value)
    end
    if fact.location ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.LOCATION, fact.location)
    end
    if fact.event ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.EVENT, fact.event)
    end
    if fact.source ~= "unknown" then
        appendCompactPair(row, COMPACT_FACT_FIELD.SOURCE, fact.source)
    end
    if fact.sourceID ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.SOURCE_ID, fact.sourceID)
    end
    if fact.evidence ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.EVIDENCE, fact.evidence)
    end
    if fact.confidence ~= defaultConfidence then
        appendCompactPair(row, COMPACT_FACT_FIELD.CONFIDENCE, fact.confidence)
    end
    if fact.observedAt ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.OBSERVED_AT, fact.observedAt)
    end
    if fact.recordedAt ~= fact.observedAt
        and fact.recordedAt ~= nil
    then
        appendCompactPair(row, COMPACT_FACT_FIELD.RECORDED_AT, fact.recordedAt)
    end
    if fact.expiresAt ~= nil then
        appendCompactPair(row, COMPACT_FACT_FIELD.EXPIRES_AT, fact.expiresAt)
    end
    if fact.clientVisible == false then
        appendCompactPair(row, COMPACT_FACT_FIELD.CLIENT_VISIBLE, false)
    end
    return row
end

local function decodeFact(row)
    local status
    local fact
    local fieldID
    local fieldName
    local value
    if type(row) ~= "table" then return nil end
    status = CODE_TO_STATUS[row[2]]
    if not status or type(row[1]) ~= "string" then return nil end
    fact = {
        subject = row[1],
        status = status,
        clientVisible = true,
    }
    for index = 3, #row, 2 do
        fieldID = row[index]
        fieldName = COMPACT_FACT_FIELD_NAME[fieldID]
        value = row[index + 1]
        if fieldName ~= nil and value ~= nil then
            fact[fieldName] = value
        end
    end
    return fact
end

local function encodeScope(scope)
    if type(scope) ~= "table" then return nil end
    local output = {}
    local targetID = identifier(scope.targetID)
    local normalizedSubject = subject(scope.subject)
    if targetID ~= nil then
        appendCompactPair(output, COMPACT_SCOPE_FIELD.TARGET_ID, targetID)
    end
    if normalizedSubject ~= nil then
        appendCompactPair(output, COMPACT_SCOPE_FIELD.SUBJECT, normalizedSubject)
    end
    if type(scope.subjects) == "table" then
        local subjects, valid = safeCopy(scope.subjects)
        if valid then
            appendCompactPair(output, COMPACT_SCOPE_FIELD.SUBJECTS, subjects)
        end
    end
    return output
end

local function decodeScope(scope)
    local output
    local fieldID
    local value
    if type(scope) ~= "table" then return nil end
    output = {}
    for index = 1, #scope, 2 do
        fieldID = scope[index]
        value = scope[index + 1]
        if fieldID == COMPACT_SCOPE_FIELD.TARGET_ID then
            output.targetID = value
        elseif fieldID == COMPACT_SCOPE_FIELD.SUBJECT then
            output.subject = value
        elseif fieldID == COMPACT_SCOPE_FIELD.SUBJECTS
            and type(value) == "table"
        then
            output.subjects = value
        end
    end
    return output
end

local function compactNormalized(
    projection,
    replace,
    scope,
    includeIdentitySeed
)
    -- Envelope: c codec, v fact schema, n NPC, r revision, t updated, f facts,
    -- x replace flag, q replacement scope, i ephemeral identity seed.
    local output = {
        c = Projection.COMPACT_VERSION,
        v = Projection.VERSION,
        n = projection.npcID,
        r = projection.revision,
        f = {},
    }
    local keys = {}
    local key
    for key, _ in pairs(projection.facts) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    for index = 1, #keys do
        output.f[index] = encodeFact(projection.facts[keys[index]])
    end
    if projection.updatedAt ~= nil then
        output.t = projection.updatedAt
    end
    if replace == true then
        output.x = true
    end
    if type(scope) == "table" then
        output.q = encodeScope(scope)
    end
    if includeIdentitySeed and projection.identitySeed ~= nil then
        output.i = projection.identitySeed
    end
    return output
end


Internal.compactNormalized = compactNormalized
Internal.decodeFact = decodeFact
Internal.decodeScope = decodeScope

return Projection
