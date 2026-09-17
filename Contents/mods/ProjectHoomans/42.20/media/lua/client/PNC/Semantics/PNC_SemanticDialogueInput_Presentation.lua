-- Conversation-history and response-queue presentation for semantic input.
-- The existing conversation session remains the authority for ordering and
-- TTS; this module only translates semantic results into queued messages.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local Policy = PNC.Semantics.DialoguePolicy

local function responsePayload(decision)
    local response = decision and decision.response or {}
    local fallback = tostring(response.fallback or "")
    return {
        key = response.templateID,
        domain = "pnc.system.shared.categories",
        -- Keep the authored English fallback on the live payload as well as
        -- in the keyed field.  Text.Resolve still gives a registered
        -- translation precedence, but a missing/late domain registration
        -- cannot leak an internal semantic template ID into the UI.
        text = fallback ~= "" and fallback or nil,
        fallback = fallback,
        args = response.args,
    }
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
    local response = options.response or responsePayload(decision)
    local ir = result.ir or {}
    if actionResult and type(actionResult.response) == "table" then
        response = actionResult.response
    end
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
    return true
end

return Input
