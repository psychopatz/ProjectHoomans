-- Candidate construction for semantic dialogue branch suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local copyValue = Internal.copyValue
local predicateIR = Internal.predicateIR
local canonicalTopic = Internal.canonicalTopic
local topicGroupID = Internal.topicGroupID
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord

local function responseCatalog()
    local catalog = PNC.Semantics.ResponseCatalog
    if type(catalog) == "table"
        and type(catalog.OffersForSelection) == "function"
    then
        return catalog
    end
    local ok, loaded = pcall(require,
        "PNC/Semantics/PNC_SemanticDialogueResponseCatalog")
    if ok and type(loaded) == "table"
        and type(loaded.OffersForSelection) == "function"
    then
        return loaded
    end
    return nil
end

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

local function predicateContextFor(context, ir, offer)
    local predicateContext = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        predicateContext[key] = value
    end
    predicateContext.ir = predicateIR(ir)
    predicateContext.suggestion = {
        candidateID = offer and offer.id or nil,
        destination = context and context.suggestionDestination or nil,
    }
    return predicateContext
end

local function branchOfferFrame(offer, revision, origin)
    local semantic = offer.frame or {}
    local frame = copyValue(semantic) or {}
    frame.schemaVersion = Suggestions.VERSION
    frame.kind = "semantic_click_frame"
    frame.candidateID = offer.id
    frame.textKey = offer.utteranceKey
    frame.textFallback = offer.utteranceFallback
    frame.labelKey = offer.labelKey
    frame.requestRevision = revision
    frame.origin = copyValue(origin) or {}
    if origin and origin.eventRef then
        frame.eventRef = origin.eventRef
    end
    if frame.reference ~= nil then
        frame.extensions = frame.extensions or {}
        frame.extensions.dialogueFollowUp = "CONTEXT_REFERENCE"
        frame.extensions.topic = frame.extensions.topic or "conversation"
        frame.extensions.contextQuestion = frame.reference
    end
    return frame
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
            -- Branch offers are the active response surface. Preserve their
            -- exact predicate evidence when the bounded trace already holds
            -- lower-priority capability rows.
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

local function offersFromPlan(plan)
    if type(plan) ~= "table" or type(plan.turns) ~= "table" then
        return {}
    end
    local output = {}
    for turnIndex = 1, #plan.turns do
        local turn = plan.turns[turnIndex]
        for offerIndex = 1, #(turn.offers or {}) do
            local offer = turn.offers[offerIndex]
            -- Event follow-ups are lifecycle-window projections. Keeping
            -- them out of the transient response/message lanes prevents a
            -- response payload from exposing them without event facts,
            -- expiry, or disclosure checks.
            if string.sub(tostring(offer and offer.id or ""), 1, 24)
                ~= "semantic.followup.event."
            then
                output[#output + 1] = {
                    offer = offer,
                    origin = {
                        kind = "response_plan",
                        sourcePoolID = plan.sourcePoolID,
                        turnID = turn.id,
                        turnIndex = turnIndex,
                        offerIndex = offerIndex,
                    },
                }
            end
        end
    end
    return output
end

local function offersFromMessages(messages)
    local output = {}
    for messageIndex = 1, #(type(messages) == "table" and messages or {}) do
        local message = messages[messageIndex]
        local payload = type(message) == "table"
            and type(message.payload) == "table" and message.payload or nil
        local plan = payload and payload.plan or nil
        for _, item in ipairs(offersFromPlan(plan)) do
            item.origin.messageIndex = messageIndex
            output[#output + 1] = item
        end
    end
    return output
end

local function offersFromLifecycle(context)
    local lifecycle = type(context) == "table"
        and context.interactionLifecycle or nil
    local beat = type(lifecycle) == "table" and lifecycle.activeBeat or nil
    local eventRef = beat and tostring(beat.eventRef or "") or ""
    local planID = beat and tostring(beat.responsePlanID or "") or ""
    local realizationID = beat and tostring(beat.realizationID or "") or ""
    local offerIDs = beat and beat.offerIDs or nil
    if eventRef == "" or planID == "" or realizationID == ""
        or type(offerIDs) ~= "table" or #offerIDs == 0
        or type(beat.factRefs) ~= "table" or #beat.factRefs == 0
    then
        return {}
    end

    local wanted = {}
    for index = 1, math.min(#offerIDs, 8) do
        wanted[tostring(offerIDs[index] or "")] = true
    end
    local catalog = responseCatalog()
    if not catalog then return {} end
    local output = {}
    for index, offer in ipairs(
        catalog.OffersForSelection(planID, realizationID) or {}
    ) do
        if wanted[tostring(offer.id or "")] then
            output[#output + 1] = {
                offer = offer,
                origin = {
                    kind = "npc_event_response_plan",
                    sourcePoolID = planID,
                    realizationID = realizationID,
                    eventRef = eventRef,
                    turnID = beat.id,
                    turnIndex = 1,
                    offerIndex = index,
                },
            }
        end
    end
    return output
end

Internal.addCandidate = addCandidate
Internal.addProviderCandidate = addProviderCandidate
Internal.addBranchOfferCandidate = addBranchOfferCandidate
Internal.branchOfferFrame = branchOfferFrame
Internal.predicateContextFor = predicateContextFor
Internal.offersFromPlan = offersFromPlan
Internal.offersFromMessages = offersFromMessages
Internal.offersFromLifecycle = offersFromLifecycle

return Suggestions

