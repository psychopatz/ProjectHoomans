-- Frame resolution and IR validation for semantic dialogue branch suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local IR = Internal.IR
local copyValue = Internal.copyValue
local normalized = Internal.normalized
local normalizedText = Internal.normalizedText
local definitionFor = Internal.definitionFor
local capabilityDefinitionFor = Internal.capabilityDefinitionFor
local projectedCapabilityFor = Internal.projectedCapabilityFor
local resolvedText = Internal.resolvedText
local predicateContextFor = Internal.predicateContextFor
local offersFromPlan = Internal.offersFromPlan
local offersFromMessages = Internal.offersFromMessages
local offersFromLifecycle = Internal.offersFromLifecycle

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
    for _, key in ipairs({
        "flowID", "nodeID", "turnID", "sourcePoolID",
        "realizationID", "eventRef",
    }) do
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

    local lifecycle = view and view.session
        and view.session.semanticInteractionLifecycle or nil
    if type(lifecycle) ~= "table" then
        local context = view and view.spec and view.spec.context or nil
        lifecycle = context and context.interactionLifecycle or nil
    end
    for _, item in ipairs(offersFromLifecycle({
        interactionLifecycle = lifecycle,
    })) do
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
    local modifiers = copyValue(source.modifiers) or {}
    if origin and origin.eventRef and source.action ~= nil then
        modifiers.encounterEpisodeID = tostring(origin.eventRef)
    end
    local extensions = copyValue(source.extensions) or {}
    if source.reference ~= nil then
        extensions.dialogueFollowUp = "CONTEXT_REFERENCE"
        extensions.topic = "conversation"
        extensions.contextQuestion = source.reference
    end
    local target
    if source.target == "SELF" and actorID ~= nil then
        target = {
            kind = "actor",
            id = actorID,
            source = "conversation",
        }
    elseif source.target ~= nil then
        target = {
            kind = "conversation_actor",
            ref = source.target,
        }
    end
    local ir = IR.New({
        kind = "semantic_suggestion_frame",
        rawText = resolvedText(
            offer.utteranceKey, offer.utteranceFallback
        ),
        normalizedText = normalizedText(offer.utteranceFallback),
        -- Event follow-up offers are executable semantic questions. Preserve
        -- the authored frame's explicit intent when present; the existing
        -- context-reference contract supplies QUESTION when the offer only
        -- carries its reference kind.
        intent = source.intent
            or source.reference and "QUESTION" or nil,
        speechAct = source.speechAct
            or source.reference and "QUESTION" or nil,
        action = source.action,
        subject = source.subject,
        target = target,
        destination = copyValue(source.destination),
        slots = slots,
        modifiers = modifiers,
        socialContext = socialContext,
        references = source.reference and { reference = source.reference } or nil,
        extensions = extensions,
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
                local sourceExtensions = copyValue(source.extensions) or {}
                if sourceExtensions.topic == nil and source.topic ~= nil then
                    sourceExtensions.topic = copyValue(source.topic)
                end
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
                    extensions = sourceExtensions,
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

return Suggestions

