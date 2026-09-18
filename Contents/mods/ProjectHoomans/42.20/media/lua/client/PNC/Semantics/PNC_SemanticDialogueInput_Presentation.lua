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

local function semanticTranslationKey(response)
    local templateID = tostring(response and response.templateID or "")
    if templateID == "semantic.question.identity" then
        local fallback = tostring(response and response.fallback or "")
        if string.find(string.lower(fallback), "liars", 1, true) then
            return "UI_PNC_Conversation_Semantic_QuestionIdentityWary"
        end
        if string.sub(fallback, 1, 4) == "I'm " then
            return "UI_PNC_Conversation_Semantic_QuestionIdentityKnown"
        end
        return "UI_PNC_Conversation_Semantic_QuestionIdentity"
    end
    local keys = {
        ["semantic.identity.exchange"] =
            "UI_PNC_Conversation_Semantic_IdentityExchange",
        ["semantic.social.self_reflection.friendly"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionFriendly",
        ["semantic.social.self_reflection.trusted"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionTrusted",
        ["semantic.social.self_reflection.withdrawn"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionWithdrawn",
        ["semantic.social.self_reflection.stressed"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionStressed",
        ["semantic.social.self_reflection.default"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionDefault",
        ["semantic.identity.evasion.untrustworthy"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionUntrustworthy",
        ["semantic.identity.evasion.friendly"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionFriendly",
        ["semantic.identity.evasion.withdrawn"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionWithdrawn",
        ["semantic.identity.evasion.default"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionDefault",
    }
    return keys[templateID]
end

local function localizedResponse(response)
    local fallback = tostring(response and response.fallback or "")
    local key = semanticTranslationKey(response)
    local translation = PNC.Translation
    if not key or not translation
        or type(translation.TrFormat) ~= "function"
    then
        return fallback, key
    end
    local args = type(response.args) == "table" and response.args or {}
    local firstArg = args.npcName or args.target or args.object
    if type(firstArg) == "table" then firstArg = nil end
    local ok, value = pcall(translation.TrFormat, key, fallback, firstArg)
    if ok and value ~= nil and tostring(value) ~= "" then
        return tostring(value), key
    end
    return fallback, key
end

local function responsePayload(decision)
    local response = decision and decision.response or {}
    local fallback = tostring(response.fallback or "")
    local text, translationKey = localizedResponse(response)
    return {
        key = response.templateID,
        domain = "pnc.system.shared.categories",
        -- Keep the authored English fallback on the live payload as well as
        -- in the keyed field.  Text.Resolve still gives a registered
        -- translation precedence, but a missing/late domain registration
        -- cannot leak an internal semantic template ID into the UI.
        text = text ~= "" and text or nil,
        fallback = fallback,
        args = response.args,
        translationKey = translationKey,
    }
end

local function campAcknowledgement(result, actionResult)
    local decision = result and result.decision or {}
    local action = string.upper(tostring(decision.action
        or actionResult and actionResult.action or ""))
    local phase
    if action ~= "CAMP" or not actionResult
        or actionResult.accepted ~= true
        or type(Internal.CampResponseFor) ~= "function"
    then
        return nil
    end
    phase = (actionResult.status == "pending"
        or actionResult.reason == "network_queued")
        and "pending" or "admitted"
    local text = Internal.CampResponseFor(
        actionResult,
        decision,
        phase
    )
    if not text then return nil end
    return {
        key = "semantic.camp.requested",
        domain = "pnc.system.shared.categories",
        text = text,
        fallback = text,
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
    local campResponse = campAcknowledgement(result, actionResult)
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
