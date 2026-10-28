-- Conversation-history and response-queue presentation for semantic input.
-- The existing conversation session remains the authority for ordering and
-- TTS; this module only translates semantic results into queued messages.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local ResponseAdapter = require
    "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses"
Internal.IdentityExchangeUnavailableResponse =
    ResponseAdapter.IdentityExchangeUnavailable
Internal.IdentityQuestionResponse = ResponseAdapter.IdentityQuestion

local GENERIC_OFFER_ITEMS = {
    anything = true,
    item = true,
    one = true,
    something = true,
    thing = true,
}

local function normalizedOfferQuery(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function stageGiftConsent(view, result, decision, group, session, options)
    local response = decision.response
    local responseID = type(response) == "table"
        and tostring(response.id or "") or ""
    local responseTemplateID = type(response) == "table"
        and tostring(response.templateID or "") or ""
    local interestedOffer = responseTemplateID == "semantic.offer.interested"
        or string.find(responseID, "semantic.offer.dataset.hungry_", 1, true)
        or string.find(responseTemplateID, "semantic.offer.dataset.hungry_", 1, true)
    if decision.branch ~= "OFFER_RECEIVED"
        or type(response) ~= "table"
        or not interestedOffer
    then
        return false
    end
    local ir = result and result.ir or nil
    if type(ir) ~= "table"
        or (ir.intent ~= "OFFER" and ir.speechAct ~= "OFFER")
    then
        return false
    end
    local object = type(ir.object) == "table" and ir.object or nil
    if not object or object.reference ~= nil then return false end
    local query = normalizedOfferQuery(
        object.text or object.value or object.name or object.category
    )
    if query == "" or GENERIC_OFFER_ITEMS[query] then return false end

    local lifecycle = PNC.Semantics and PNC.Semantics.GiftLifecycle or nil
    if not lifecycle or type(lifecycle.StageOfferConsent) ~= "function" then
        return false
    end

    local speakerID = options.speakerID
    local speakerName = options.speakerName
    if not speakerID and group and type(group.SpeakerFor) == "function" then
        speakerID, speakerName = group:SpeakerFor(view)
    end
    speakerID = speakerID or view.spec and view.spec.npcID
    local context = view.spec and view.spec.context or {}
    speakerName = speakerName or context.npcFullName or context.npcName
    local turnID = options.groupTurnID or group and group.activeTurn
        and group.activeTurn.id
    lifecycle.StageOfferConsent(session, {
        query = query,
        quantity = object.quantity,
        groupID = options.groupID or group and group.id,
        groupTurnID = turnID,
        sourceSequence = result.sequence,
        conversationID = session and session.conversationID,
    }, {
        npcID = speakerID,
        name = speakerName,
    }, Internal.Now and Internal.Now() or nil)
    return true
end

local function recordNPCResponseTurn(
    session, inputIR, response, decision, speakerID
)
    local context = session and session.semanticDialogueContext or nil
    if not context or type(context.RecordNPCResponse) ~= "function" then
        return false
    end
    local responseText = response and (response.text or response.fallback)
    if type(responseText) ~= "string" or responseText == "" then
        return false
    end

    local branch = decision and decision.branch or nil
    local responseSpeechAct = branch == "COMPLIMENT_RECEIVED"
        and "COMPLIMENT_RESPONSE" or "ANSWER"
    local topic = response and response.topic or nil
    topic = topic or inputIR and inputIR.extensions
        and inputIR.extensions.topic or nil
    if type(topic) == "table" then topic = topic.id or topic.key end
    if inputIR and (inputIR.intent == "ACCEPT"
            or inputIR.intent == "ACKNOWLEDGE"
            or inputIR.intent == "AGREE"
            or inputIR.intent == "THANK")
    then
        topic = context.currentTopic or context.previousTopic or topic
    end
    topic = topic or inputIR and (inputIR.subject or inputIR.action)
    if topic == nil then
        -- An acknowledgment gets its own topic in the turn state. Preserve
        -- the question topic that its response is continuing.
        topic = context.previousTopic or context.currentTopic
    end
    local responseSubject = response and response.referenceSubject
        or inputIR and inputIR.subject

    -- Keep one compact, participant-scoped discourse focus for the existing
    -- reference resolver.  This is a topic mention, not a fabricated world
    -- entity or fact; authoritative providers still answer the follow-up.
    local mentions
    -- Gameplay-action responses must not add a competing conversational topic
    -- candidate.  Existing command/task target resolution relies on the
    -- authoritative world target remaining the only candidate for "there".
    if inputIR and inputIR.action == nil
        and topic ~= nil and tostring(topic) ~= ""
    then
        local referenceTopic = response and response.referenceTopic or topic
        mentions = {
            {
                entityType = "topic",
                kind = "topic",
                concept = responseSubject
                    or "CONVERSATION_TOPIC",
                text = tostring(referenceTopic),
                value = tostring(referenceTopic),
                topic = tostring(topic),
                source = "semantic_response",
            },
        }
    end
    return context:RecordNPCResponse({
        intent = "RESPONSE",
        speechAct = responseSpeechAct,
        subject = responseSubject,
        rawText = responseText,
        extensions = {
            topic = topic,
        },
    }, {
        speaker = "npc",
        speakerID = speakerID,
        source = "semantic_response",
        branch = branch,
        topic = topic,
        mentions = mentions,
    })
end

function Internal.AppendPlayerInput(view, value, result)
    local group = view and view.groupConversation
    local session = group and type(group.PrimarySession) == "function"
        and group:PrimarySession() or view.session
    local ir = result.ir or {}
    local provenance = ir.provenance or {}
    local topic = ir.extensions and ir.extensions.topic or nil
    topic = type(topic) == "table" and (topic.id or topic.key) or topic
    local channel = provenance.parser == "semantic_navigation_frame"
        and "navigation" or "input"
    return session:append("player", value, {
        source = {
            kind = "semantic",
            channel = channel,
            route = result.decision and result.decision.route,
            branch = result.decision and result.decision.branch,
        },
        provenance = {
            provider = provenance.provider,
            parser = provenance.parser,
            pattern = provenance.pattern,
            confidence = ir.confidence,
            topic = topic,
        },
        participants = group and group.participantIDs or nil,
        groupID = group and group.id or nil,
        groupTurnID = group and group.activeTurn
            and group.activeTurn.id or nil,
    })
end

function Internal.QueueDeterministicResponse(
    view, value, result, actionResult, options
)
    options = type(options) == "table" and options or {}
    local group = options.groupConversation or view and view.groupConversation
    local session = options.session
        or group and type(group.PrimarySession) == "function"
        and group:PrimarySession()
        or view.session
    local pendingChoices = session.currentNode
        and session.currentNode.choices or session.pendingChoices
    local decision = result.decision or {}
    local presentationContext = type(Internal.ShallowContext) == "function"
        and Internal.ShallowContext(view) or {}
    -- Presentation may use the already-authoritative semantic decision for
    -- wording/microplanning, but it never feeds generated text back into NLU
    -- or gameplay authority.
    presentationContext.dialogueIR = result.ir
    presentationContext.dialogueDecision = decision
    presentationContext.interactionPlan = decision.interactionPlan
    presentationContext.utterancePlanSalt = table.concat({
        tostring(result.sequence or 0),
        tostring(decision.branch or ""),
        tostring(decision.interactionPlan
            and decision.interactionPlan.behaviorID or ""),
    }, ":")
    local responses
    if type(options.responses) == "table" and #options.responses > 0 then
        responses = options.responses
    elseif type(options.response) == "table" then
        responses = { options.response }
    else
        responses = ResponseAdapter.Payloads(decision, presentationContext)
    end
    local response = responses[1] or {}
    local ir = result.ir or {}
    if actionResult and type(actionResult.response) == "table" then
        responses = { actionResult.response }
        response = responses[1]
    end
    local generatedFlowResponse = false
    local localResponse = PNC.Semantics and PNC.Semantics.LocalResponse
    local taskResponses = Internal.TaskResponses
    local questResponses = Internal.QuestResponses
    local preserveQuestResponse = questResponses
        and type(questResponses.UseExistingResultResponse) == "function"
        and questResponses.UseExistingResultResponse(
            actionResult, actionResult and actionResult.action)
    if preserveQuestResponse then
        -- The authoritative quest-result spoke owns both accepted and rejected
        -- wording. Never leak the generated admission line or add a second
        -- generic ActionRejected line while its result is pending.
        return true
    end
    local preserveTaskResponse = taskResponses
        and type(taskResponses.UseExistingResultResponse) == "function"
        and taskResponses.UseExistingResultResponse(
            actionResult, nil, actionResult and actionResult.action)
    local flowResultApplied = result.flow
        and result.flow.generated == true
        and (result.flow.resultNodeId ~= nil
            or result.flow.gate
            and result.flow.gate.status == "FAIL")
        and actionResult
        and (actionResult.status ~= "semantic_dispatch_blocked"
            or result.flow.resultNodeId == "rejected"
            or result.flow.resultNodeId == "failed"
            or result.flow.gate
            and result.flow.gate.status == "FAIL")
    local actionAccepted = not (ir and ir.action)
        or actionResult and actionResult.accepted == true
        or flowResultApplied
    if not (actionResult and type(actionResult.response) == "table")
        and result.flow and result.flow.matched == true
        and ir and ir.action ~= nil
        and actionAccepted
        and preserveTaskResponse ~= true
        and type(result.flow.responsePool) == "string"
        and localResponse
        and type(localResponse.ResolveFlow) == "function"
    then
        local flowResponse = localResponse.ResolveFlow(
            ir,
            session and session.semanticDialogueState,
            presentationContext,
            result.flow
        )
        if type(flowResponse) == "table" then
            responses = {
                ResponseAdapter.Payload(
                    { response = flowResponse }, presentationContext
                ),
            }
            response = responses[1]
            generatedFlowResponse = true
        end
    end
    local rejectedResponse
    if not generatedFlowResponse
        and not (actionResult and type(actionResult.response) == "table")
    then
        rejectedResponse = ResponseAdapter.ActionRejected(
            result, actionResult
        )
    end
    if rejectedResponse then
        responses = { rejectedResponse }
        response = rejectedResponse
    end
    local campResponse = ResponseAdapter.CampAcknowledgement(
        result, actionResult)
    if campResponse then
        responses = { campResponse }
        response = campResponse
    end
    if actionResult and (actionResult.status == "gift_transfer_pending"
            or actionResult.status == "gift_transferred")
    then
        -- The authoritative gift result will append the natural response when
        -- the server confirms the transfer. Do not put an empty/pending line
        -- in front of it.
        return true
    end
    if actionResult
        and actionResult.status == "conversation_recruitment_pending"
    then
        -- The production recruitment result owns the NPC reply. The request
        -- may resolve synchronously in the harness or later through the native
        -- network result router, so never add a generic local acknowledgement.
        return true
    end
    if decision.branch == "INVENTORY_QUERY_RECEIVED"
        and actionResult
        and actionResult.accepted == false
        and actionResult.reason == "inventory_query_pending_limit"
    then
        -- The bounded pending map already prevents another request. Do not
        -- add a generic action failure beside the next authoritative result.
        return true
    end
    if actionResult and actionResult.accepted == false
        and actionResult.status ~= "unmapped"
        and actionResult.status ~= "skipped"
        and type(actionResult.response) ~= "table"
    then
        -- The existing dispatcher rejected the request. The explicit
        -- ActionRejected response above keeps the NPC wording truthful and
        -- prevents the policy's pre-dispatch acknowledgement from leaking.
        -- A task/gift adapter may still own a more specific response.
        if not rejectedResponse and not generatedFlowResponse then return true end
    end
    if decision.branch == "INVENTORY_QUERY_RECEIVED"
        and actionResult and actionResult.result
        and actionResult.result.status ~= "pending"
    then
        -- Singleplayer delivers the authoritative projection synchronously;
        -- the result spoke already queued the concrete answer. Multiplayer
        -- does the same when its server command arrives.
        return true
    end
    local topic = ir.extensions and ir.extensions.topic or nil
    topic = type(topic) == "table" and (topic.id or topic.key) or topic
    session.pendingChoices = pendingChoices
    session.pendingNext = nil
    session.pendingClose = nil
    session.pendingCloseReason = nil
    local speakerID = options.speakerID
    local speakerName = options.speakerName
    if not speakerID and group and type(group.SpeakerFor) == "function" then
        speakerID, speakerName = group:SpeakerFor(view)
    end
    stageGiftConsent(view, result, decision, group, session, options)
    local responseTexts = {}
    local responseFallbacks = {}
    local responseIndex
    local payload
    for responseIndex, payload in ipairs(responses) do
        session:queueMessage("npc", payload, {
            speakerID = speakerID,
            speakerName = speakerName,
            npcID = speakerID or view.spec and view.spec.npcID,
            participants = options.participants
                or group and group.participantIDs or nil,
            source = {
                kind = "semantic",
                channel = "response",
                branch = decision.branch,
                action = decision.action,
                topic = topic,
                actionResult = actionResult,
                input = tostring(value or ""),
                planTurn = payload.planTurn or responseIndex,
                planContinuation = payload.planContinuation,
                groupID = options.groupID or group and group.id,
                groupTurnID = options.groupTurnID or group
                    and group.activeTurn and group.activeTurn.id,
            },
            provenance = {
                provider = "lua",
                parser = "semantic_dialogue_policy",
                branch = decision.branch,
                planTurn = payload.planTurn or responseIndex,
                planContinuation = payload.planContinuation,
                groupID = options.groupID or group and group.id,
                groupTurnID = options.groupTurnID or group
                    and group.activeTurn and group.activeTurn.id,
            },
        })
        if payload.text ~= nil and tostring(payload.text) ~= "" then
            responseTexts[#responseTexts + 1] = tostring(payload.text)
        end
        if payload.fallback ~= nil and tostring(payload.fallback) ~= "" then
            responseFallbacks[#responseFallbacks + 1] = tostring(payload.fallback)
        end
    end
    local responseForContext = response
    if #responseTexts > 1 then
        responseForContext = {
            text = table.concat(responseTexts, " "),
            fallback = table.concat(responseFallbacks, " "),
        }
    end
    recordNPCResponseTurn(
        session,
        ir,
        responseForContext,
        decision,
        speakerID
    )
    return true
end

return Input
