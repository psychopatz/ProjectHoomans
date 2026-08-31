-- Authoritative adapter for the Project Hoomans LLM social reaction tool.
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
local Network = PNC.Network
local Presentation = PNC.RelationshipPresentation
local Tools = PNC.ConversationLLMTools
local Policy = PNC.Conversation
    and PNC.Conversation.LLMSocialReactionPolicy
local Authority = PNC.Conversation.Authority

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
    local result = {
        requestID = text(args.requestID),
        callID = text(args.callID),
        npcID = text(args.npcID),
        tool = "social_react",
        accepted = false,
        reason = tostring(reason or "rejected"),
        reaction = text(args.kind or args.reaction),
        intensity = text(args.intensity),
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

local function handle(player, args)
    args = type(args) == "table" and args or {}
    local requestID = string.sub(text(args.requestID), 1, MAX_ID_LENGTH)
    local callID = string.sub(text(args.callID), 1, MAX_ID_LENGTH)
    local npcID = string.sub(text(args.npcID), 1, MAX_ID_LENGTH)
    local token = text(args.token)
    local reaction = Tools and Tools.NormalizeReaction
        and Tools.NormalizeReaction(args.kind or args.reaction) or nil
    local intensity = Tools and Tools.NormalizeIntensity
        and Tools.NormalizeIntensity(args.intensity) or "normal"
    local record
    local lease
    local pendingRequest
    local targetKey
    local before
    local beforeExists
    local after
    local effect
    local applied
    local reason
    local details
    local capabilities
    local at
    local cooldownType
    local cooldownUntil
    local result
    local idempotencyKey

    if requestID == "" then return rejected(player, args, "request_id_required") end
    if callID == "" then return rejected(player, args, "call_id_required") end
    if npcID == "" then return rejected(player, args, "npc_id_required") end
    if not reaction then return rejected(player, args, "unknown_reaction") end

    record = Registry and Registry.Get and Registry.Get(npcID) or nil
    if not record then return rejected(player, args, "npc_not_found") end

    local internal = Authority.Internal or {}
    if not internal.ValidateLLMRequest and not internal.ValidateLease then
        return rejected(player, args, "conversation_authority_unavailable")
    end
    local leaseOK
    if internal.ValidateLLMRequest then
        leaseOK, reason, lease = internal.ValidateLLMRequest(
            player,
            record,
            token,
            requestID
        )
    else
        leaseOK, reason, lease = internal.ValidateLease(player, record, token)
    end
    if not leaseOK then return rejected(player, args, reason) end
    if not playerOwnsLease(player, lease) then
        return rejected(player, args, "conversation_player_mismatch")
    end

    lease.llmToolCalls = lease.llmToolCalls or {}
    idempotencyKey = requestID .. ":" .. callID
    if lease.llmToolCalls[idempotencyKey] then
        result = lease.llmToolCalls[idempotencyKey]
        log(
            "social_react_duplicate",
            "npc=" .. npcID .. " request=" .. requestID
                .. " call=" .. callID
        )
        sendResult(player, result)
        return result
    end
    pendingRequest = lease.requestID ~= nil
    if pendingRequest and lease.consumed == true then
        return rejected(player, args, "llm_request_consumed")
    end

    if not PNC.PlayerCharacters or not PNC.PlayerCharacters.GetEntityKey then
        return rejected(player, args, "player_identity_unavailable")
    end
    targetKey, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "llm_social_reaction",
        worldAgeHours = worldAgeHours(),
    })
    if not targetKey then return rejected(player, args, reason) end

    local beforeRelationship = relationshipFor(npcID, targetKey)
    beforeExists = beforeRelationship ~= nil
    before = snapshotOf(beforeRelationship)
    log(
        "social_react_received",
        "npc=" .. npcID .. " request=" .. requestID
            .. " call=" .. callID .. " reaction=" .. tostring(reaction)
            .. " intensity=" .. tostring(intensity)
            .. " target=" .. tostring(targetKey)
            .. " before_approval=" .. tostring(before.approval or 0)
            .. " before_respect=" .. tostring(before.respect or 0)
    )
    if not Tools or not Tools.GetEffect or not Policy
        or not Policy.Evaluate
    then
        return rejected(player, args, "social_reaction_policy_unavailable")
    end
    at = worldAgeHours()
    local available, availabilityReason, availabilityDetails =
        Policy.Evaluate(reaction, record, player, beforeRelationship, at)
    if not available then
        capabilities = Policy.BuildCapabilities
            and Policy.BuildCapabilities(
                record, player, beforeRelationship, at
            ) or nil
        if type(availabilityDetails) ~= "table" then
            availabilityDetails = {}
        end
        availabilityDetails.capabilities = capabilities
        return rejected(player, args, availabilityReason, availabilityDetails)
    end
    effect, reason = Tools.GetEffect(reaction, intensity)
    if not effect then return rejected(player, args, reason) end

    cooldownType, cooldownUntil = Policy.CooldownMutation(reaction, at)
    applied, reason, details = PNC.Relationships.ApplyConversationEffect(
        npcID,
        targetKey,
        effect,
        {
            blockID = "llm_social_reaction",
            choiceID = requestID,
            outcomeID = callID .. ":" .. reaction,
            interactionType = effect.interactionType
                or effect.memoryType or effect.type,
            worldAgeHours = at,
            cooldownType = cooldownType,
            cooldownUntil = cooldownUntil,
        }
    )
    if applied ~= true then
        log(
            "social_react_apply_failed",
            "npc=" .. npcID .. " request=" .. requestID
                .. " call=" .. callID .. " reaction=" .. reaction
                .. " reason=" .. tostring(reason or "relationship_rejected")
        )
        return rejected(player, args, reason or "relationship_rejected")
    end

    after = relationshipFor(npcID, targetKey) or {}
    local relationshipSummary = summaryFor(player, npcID, after)
    local relationshipBefore = summaryOf(before, beforeExists, npcID)
    local relationshipAfter = relationshipSummary
        or summaryOf(after, true, npcID)
    capabilities = Policy.BuildCapabilities
        and Policy.BuildCapabilities(record, player, after, at) or nil
    local relationshipDelta = {
        approval = (tonumber(after.approval) or 0)
            - (tonumber(before.approval) or 0),
        respect = (tonumber(after.respect) or 0)
            - (tonumber(before.respect) or 0),
        familiarity = (tonumber(after.familiarity) or 0)
            - (tonumber(before.familiarity) or 0),
    }
    result = {
        requestID = requestID,
        callID = callID,
        npcID = npcID,
        tool = "social_react",
        accepted = true,
        reason = reason or "applied",
        reaction = reaction,
        intensity = intensity,
        relationship = relationshipSummary,
        relationshipBefore = relationshipBefore,
        relationshipAfter = relationshipAfter,
        relationshipDelta = relationshipDelta,
        relationshipRevision = relationshipSummary
            and relationshipSummary.revision or nil,
        memoryID = details and details.memoryID or nil,
        memoryType = details and details.memoryType or nil,
        interactionType = details and details.interactionType or nil,
        eventID = details and details.eventID or nil,
        capabilities = capabilities,
        policyVersion = Policy.VERSION,
        cooldownType = cooldownType,
        cooldownUntil = cooldownUntil,
        approvalDelta = relationshipDelta.approval,
        respectDelta = relationshipDelta.respect,
        familiarityDelta = relationshipDelta.familiarity,
    }
    lease.llmToolCalls[idempotencyKey] = result
    if pendingRequest then
        lease.consumed = true
        lease.consumedAt = getTimeInMillis and getTimeInMillis() or nil
    end
    log(
        "social_react_applied",
        "npc=" .. npcID .. " request=" .. requestID
            .. " call=" .. callID .. " reaction=" .. reaction
            .. " memory=" .. tostring(result.memoryID or "")
            .. " event=" .. tostring(details and details.eventID or "")
            .. " after_approval=" .. tostring(after.approval or 0)
            .. " after_respect=" .. tostring(after.respect or 0)
            .. " revision=" .. tostring(result.relationshipRevision or "")
    )
    sendResult(player, result)
    if Network and Network.SendConversationRelationship then
        Network.SendConversationRelationship(
            player,
            relationshipSummary,
            "llm_social_reaction"
        )
    end
    return result
end

Authority.HandleLLMSocialReaction = handle
Router.Register(Const.CMD_LLM_SOCIAL_REACTION, handle)
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
