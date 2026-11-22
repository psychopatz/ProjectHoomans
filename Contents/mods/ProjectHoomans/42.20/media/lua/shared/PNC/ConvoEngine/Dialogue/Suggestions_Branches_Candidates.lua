-- Candidate construction for semantic dialogue branch suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Suggestions = PNC.ConvoEngine.DialogueSuggestions
local Internal = Suggestions.Internal

require "PNC/ConvoEngine/Dialogue/Suggestions_Branches_Sources"

local Predicates = Internal.Predicates
local copyValue = Internal.copyValue
local canonicalTopic = Internal.canonicalTopic
local topicGroupID = Internal.topicGroupID
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord
local predicateContextFor = Internal.predicateContextFor
local branchOfferFrame = Internal.branchOfferFrame

local function addCandidate(output, seen, definition, kind, revision, reason)
    if not definition then return end
    local candidate = seen[definition.id]
    if candidate then
        if #candidate.sources < Suggestions.MAX_SOURCES then
            candidate.sources[#candidate.sources + 1] =
                sourceRecord(kind, revision, reason)
        end
        return
    end
    if #output >= Suggestions.MAX_CANDIDATES then return end

    local frame = {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_click_frame",
        candidateID = definition.id,
        topic = definition.topic,
        patternID = definition.patternID,
        intent = definition.intent,
        speechAct = definition.speechAct,
        subject = definition.subject,
        target = definition.target,
        slots = copyValue(definition.slots) or {},
        modifiers = copyValue(definition.modifiers) or {},
        socialContext = copyValue(definition.socialContext) or {},
        extensions = copyValue(definition.extensions) or {},
        textKey = definition.utteranceKey,
        textFallback = definition.utteranceFallback,
        labelKey = definition.labelKey,
        requestRevision = revision,
    }
    candidate = {
        id = definition.id,
        topic = definition.topic,
        groupID = topicGroupID(definition.topic)
            or "topic:other",
        rank = #output + 1,
        source = sourceRecord(kind, revision, reason),
        sources = { sourceRecord(kind, revision, reason) },
        frame = frame,
        display = {
            labelKey = definition.labelKey,
            labelFallback = definition.labelFallback,
            label = resolvedText(definition.labelKey, definition.labelFallback),
            utteranceKey = definition.utteranceKey,
            utteranceFallback = definition.utteranceFallback,
            utterance = resolvedText(
                definition.utteranceKey,
                definition.utteranceFallback
            ),
        },
        visibility = "player",
    }
    candidate = normalizeCandidate(candidate, kind, #output + 1)
    output[#output + 1] = candidate
    seen[definition.id] = candidate
end

local function addProviderCandidate(output, seen, candidate, revision)
    if type(candidate) ~= "table" then return end
    local id = tostring(candidate.id or "")
    if id == "" or candidate.visibility == "private" or seen[id] then
        return
    end
    if #output >= Suggestions.MAX_CANDIDATES then return end
    local frame = copyValue(candidate.frame) or {}
    local source = type(candidate.source) == "table"
        and candidate.source or {}
    frame.schemaVersion = Suggestions.VERSION
    frame.kind = "semantic_click_frame"
    frame.candidateID = id
    frame.requestRevision = revision
    candidate.frame = frame
    local providerID = tostring(
        candidate.providerID or source.providerID or "provider"
    )
    local sourceKind = tostring(source.kind or "provider")
    candidate.source = sourceRecord(
        sourceKind, revision, "provider_eligible"
    )
    candidate.source.providerID = providerID
    candidate.sources = { sourceRecord(
        sourceKind, revision, "provider_eligible"
    ) }
    candidate.sources[1].providerID = providerID
    frame.providerID = providerID
    local display = type(candidate.display) == "table"
        and candidate.display or {}
    display.label = resolvedText(display.labelKey, display.labelFallback)
    display.utterance = resolvedText(
        display.utteranceKey, display.utteranceFallback
    )
    candidate.display = display
    candidate.rank = #output + 1
    candidate.visibility = "player"
    output[#output + 1] = candidate
    seen[id] = candidate
end

local function addBranchOfferCandidate(
    output,
    seen,
    offer,
    kind,
    revision,
    reason,
    origin,
    context,
    ir,
    predicateTrace
)
    if type(offer) ~= "table" or offer.visibility == "private" then
        return nil, nil
    end
    local existing = seen[offer.id]
    if existing then
        if #existing.sources < Suggestions.MAX_SOURCES then
            existing.sources[#existing.sources + 1] = sourceRecord(
                kind, revision, reason
            )
        end
        return existing, nil
    end
    if #output >= Suggestions.MAX_CANDIDATES then return nil, nil end

    local eligibility = { status = "allowed", allowed = true, trace = {} }
    if type(offer.constraints) == "table" then
        eligibility = Predicates.Evaluate(
            offer.constraints,
            predicateContextFor(context, ir, offer)
        )
        for _, traceRow in ipairs(eligibility.trace or {}) do
            while #predicateTrace >= Predicates.MAX_TRACE do
                table.remove(predicateTrace, 1)
            end
            if #predicateTrace < Predicates.MAX_TRACE then
                predicateTrace[#predicateTrace + 1] = {
                    candidateID = offer.id,
                    source = kind,
                    path = traceRow.path,
                    status = traceRow.status,
                    reason = traceRow.reason,
                }
            end
        end
        if eligibility.status ~= "allowed" then
            return nil, eligibility
        end
    end

    local frame = branchOfferFrame(offer, revision, origin)
    local source = sourceRecord(kind, revision, reason)
    local candidate = {
        id = offer.id,
        topic = canonicalTopic(origin and origin.topic),
        groupID = "conversation_branch",
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        display = {
            labelKey = offer.labelKey,
            labelFallback = offer.labelFallback,
            label = resolvedText(offer.labelKey, offer.labelFallback),
            utteranceKey = offer.utteranceKey,
            utteranceFallback = offer.utteranceFallback,
            utterance = resolvedText(
                offer.utteranceKey, offer.utteranceFallback
            ),
        },
        visibility = "player",
        eligibility = eligibility,
        branch = copyValue(origin),
    }
    candidate = normalizeCandidate(candidate, kind, #output + 1)
    output[#output + 1] = candidate
    seen[offer.id] = candidate
    return candidate, eligibility
end

Internal.addCandidate = addCandidate
Internal.addProviderCandidate = addProviderCandidate
Internal.addBranchOfferCandidate = addBranchOfferCandidate

return Suggestions
