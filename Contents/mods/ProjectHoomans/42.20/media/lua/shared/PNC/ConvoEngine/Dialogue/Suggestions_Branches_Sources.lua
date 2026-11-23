-- Branch offer source extraction and predicate context helpers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Suggestions = PNC.ConvoEngine.DialogueSuggestions
local Internal = Suggestions.Internal

local copyValue = Internal.copyValue
local predicateIR = Internal.predicateIR

local function responseCatalog()
    local catalog = PNC.ConvoEngine.ResponseCatalog
    if type(catalog) == "table"
        and type(catalog.OffersForSelection) == "function"
    then
        return catalog
    end
    local loaded = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
    if type(loaded) == "table"
        and type(loaded.OffersForSelection) == "function"
    then
        return loaded
    end
    return nil
end

local function dialogueSituation()
    local sit = PNC.ConvoEngine.DialogueSituation
    if type(sit) == "table" and type(sit.Internal) == "table"
        and type(sit.Internal.ResolveInjuryState) == "function"
    then
        return sit
    end
    local loaded = require "PNC/ConvoEngine/Dialogue/Situation"
    if type(loaded) == "table" then return loaded end
    return nil
end

local function predicateContextFor(context, ir, offer)
    local predicateContext = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        predicateContext[key] = value
    end
    local sit = dialogueSituation()
    local resolveInjury = sit and sit.Internal and sit.Internal.ResolveInjuryState
    local injury = type(resolveInjury) == "function"
        and resolveInjury(predicateContext) or nil
    if type(injury) == "table" then
        local npcState = {}
        for k, v in pairs(type(predicateContext.npcState) == "table" and predicateContext.npcState or {}) do
            npcState[k] = v
        end
        for k, v in pairs(injury) do
            if npcState[k] == nil then npcState[k] = v end
        end
        predicateContext.npcState = npcState
        local wk = {}
        for k, v in pairs(type(predicateContext.worldKnowledge) == "table" and predicateContext.worldKnowledge or {}) do
            wk[k] = v
        end
        if wk.salivaTransmissible == nil then
            wk.salivaTransmissible = injury.salivaTransmissible
        end
        predicateContext.worldKnowledge = wk
    end
    local beat = predicateContext.interactionLifecycle
        and predicateContext.interactionLifecycle.activeBeat or nil
    local beatCtx = beat and type(beat.context) == "table" and beat.context or nil
    if type(predicateContext.scene) ~= "table" then
        local pCount = tonumber(predicateContext.participantCount)
            or (beatCtx and tonumber(beatCtx.participantCount))
            or 0
        if pCount > 0 then
            predicateContext.scene = {
                participantCount = pCount,
                hasThirdPartyWitness = pCount >= 3,
            }
        end
    elseif predicateContext.scene.hasThirdPartyWitness == nil
        and tonumber(predicateContext.scene.participantCount) ~= nil
    then
        predicateContext.scene.hasThirdPartyWitness =
            tonumber(predicateContext.scene.participantCount) >= 3
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

local function offersFromPlan(plan)
    if type(plan) ~= "table" or type(plan.turns) ~= "table" then
        return {}
    end
    local output = {}
    for turnIndex = 1, #plan.turns do
        local turn = plan.turns[turnIndex]
        for offerIndex = 1, #(turn.offers or {}) do
            local offer = turn.offers[offerIndex]
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
    local offers = catalog and catalog.OffersForSelection(planID, realizationID) or {}
    if beat.flowID == "combat.injury.triage_exchange" then
        local triage = require "PNC/ConvoEngine/Dialogue/InjuryTriageOffers"
        local projected = triage.ForPlan(planID)
        if #projected > 0 then offers = projected end
    end
    local output = {}
    for index, offer in ipairs(offers) do
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

Internal.responseCatalog = responseCatalog
Internal.predicateContextFor = predicateContextFor
Internal.branchOfferFrame = branchOfferFrame
Internal.offersFromPlan = offersFromPlan
Internal.offersFromMessages = offersFromMessages
Internal.offersFromLifecycle = offersFromLifecycle

return Suggestions
