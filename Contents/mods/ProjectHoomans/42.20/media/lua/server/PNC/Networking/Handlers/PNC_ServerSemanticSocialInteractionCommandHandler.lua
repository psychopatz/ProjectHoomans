-- Server-authoritative relationship effects for directed hostile dialogue.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.SemanticDialogueSocialAuthority =
    PNC.SemanticDialogueSocialAuthority or {}

local Authority = PNC.SemanticDialogueSocialAuthority
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local PlayerCharacters = PNC.PlayerCharacters
local EntityRef = PNC.EntityRef
local Definitions = PNC.SocialEventDefinitions
local SocialEvents = PNC.SocialEvents
local Network = PNC.Network
local RelationshipPresentation = PNC.RelationshipPresentation

local EVENT_TYPE_BY_SPEECH_ACT = {
    INSULT = "player_dialogue_insult",
    HOSTILE_REMARK = "player_dialogue_hostile_remark",
    THREATEN = "player_dialogue_threat",
}

local function text(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    return string.sub(value, 1, maximum or 128)
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function rejected(requestID, npcID, speechAct, reason)
    return {
        accepted = false,
        status = "rejected",
        requestID = requestID,
        npcID = npcID,
        speechAct = speechAct,
        reason = tostring(reason or "rejected"),
    }
end

local function relationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

local function relationshipSummary(value, exists, npcID)
    local summary
    if RelationshipPresentation
        and type(RelationshipPresentation.Summarize) == "function"
    then
        summary = RelationshipPresentation.Summarize(value, exists == true)
    else
        value = type(value) == "table" and value or {}
        summary = {
            exists = exists == true,
            approval = tonumber(value.approval) or 0,
            respect = tonumber(value.respect) or 0,
            familiarity = tonumber(value.familiarity) or 0,
            state = value.state,
            previousState = value.previousState,
            revision = tonumber(value.revision) or 0,
        }
    end
    summary = type(summary) == "table" and summary or {}
    summary.npcID = npcID
    return summary
end

local function detailFor(result, npcID, actorKey)
    local details = type(result and result.details) == "table"
        and result.details or {}
    for index = 1, #details do
        local detail = details[index]
        if tostring(detail.observerNPCID or "") == npcID
            and tostring(detail.aboutKey or "") == actorKey
        then
            return detail
        end
    end
    return nil
end

local function sendRelationship(player, npcID, requestID, eventID,
    eventType, detail)
    if not Network or type(Network.SendConversationRelationshipForNPC)
        ~= "function"
    then
        return false
    end
    local before = detail and detail.relationshipBefore or nil
    return Network.SendConversationRelationshipForNPC(
        player,
        npcID,
        "semantic_dialogue",
        {
            source = "semantic_dialogue",
            requestID = requestID,
            eventID = eventID,
            eventType = eventType,
            relationshipBefore = relationshipSummary(before, true, npcID),
            relationshipDelta = relationshipDelta(
                before,
                detail and detail.relationshipAfter or nil
            ),
        }
    )
end

function Authority.Handle(player, args)
    args = type(args) == "table" and args or {}
    local requestID = text(args.requestID, 96)
    local npcID = text(args.npcID, 128)
    local speechAct = string.upper(text(args.speechAct, 32))
    local conversationID = text(args.conversationID, 96)
    local conversationToken = text(
        args.conversationToken or args.token,
        128
    )
    local eventType = EVENT_TYPE_BY_SPEECH_ACT[speechAct]
    local record
    local body
    local validateLease
    local valid
    local reason
    local at
    local actorKey
    local targetKey
    local definition
    local eventID
    local processed
    local detail
    local beforeSummary
    local afterSummary
    local accepted

    if not Core or not Core.IsAuthority or Core.IsAuthority() ~= true then
        return rejected(requestID, npcID, speechAct, "not_authority")
    end
    if not player or player.isDead and player:isDead() then
        return rejected(requestID, npcID, speechAct, "player_unavailable")
    end
    if requestID == "" then
        return rejected(requestID, npcID, speechAct, "request_id_required")
    end
    if npcID == "" or conversationID == "" then
        return rejected(requestID, npcID, speechAct,
            "conversation_identity_required")
    end
    if not eventType then
        return rejected(requestID, npcID, speechAct,
            "unsupported_social_speech_act")
    end
    if not Registry or type(Registry.Get) ~= "function"
        or type(Registry.GetLiveZombie) ~= "function"
    then
        return rejected(requestID, npcID, speechAct,
            "npc_registry_unavailable")
    end
    record = Registry.Get(npcID)
    body = Registry.GetLiveZombie(npcID)
    if not record or record.alive == false or not body
        or body.isDead and body:isDead()
    then
        return rejected(requestID, npcID, speechAct, "npc_unavailable")
    end

    local conversationAuthority = PNC.Conversation
        and PNC.Conversation.Authority or nil
    local authorityInternal = conversationAuthority
        and conversationAuthority.Internal or nil
    validateLease = authorityInternal and authorityInternal.ValidateLease
    if type(validateLease) ~= "function" then
        return rejected(requestID, npcID, speechAct,
            "conversation_authority_unavailable")
    end
    valid, reason = validateLease(player, record, conversationToken)
    if valid ~= true then
        return rejected(requestID, npcID, speechAct,
            reason or "invalid_conversation")
    end

    if not PlayerCharacters or type(PlayerCharacters.GetEntityKey)
        ~= "function"
    then
        return rejected(requestID, npcID, speechAct,
            "player_identity_unavailable")
    end
    at = worldAgeHours()
    actorKey = PlayerCharacters.GetEntityKey(player, {
        callback = "semantic_dialogue_social",
        worldAgeHours = at,
    })
    targetKey = EntityRef and type(EntityRef.ForNPC) == "function"
        and EntityRef.ForNPC(npcID) or nil
    if not actorKey or not targetKey then
        return rejected(requestID, npcID, speechAct,
            "social_identity_unavailable")
    end
    definition = Definitions and Definitions[eventType] or nil
    if not definition
        or not definition.allowedSourceSystems
        or definition.allowedSourceSystems.semantic_dialogue ~= true
    then
        return rejected(requestID, npcID, speechAct,
            "social_event_definition_unavailable")
    end
    if not SocialEvents or type(SocialEvents.Emit) ~= "function" then
        return rejected(requestID, npcID, speechAct,
            "social_event_service_unavailable")
    end

    eventID = table.concat({
        "social:semantic_dialogue",
        tostring(actorKey),
        npcID,
        conversationID,
        requestID,
    }, ":")
    processed = SocialEvents.Emit({
        id = eventID,
        type = eventType,
        actorKey = actorKey,
        targetKey = targetKey,
        occurredAt = at,
        sourceSystem = "semantic_dialogue",
        context = {
            conversationID = conversationID,
            speechAct = speechAct,
        },
    })
    if type(processed) ~= "table" or processed.ok ~= true then
        return rejected(requestID, npcID, speechAct,
            processed and processed.reason or "social_event_rejected")
    end
    detail = detailFor(processed, npcID, actorKey)
    if detail then
        sendRelationship(
            player,
            npcID,
            requestID,
            eventID,
            eventType,
            detail
        )
    end
    beforeSummary = detail and relationshipSummary(
        detail.relationshipBefore,
        true,
        npcID
    ) or nil
    afterSummary = detail and relationshipSummary(
        detail.relationshipAfter,
        true,
        npcID
    ) or nil
    accepted = (tonumber(processed.relationshipsChanged) or 0) > 0
    return {
        accepted = accepted,
        status = accepted and "applied" or "rejected",
        reason = accepted and nil or "relationship_not_changed",
        requestID = requestID,
        npcID = npcID,
        speechAct = speechAct,
        eventID = eventID,
        eventType = eventType,
        relationshipBefore = beforeSummary,
        relationshipAfter = afterSummary,
        relationshipDelta = relationshipDelta(beforeSummary, afterSummary),
    }
end

Router.Register(Const.CMD_SEMANTIC_SOCIAL_EVENT_REQUEST, function(player, args)
    Authority.Handle(player, args)
end)

return Authority
