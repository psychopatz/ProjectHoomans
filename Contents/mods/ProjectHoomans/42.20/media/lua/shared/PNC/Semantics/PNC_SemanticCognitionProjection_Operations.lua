local Projection = require "PNC/Semantics/PNC_SemanticCognitionProjection_Core"
require "PNC/Semantics/PNC_SemanticCognitionProjection_Codec"

local Internal = Projection.Internal or {}
local finite = Internal.finite
local normalizeIdentitySeed = Internal.normalizeIdentitySeed
local identifier = Internal.identifier
local subject = Internal.subject
local keyParts = Internal.keyParts
local prefer = Internal.prefer
local pruneFacts = Internal.pruneFacts
local compactNormalized = Internal.compactNormalized
local decodeFact = Internal.decodeFact
local decodeScope = Internal.decodeScope
local normalizeTime = Internal.normalizeTime

function Projection.Compact(raw, npcID)
    if type(raw) ~= "table" then return nil end
    local compact = raw.c == Projection.COMPACT_VERSION
    local replace = raw.replace == true or compact and raw.x == true
    local scope = type(raw.scope) == "table" and raw.scope
        or compact and decodeScope(raw.q)
    local normalized = Projection.Normalize(raw, npcID)
    -- Conversation packets carry the existing seed as a compact reference
    -- for client-side derived identity context. Persistence omits this copy.
    return compactNormalized(normalized, replace, scope, true)
end

function Projection.Normalize(raw, npcID)
    local source = type(raw) == "table" and raw or {}
    local compact = source.c == Projection.COMPACT_VERSION
    local revision = compact and source.r or source.revision
    local updatedAt = compact and source.t or source.updatedAt
    local rawIdentitySeed = compact and source.i or source.identitySeed
    local output = {
        schemaVersion = Projection.VERSION,
        npcID = identifier(npcID or (compact and source.n or source.npcID)),
        revision = math.max(0, math.floor(finite(revision) or 0)),
        updatedAt = normalizeTime(updatedAt),
        facts = {},
    }
    output.identitySeed = normalizeIdentitySeed(rawIdentitySeed)
    local candidates = compact and type(source.f) == "table" and source.f
        or type(source.facts) == "table" and source.facts or {}
    local keys = {}
    local key
    local item
    local fallbackSubject
    local fallbackTargetID
    local normalized
    local existing
    if compact then
        for index = 1, math.min(#candidates, Projection.MAX_FACTS * 2) do
            item = decodeFact(candidates[index])
            normalized = item and Projection.NormalizeFact(item) or nil
            if normalized then
                existing = output.facts[normalized.key]
                output.facts[normalized.key] = existing
                    and prefer(existing, normalized) or normalized
            end
        end
    else
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
    -- Static identity/background context is rebuilt from identity.seed; only
    -- observed or learned facts belong in this persisted projection.
    return compactNormalized(normalized)
end

function Projection.Get(raw, rawSubject, rawTargetID, worldAgeHours)
    local projection = type(raw) == "table" and raw or nil
    local key = Projection.Key(rawSubject, rawTargetID)
    local fallbackKey = Projection.Key(rawSubject, nil)
    local fact
    local expiresAt
    local now
    if projection and projection.c == Projection.COMPACT_VERSION then
        projection = Projection.Normalize(projection)
    end
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


return Projection
