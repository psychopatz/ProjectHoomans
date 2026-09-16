-- Salience- and capability-aware discourse reference resolution.
--
-- This module only ranks semantic candidates. It never scans the world,
-- queries inventory, or performs gameplay actions. Authoritative providers
-- supply candidate mentions and downstream systems revalidate the selected
-- entity before creating an action plan.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Resolver = PNC.Semantics.ContextResolver or {}
PNC.Semantics.ContextResolver = Resolver

local Constraints = PNC.Semantics.ContextConstraints
if type(Constraints) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticContextConstraints"
    Constraints = type(loaded) == "table" and loaded or nil
end

Resolver.VERSION = 1
Resolver.DEFAULT_MINIMUM_SCORE = 0.58
Resolver.DEFAULT_MINIMUM_MARGIN = 0.08
Resolver.MAX_DIAGNOSTIC_CANDIDATES = 8

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function normalized(value)
    value = string.upper(tostring(value or ""))
    return string.gsub(value, "[%s%-]+", "_")
end

local function referenceToken(value)
    local reference = type(value) == "table" and value.reference or value
    reference = normalized(reference)
    if reference == "THIS" or reference == "IT" or reference == "THAT" then
        return reference, "object"
    end
    if reference == "HIM" or reference == "HER" or reference == "THEM" then
        return reference, "person"
    end
    return nil, nil
end

local function candidateKey(value)
    if type(value) ~= "table" then return nil end
    if value.key ~= nil and tostring(value.key) ~= "" then
        return tostring(value.key)
    end
    local identity = value.id or value.entityID or value.itemID or value.uuid
    if identity ~= nil and tostring(identity) ~= "" then
        return "id:" .. tostring(identity)
    end
    local kind = value.entityType or value.type or value.kind or "entity"
    local concept = value.concept or value.category or ""
    local text = value.text or value.name or value.value or ""
    return "mention:" .. tostring(kind) .. ":"
        .. tostring(concept) .. ":" .. tostring(text)
end

local function personType(value)
    local kind = string.lower(tostring(
        value and (value.entityType or value.type or value.kind) or ""
    ))
    return kind == "npc" or kind == "player" or kind == "person"
        or kind == "character" or kind == "survivor"
end

local function compatibleType(value, referenceKind)
    if referenceKind == "person" then return personType(value) end
    if referenceKind == "object" then return not personType(value) end
    return true
end

local function storeList(store, method, limit)
    if type(store) ~= "table" or type(store[method]) ~= "function" then
        return {}
    end
    local ok
    local result
    ok, result = pcall(store[method], store, limit)
    return ok and type(result) == "table" and result or {}
end

local function addCandidates(output, seen, values)
    local index
    local candidate
    local key
    for index = 1, #values do
        candidate = values[index]
        if type(candidate) == "table" then
            key = candidateKey(candidate)
            if key and not seen[key] then
                seen[key] = true
                output[#output + 1] = candidate
            end
        end
    end
end

local function candidatesFor(store, context)
    local output = {}
    local seen = {}
    addCandidates(output, seen, storeList(store, "GetFocus", 12))
    addCandidates(output, seen, storeList(store, "GetMentions", 32))
    if type(context) == "table" then
        addCandidates(output, seen, context.semanticContextCandidates or {})
        addCandidates(output, seen, context.semanticEntityCandidates or {})
    end
    return output
end

local function currentTopic(store, context, options)
    if type(options) == "table" and options.currentTopic then
        return tostring(options.currentTopic)
    end
    if type(store) == "table" and store.currentTopic then
        return tostring(store.currentTopic)
    end
    return type(context) == "table" and context.currentTopic or nil
end

local function currentTurn(store, options)
    if type(options) == "table" and options.currentTurn ~= nil then
        return tonumber(options.currentTurn) or 0
    end
    return type(store) == "table" and tonumber(store.sequence) or 0
end

local function scoreCandidate(candidate, referenceKind, field, action, store,
    context, options)
    if not compatibleType(candidate, referenceKind) then
        return nil, "reference_type_mismatch"
    end

    local turn = currentTurn(store, options)
    local lastTurn = tonumber(candidate.lastTurn or candidate.turn) or turn
    local age = math.max(0, turn - lastTurn)
    local recency = 1 / (1 + age)
    local score = 0.20 + recency * 0.28
    local details = {
        key = candidateKey(candidate),
        recency = recency,
        age = age,
        roleMatch = false,
        topicMatch = false,
    }

    local role = string.lower(tostring(candidate.lastRole or candidate.role or ""))
    local expectedRole = field == "object" and "object"
        or field == "target" and "target" or field
    if role ~= "" and role == expectedRole then
        score = score + 0.18
        details.roleMatch = true
    end

    local topic = currentTopic(store, context, options)
    if topic and candidate.topic
        and string.lower(tostring(topic))
            == string.lower(tostring(candidate.topic))
    then
        score = score + 0.12
        details.topicMatch = true
    end

    local count = tonumber(candidate.mentionCount) or 1
    score = score + math.min(0.08, math.max(0, count - 1) * 0.02)
    if tonumber(candidate.confidence) then
        score = score + math.min(0.05, math.max(0, candidate.confidence) * 0.05)
    end

    local compatibility = true
    local compatibilityReason = "no_constraint"
    local compatibilityDetails = {}
    if Constraints and type(Constraints.Check) == "function" then
        compatibility, compatibilityReason, compatibilityDetails =
            Constraints.Check(action, candidate)
        details.capability = compatibilityDetails
    end
    details.capabilityStatus = compatibility == true and "satisfied"
        or compatibility == false and "incompatible" or "unknown"
    details.capabilityReason = compatibilityReason

    if compatibility == false then
        return nil, compatibilityReason, details
    end
    if compatibility == nil
        and (not options or options.requireKnownCapabilities ~= false)
    then
        return nil, compatibilityReason, details
    end
    if compatibility == true then score = score + 0.25 end
    if compatibility == nil then score = score - 0.08 end

    details.score = math.max(0, math.min(1, score))
    return details.score, compatibilityReason, details
end

local function sortCandidates(left, right)
    if left.score ~= right.score then return left.score > right.score end
    return tostring(left.key) < tostring(right.key)
end

local function diagnosticCandidate(entry)
    return {
        key = entry.key,
        id = entry.candidate.id or entry.candidate.entityID
            or entry.candidate.itemID,
        concept = entry.candidate.concept or entry.candidate.category,
        text = entry.candidate.text or entry.candidate.name,
        score = entry.score,
        reason = entry.reason,
        capabilityStatus = entry.details
            and entry.details.capabilityStatus or nil,
    }
end

local function resolvedValue(candidate, reference, details)
    local output = copyValue(candidate)
    output.reference = nil
    output.unresolved = false
    output.resolvedReference = reference
    output.resolution = {
        method = "context_salience_and_capability",
        confidence = details.confidence,
        margin = details.margin,
        candidateKey = details.candidateKey,
    }
    return output
end

function Resolver.ResolveReference(value, store, ir, options)
    options = type(options) == "table" and options or {}
    local reference, referenceKind = referenceToken(value)
    if not reference then return nil, "not_supported_reference" end
    if type(store) ~= "table" then return nil, "context_state_unavailable" end

    local candidates = candidatesFor(store, options.context)
    local ranked = {}
    local rejected = {}
    local index
    local candidate
    local score
    local reason
    local details
    local field = options.field or "object"
    local action = options.action or ir and ir.action
    for index = 1, #candidates do
        candidate = candidates[index]
        score, reason, details = scoreCandidate(
            candidate, referenceKind, field, action, store,
            options.context, options
        )
        if score then
            ranked[#ranked + 1] = {
                candidate = candidate,
                key = candidateKey(candidate),
                score = score,
                reason = reason,
                details = details,
            }
        else
            rejected[#rejected + 1] = {
                candidate = candidate,
                key = candidateKey(candidate),
                score = 0,
                reason = reason,
                details = details,
            }
        end
    end

    table.sort(ranked, sortCandidates)
    local top = ranked[1]
    local second = ranked[2]
    local margin = top and top.score - (second and second.score or 0) or 0
    local diagnostics = {
        reference = reference,
        referenceKind = referenceKind,
        field = field,
        action = action,
        candidateCount = #candidates,
        acceptedCandidateCount = #ranked,
        rejectedCandidates = {},
        candidates = {},
        margin = margin,
    }
    for index = 1, math.min(#ranked, Resolver.MAX_DIAGNOSTIC_CANDIDATES) do
        diagnostics.candidates[#diagnostics.candidates + 1] =
            diagnosticCandidate(ranked[index])
    end
    for index = 1, math.min(#rejected, Resolver.MAX_DIAGNOSTIC_CANDIDATES) do
        diagnostics.rejectedCandidates[#diagnostics.rejectedCandidates + 1] =
            diagnosticCandidate(rejected[index])
    end

    if not top then
        if #rejected > 0 then
            diagnostics.reason = rejected[1].reason
            return nil, rejected[1].reason, diagnostics
        end
        diagnostics.reason = "no_reference_candidates"
        return nil, diagnostics.reason, diagnostics
    end

    local minimumScore = tonumber(options.minimumScore)
        or Resolver.DEFAULT_MINIMUM_SCORE
    local minimumMargin = tonumber(options.minimumMargin)
        or Resolver.DEFAULT_MINIMUM_MARGIN
    diagnostics.topScore = top.score
    diagnostics.candidateKey = top.key
    diagnostics.confidence = top.score
    if top.score < minimumScore then
        diagnostics.reason = "low_reference_confidence"
        return nil, diagnostics.reason, diagnostics
    end
    if second and margin < minimumMargin then
        diagnostics.reason = "ambiguous_reference"
        return nil, diagnostics.reason, diagnostics
    end

    diagnostics.reason = "context_capability_match"
    return resolvedValue(top.candidate, reference, diagnostics),
        diagnostics.reason, diagnostics
end

Resolver.Resolve = Resolver.ResolveReference

return Resolver
