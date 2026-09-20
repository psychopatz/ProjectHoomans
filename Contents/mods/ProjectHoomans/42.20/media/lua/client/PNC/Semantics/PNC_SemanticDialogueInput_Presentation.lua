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
    if decision.branch ~= "OFFER_RECEIVED"
        or type(decision.response) ~= "table"
        or decision.response.templateID ~= "semantic.offer.interested"
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
    local topic = inputIR and inputIR.extensions
        and inputIR.extensions.topic or nil
    if type(topic) == "table" then topic = topic.id or topic.key end
    topic = topic or inputIR and (inputIR.subject or inputIR.action)
    if topic == nil then
        -- An acknowledgment gets its own topic in the turn state. Preserve
        -- the question topic that its response is continuing.
        topic = context.previousTopic or context.currentTopic
    end
    return context:RecordNPCResponse({
        intent = "RESPONSE",
        speechAct = responseSpeechAct,
        subject = inputIR and inputIR.subject,
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
    return session:append("player", value, {
        source = {
            kind = "semantic",
            channel = "input",
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
    local response = options.response or ResponseAdapter.Payload(decision)
    local ir = result.ir or {}
    if actionResult and type(actionResult.response) == "table" then
        response = actionResult.response
    end
    local campResponse = ResponseAdapter.CampAcknowledgement(
        result, actionResult)
    if campResponse then response = campResponse end
    if actionResult and (actionResult.status == "gift_transfer_pending"
            or actionResult.status == "gift_transferred")
    then
        -- The authoritative gift result will append the natural response when
        -- the server confirms the transfer. Do not put an empty/pending line
        -- in front of it.
        return true
    end
    if actionResult and actionResult.accepted == false
        and actionResult.status ~= "unmapped"
        and actionResult.status ~= "skipped"
        and type(actionResult.response) ~= "table"
    then
        -- DispatchAction has already converted the authoritative rejection
        -- into a task-result message. Do not append a misleading "Okay."
        return true
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
    session:queueMessage("npc", response, {
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
            groupID = options.groupID or group and group.id,
            groupTurnID = options.groupTurnID or group
                and group.activeTurn and group.activeTurn.id,
        },
        provenance = {
            provider = "lua",
            parser = "semantic_dialogue_policy",
            branch = decision.branch,
            groupID = options.groupID or group and group.id,
            groupTurnID = options.groupTurnID or group
                and group.activeTurn and group.activeTurn.id,
        },
    })
    recordNPCResponseTurn(session, ir, response, decision, speakerID)
    return true
end

return Input
