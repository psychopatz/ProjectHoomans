-- Authoritative adapter for the PBrainZ social reaction tool.
-- The provider never supplies relationship deltas or a trusted target.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PNC/Networking/PNC_LLMSocialReactionPolicy"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Registry = PNC.Registry
local Relationships = PNC.Relationships
local Network = PNC.Network
local Presentation = PNC.RelationshipPresentation
local Tools = PNC.ConversationLLMTools
local Policy = PNC.Conversation
    and PNC.Conversation.LLMSocialReactionPolicy
local Authority = PNC.Conversation.Authority
Authority.Internal = Authority.Internal or {}

local MAX_ID_LENGTH = 128

local function log(event, details)
    if print then
        print("[PNC][LLM] " .. tostring(event) .. " "
            .. tostring(details or ""))
    end
end

local function text(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function socialSubtype(reaction, value)
    if not Tools or not Tools.NormalizeSubtypeForReaction then
        return nil
    end
    return Tools.NormalizeSubtypeForReaction(value, reaction)
end

local function buildReplyContext(reaction, subtype, accepted, reason)
    return {
        outcome = accepted == true and "accepted" or "rejected",
        reaction = reaction,
        subtype = subtype,
        reason = tostring(reason or (accepted and "applied" or "rejected")),
        authoritative = true,
    }
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function playerOwnsLease(player, lease)
    if not player or not lease then return false end
    if lease.playerOnlineID ~= nil and player.getOnlineID
        and tostring(lease.playerOnlineID) == tostring(player:getOnlineID())
    then
        return true
    end
    if lease.playerUsername ~= nil and player.getUsername
        and tostring(lease.playerUsername) == tostring(player:getUsername())
    then
        return true
    end
    return false
end

local function relationshipFor(npcID, targetKey)
    local relationships = PNC.Relationships
    local personal = relationships and relationships.Personal
    local queries = personal and personal.Queries or relationships
    return queries and queries.Get and queries.Get(npcID, targetKey) or nil
end

local function summaryOf(relationship, exists, npcID)
    if Presentation and Presentation.Summarize then
        local summary = Presentation.Summarize(relationship, exists == true)
        summary.npcID = tostring(npcID)
        return summary
    end
    return relationship
end

local function summaryFor(player, npcID, relationship)
    if Presentation and Presentation.BuildForConversation then
        local summary = Presentation.BuildForConversation(player, npcID)
        if summary then return summary end
    end
    return summaryOf(relationship, relationship ~= nil, npcID)
end

local function snapshotOf(relationship)
    if type(relationship) ~= "table" then return {} end
    local snapshot = {}
    for key, value in pairs(relationship) do
        if type(value) ~= "table" then snapshot[key] = value end
    end
    return snapshot
end

local function sendResult(player, result)
    if Network and Network.SendLLMSocialReactionResult then
        Network.SendLLMSocialReactionResult(player, result)
    end
end

local function rejected(player, args, reason, details)
    local reaction = Tools and Tools.NormalizeReaction
        and Tools.NormalizeReaction(args.kind or args.reaction)
        or text(args.kind or args.reaction)
    local subtype = socialSubtype(reaction, args.subtype)
    local result = {
        requestID = text(args.requestID),
        callID = text(args.callID),
        npcID = text(args.npcID),
        tool = "social_react",
        accepted = false,
        reason = tostring(reason or "rejected"),
        reaction = reaction,
        intensity = text(args.intensity),
        subtype = subtype,
        explicit = subtype == "sexual_advance",
        replyContext = buildReplyContext(
            reaction,
            subtype,
            false,
            reason
        ),
    }
    if type(details) == "table" then
        result.retryAfterWorldHours = details.retryAfterWorldHours
        result.cooldownUntil = details.cooldownUntil
        result.capabilities = details.capabilities
    end
    log(
        "social_react_rejected",
        "npc=" .. tostring(result.npcID)
            .. " request=" .. tostring(result.requestID)
            .. " call=" .. tostring(result.callID)
            .. " reaction=" .. tostring(result.reaction)
            .. " reason=" .. tostring(result.reason)
    )
    sendResult(player, result)
    return result
end

local function reserveLLMRequest(player, args)
    args = type(args) == "table" and args or {}
    local requestID = string.sub(text(args.requestID), 1, MAX_ID_LENGTH)
    local npcID = string.sub(text(args.npcID), 1, MAX_ID_LENGTH)
    local token = text(args.token)
    local record
    local internal = Authority.Internal or {}
    local ok
    local reason
    if requestID == "" then return false, "request_id_required" end
    if npcID == "" then return false, "npc_id_required" end
    record = Registry and Registry.Get and Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end
    if not internal.ReserveLLMRequest then
        return false, "conversation_authority_unavailable"
    end
    ok, reason = internal.ReserveLLMRequest(
        player,
        record,
        token,
        requestID
    )
    log(
        ok and "llm_request_reserved" or "llm_request_reserve_rejected",
        "npc=" .. npcID
            .. " request=" .. requestID
            .. " reason=" .. tostring(reason or "reserved")
    )
    return ok == true, reason
end

local function releaseLLMRequest(player, args)
    args = type(args) == "table" and args or {}
    local requestID = string.sub(text(args.requestID), 1, MAX_ID_LENGTH)
    local npcID = string.sub(text(args.npcID), 1, MAX_ID_LENGTH)
    local token = text(args.token)
    local record
    local internal = Authority.Internal or {}
    local ok
    local reason
    if requestID == "" then return false, "request_id_required" end
    if npcID == "" then return false, "npc_id_required" end
    record = Registry and Registry.Get and Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end
    if not internal.ReleaseLLMRequest then
        return false, "conversation_authority_unavailable"
    end
    ok, reason = internal.ReleaseLLMRequest(
        player,
        record,
        token,
        requestID,
        "request_completed"
    )
    log(
        ok and "llm_request_released" or "llm_request_release_rejected",
        "npc=" .. npcID
            .. " request=" .. requestID
            .. " reason=" .. tostring(reason or "released")
    )
    return ok == true, reason
end

Authority.Internal.LLMSocialReaction = {
    Authority = Authority,
    Registry = Registry,
    Relationships = Relationships,
    Network = Network,
    Presentation = Presentation,
    Tools = Tools,
    Policy = Policy,
    MAX_ID_LENGTH = MAX_ID_LENGTH,
    log = log,
    text = text,
    socialSubtype = socialSubtype,
    buildReplyContext = buildReplyContext,
    worldAgeHours = worldAgeHours,
    playerOwnsLease = playerOwnsLease,
    relationshipFor = relationshipFor,
    summaryOf = summaryOf,
    summaryFor = summaryFor,
    snapshotOf = snapshotOf,
    sendResult = sendResult,
    rejected = rejected,
}

require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_ApplyEffect"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_BuildResult"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_DeliverResult"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_LeaseLifecycle"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_AdmissionRequest"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_AdmissionLease"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_AdmissionPolicy"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_Admission"
require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_Handle"

Router.Register(
    Const.CMD_LLM_SOCIAL_REACTION,
    Authority.HandleLLMSocialReaction
)
if Const.CMD_LLM_REQUEST_RESERVE then
    Router.Register(Const.CMD_LLM_REQUEST_RESERVE, function(player, args)
        return reserveLLMRequest(player, args)
    end)
end
if Const.CMD_LLM_REQUEST_RELEASE then
    Router.Register(Const.CMD_LLM_REQUEST_RELEASE, function(player, args)
        return releaseLLMRequest(player, args)
    end)
end

return Authority
