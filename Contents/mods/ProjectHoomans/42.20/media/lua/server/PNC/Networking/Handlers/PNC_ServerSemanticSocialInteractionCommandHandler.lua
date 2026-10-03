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

Authority.Internal = Authority.Internal or {}
Authority.Internal.SemanticSocial = {
    Authority = Authority,
    Router = Router,
    Const = Const,
    Core = Core,
    Registry = Registry,
    PlayerCharacters = PlayerCharacters,
    EntityRef = EntityRef,
    Definitions = Definitions,
    SocialEvents = SocialEvents,
    Network = Network,
    RelationshipPresentation = RelationshipPresentation,
    EVENT_TYPE_BY_SPEECH_ACT = EVENT_TYPE_BY_SPEECH_ACT,
    text = text,
    worldAgeHours = worldAgeHours,
    rejected = rejected,
    relationshipDelta = relationshipDelta,
    relationshipSummary = relationshipSummary,
    detailFor = detailFor,
    sendRelationship = sendRelationship,
}

require "PNC/Networking/Handlers/PNC_ServerSemanticSocialInteractionCommandHandler_ApplySocialEvent"
require "PNC/Networking/Handlers/PNC_ServerSemanticSocialInteractionCommandHandler_Handle"

Router.Register(Const.CMD_SEMANTIC_SOCIAL_EVENT_REQUEST, function(player, args)
    Authority.Handle(player, args)
end)

return Authority
