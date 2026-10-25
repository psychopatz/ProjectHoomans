-- Internal implementation spoke for semantic dialogue suggestions.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local ChoiceRegistry = Internal.ChoiceRegistry
local IR = Internal.IR
local BranchOffers = Internal.BranchOffers
local Identity = Internal.Identity
local copyValue = Internal.copyValue
local predicateIR = Internal.predicateIR
local boundedText = Internal.boundedText
local normalized = Internal.normalized
local canonicalTopic = Internal.canonicalTopic
local topicGroupID = Internal.topicGroupID
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord

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
            output[#output + 1] = {
                offer = turn.offers[offerIndex],
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

function Suggestions.ResolveFrameText(frame)
    frame = type(frame) == "table" and frame or {}
    return resolvedText(
        frame.textKey,
        frame.textFallback or frame.utteranceFallback or frame.utterance
    )
end

local function sameBranchOrigin(frame, origin)
    local requested = type(frame.origin) == "table" and frame.origin or {}
    if requested.kind ~= nil and requested.kind ~= origin.kind then
        return false
    end
    for _, key in ipairs({ "flowID", "nodeID", "turnID", "sourcePoolID" }) do
        if requested[key] ~= nil
            and tostring(requested[key]) ~= tostring(origin[key] or "")
        then
            return false
        end
    end
    return true
end

local function branchOfferForFrame(frame, view)
    local result = view and view.lastSemanticDialogueResult or nil
    local decision = type(result) == "table"
        and type(result.decision) == "table" and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local flowOrigin = {
        kind = "active_flow",
        flowID = flow.flowId,
        nodeID = flow.toNodeId or flow.nodeId,
    }
    for _, offer in ipairs(flow.branchOffers or {}) do
        if type(offer) == "table"
            and offer.id == frame.candidateID
            and sameBranchOrigin(frame, flowOrigin)
        then
            return offer, flowOrigin
        end
    end

    local response = type(decision.response) == "table"
        and decision.response or {}
    for _, item in ipairs(offersFromPlan(response.plan)) do
        if item.offer and item.offer.id == frame.candidateID
            and sameBranchOrigin(frame, item.origin)
        then
            return item.offer, item.origin
        end
    end

    -- A live view may only expose the most recent queued payload. Inspect
    -- that bounded payload as a compatibility fallback without reparsing.
    for _, item in ipairs(offersFromMessages(result and result.messages)) do
        if item.offer and item.offer.id == frame.candidateID
            and sameBranchOrigin(frame, item.origin)
        then
            return item.offer, item.origin
        end
    end
    return nil, nil
end

local function branchOfferIR(offer, origin, frame, view)
    local source = offer.frame or {}
    local actorID = view and view.spec and view.spec.npcID or nil
    local slots = {}
    if source.stateType ~= nil or source.stateValue ~= nil then
        slots.state = {
            type = source.stateType,
            value = source.stateValue,
        }
    end
    local socialContext = {}
    if source.selfDirected ~= nil then
        socialContext.selfDirected = source.selfDirected
    end
    if source.target ~= nil then socialContext.target = source.target end
    if source.identityClaim ~= nil then
        socialContext.identityClaim = source.identityClaim
    end
    local target = source.target and {
        kind = "conversation_actor",
        ref = source.target,
    } or nil
    local ir = IR.New({
        kind = "semantic_suggestion_frame",
        rawText = resolvedText(
            offer.utteranceKey, offer.utteranceFallback
        ),
        normalizedText = normalizedText(offer.utteranceFallback),
        intent = source.intent,
        speechAct = source.speechAct,
        action = source.action,
        subject = source.subject,
        target = target,
            destination = copyValue(source.destination),
        slots = slots,
        socialContext = socialContext,
        confidence = 1,
        provenance = {
            provider = "suggestion",
            parser = "semantic_click_frame",
            pattern = source.pattern or "semantic_branch_offer",
            candidateID = frame.candidateID,
            origin = copyValue(origin),
            branchOfferID = offer.id,
            branchOfferConstraints = copyValue(offer.constraints),
        },
    })
    if actorID ~= nil and ir.target == nil and source.target == "SELF" then
        ir.target = { kind = "actor", id = actorID, source = "conversation" }
    end
    return ir
end

function Suggestions.FrameToIR(frame, view)
    if Suggestions.IsNavigationFrame(frame) then
        return Suggestions.NavigationFrameToIR(frame, view)
    end
    -- A landing shortcut is already a typed semantic frame. Preserve its
    -- canonical topic/route when native Core submits it through a group
    -- host; flattening it to display text lets the native parser reinterpret
    -- "What's up?" as a generic navigation turn.
    if Suggestions.IsShortcutFrame(frame) then
        local value = Suggestions.ResolveFrameText(frame)
        if value == "" then return nil, "shortcut_frame_text_missing" end
        local extensions = copyValue(frame.extensions) or {}
        if extensions.topic == nil and frame.topic ~= nil then
            extensions.topic = frame.topic
        end
        return IR.New({
            kind = "semantic_suggestion_frame",
            rawText = value,
            normalizedText = normalizedText(value),
            intent = frame.intent or "QUESTION",
            speechAct = frame.speechAct or "QUESTION",
            subject = frame.subject or "CONVERSATION_TOPIC",
            target = {
                kind = "actor",
                id = view and view.spec and view.spec.npcID or nil,
                source = "conversation",
            },
            extensions = extensions,
            confidence = 1,
            provenance = {
                provider = "suggestion",
                parser = "semantic_click_frame",
                pattern = "semantic_shortcut",
                candidateID = frame.candidateID,
            },
        })
    end
    if type(frame) ~= "table"
        or tonumber(frame.schemaVersion) ~= Suggestions.VERSION
        or frame.kind ~= "semantic_click_frame"
    then
        return nil, "suggestion_frame_invalid"
    end
    local branchOffer, branchOrigin = branchOfferForFrame(frame, view)
    if branchOffer then
        return branchOfferIR(branchOffer, branchOrigin, frame, view)
    end

    -- Generic registered providers resolve through the current bounded
    -- projection. This keeps click-time identity/revision checks on the
    -- existing lane instead of allowing a provider to become an action
    -- dispatcher or a second parser.
    local providerID = frame.providerID
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    providerID = providerID or extensions.providerID
    if providerID ~= nil then
        local current = view and view.semanticSuggestions or nil
        for _, candidate in ipairs(
            type(current) == "table" and current.candidates or {}
        ) do
            if tostring(candidate.id or "") == tostring(frame.candidateID or "")
                and tostring(candidate.providerID or "") == tostring(providerID)
            then
                local source = type(candidate.frame) == "table"
                    and candidate.frame or nil
                if not source then return nil, "suggestion_provider_frame_missing" end
                local target = copyValue(source.target)
                return IR.New({
                    kind = "semantic_suggestion_frame",
                    rawText = Suggestions.ResolveFrameText(source),
                    normalizedText = normalizedText(
                        source.textFallback or source.utteranceFallback
                    ),
                    intent = source.intent,
                    speechAct = source.speechAct,
                    action = source.action,
                    subject = source.subject,
                    target = target,
                    destination = copyValue(source.destination),
                    slots = copyValue(source.slots) or {},
                    modifiers = copyValue(source.modifiers) or {},
                    socialContext = copyValue(source.socialContext) or {},
                    extensions = copyValue(source.extensions) or {},
                    confidence = 1,
                    provenance = {
                        provider = tostring(providerID),
                        parser = "semantic_click_frame",
                        pattern = source.pattern or "semantic_provider",
                        candidateID = frame.candidateID,
                    },
                })
            end
        end
        return nil, "suggestion_provider_candidate_unknown"
    end

    local definition = definitionFor(frame.candidateID)
    local action
    if not definition then
        action, definition = capabilityDefinitionFor(frame.candidateID)
    end
    if not definition then
        action, definition = projectedCapabilityFor(frame.candidateID, view)
    end
    if not definition then return nil, "suggestion_candidate_unknown" end

    local actorID = view and view.spec and view.spec.npcID or nil
    local isCapability = action ~= nil
    if isCapability and normalized(frame.action) ~= normalized(action) then
        return nil, "suggestion_action_mismatch"
    end
    if not isCapability and frame.action ~= nil then
        return nil, "suggestion_unexpected_action"
    end

    local rawText = resolvedText(
        definition.utteranceKey,
        definition.utteranceFallback
    )
    local slots = copyValue(definition.slots) or {}
    local target = copyValue(definition.target)
    if isCapability and (target == nil
        or target.kind == "conversation_actor"
        or target.ref == "npc")
    then
        target = { kind = "actor", id = actorID, source = "conversation" }
        slots.npcID = actorID
    elseif isCapability then
        slots.npcID = actorID
    end
    local ir = IR.New({
        kind = "semantic_suggestion_frame",
        rawText = rawText,
        normalizedText = normalizedText(definition.utteranceFallback),
        intent = isCapability and "REQUEST" or definition.intent,
        speechAct = isCapability and "REQUEST" or definition.speechAct,
        action = isCapability and action or nil,
        subject = isCapability and nil or definition.subject,
        target = target,
        destination = copyValue(definition.destination),
        slots = slots,
        modifiers = copyValue(definition.modifiers) or {},
        socialContext = copyValue(definition.socialContext) or {},
        extensions = copyValue(definition.extensions) or {},
        confidence = 1,
        provenance = {
            provider = "suggestion",
            parser = "semantic_click_frame",
            pattern = definition.patternID,
            candidateID = definition.id,
        },
    })
    return ir
end

function Suggestions.CheckFrame(frame, context, ir)
    if Suggestions.IsNavigationFrame(frame) then
        if type(ir) ~= "table"
            or ir.intent ~= "NAVIGATE"
            or ir.provenance.parser ~= "semantic_navigation_frame"
        then
            return false, "navigation_frame_invalid"
        end
        return true, "navigation_frame_eligible", {
            status = "allowed",
            trace = {},
        }
    end
    local provenance = type(ir) == "table"
        and type(ir.provenance) == "table" and ir.provenance or {}
    if provenance.branchOfferID == frame.candidateID then
        local branchOffer = {
            id = provenance.branchOfferID,
            constraints = provenance.branchOfferConstraints,
        }
        local predicateContext = predicateContextFor(context, ir, branchOffer)
        if type(branchOffer.constraints) == "table" then
            local result = Predicates.Evaluate(
                branchOffer.constraints, predicateContext
            )
            if result.allowed ~= true then
                return false, "suggestion_click_ineligible_"
                    .. tostring(result.status), result
            end
            return true, "eligible", result
        end
        return true, "eligible", { status = "allowed", trace = {} }
    end

    local providerID = type(frame) == "table" and frame.providerID or nil
    local extensions = type(frame) == "table"
        and type(frame.extensions) == "table" and frame.extensions or {}
    providerID = providerID or extensions.providerID
    if providerID ~= nil then
        local registry = PNC.Semantics and PNC.Semantics.DialogueChoiceRegistry
        local provider = registry and type(registry.GetProvider) == "function"
            and registry.GetProvider(providerID) or nil
        if not provider or provider.enabled == false then
            return false, "suggestion_provider_unavailable", {
                status = "unknown",
                trace = {},
            }
        end
        return true, "provider_eligible", {
            status = "allowed",
            providerID = providerID,
            trace = {},
        }
    end

    local action, definition = capabilityDefinitionFor(
        type(frame) == "table" and frame.candidateID or nil
    )
    if not action or type(definition.constraints) ~= "table" then
        return true, "eligible", { status = "allowed", trace = {} }
    end
    local predicateContext = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        predicateContext[key] = value
    end
    predicateContext.ir = copyValue(ir) or {}
    predicateContext.suggestion = {
        destination = type(frame) == "table" and frame.destination or nil,
    }
    local result = Predicates.Evaluate(definition.constraints, predicateContext)
    if result.allowed ~= true then
        return false, "suggestion_click_ineligible_" .. tostring(result.status), result
    end
    return true, "eligible", result
end


Internal.addCandidate = addCandidate
Internal.addProviderCandidate = addProviderCandidate
Internal.addBranchOfferCandidate = addBranchOfferCandidate
Internal.branchOfferFrame = branchOfferFrame
Internal.predicateContextFor = predicateContextFor
Internal.offersFromPlan = offersFromPlan
Internal.offersFromMessages = offersFromMessages

