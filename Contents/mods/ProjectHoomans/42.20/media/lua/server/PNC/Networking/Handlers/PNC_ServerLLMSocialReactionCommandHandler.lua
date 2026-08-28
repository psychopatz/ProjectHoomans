-- Authoritative adapter for the Project Hoomans LLM social reaction tool.
-- The provider never supplies relationship deltas or a trusted target.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Registry = PNC.Registry
local Network = PNC.Network
local Presentation = PNC.RelationshipPresentation
local Tools = PNC.ConversationLLMTools
local Authority = PNC.Conversation.Authority

local MAX_ID_LENGTH = 128

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

local function summaryFor(player, npcID, relationship)
    if Presentation and Presentation.BuildForConversation then
        local summary = Presentation.BuildForConversation(player, npcID)
        if summary then return summary end
    end
    if Presentation and Presentation.Summarize then
        local summary = Presentation.Summarize(relationship, relationship ~= nil)
        summary.npcID = tostring(npcID)
        return summary
    end
    return relationship
end

local function sendResult(player, result)
    if Network and Network.SendLLMSocialReactionResult then
        Network.SendLLMSocialReactionResult(player, result)
    end
end

local function rejected(player, args, reason)
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
    sendResult(player, result)
    return result
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
    local targetKey
    local before
    local after
    local effect
    local applied
    local reason
    local details
    local result
    local idempotencyKey

    if requestID == "" then return rejected(player, args, "request_id_required") end
    if callID == "" then return rejected(player, args, "call_id_required") end
    if npcID == "" then return rejected(player, args, "npc_id_required") end
    if not reaction then return rejected(player, args, "unknown_reaction") end

    record = Registry and Registry.Get and Registry.Get(npcID) or nil
    if not record then return rejected(player, args, "npc_not_found") end

    local internal = Authority.Internal or {}
    if not internal.ValidateLease then
        return rejected(player, args, "conversation_authority_unavailable")
    end
    local leaseOK
    leaseOK, reason, lease = internal.ValidateLease(player, record, token)
    if not leaseOK then return rejected(player, args, reason) end
    if not playerOwnsLease(player, lease) then
        return rejected(player, args, "conversation_player_mismatch")
    end

    lease.llmToolCalls = lease.llmToolCalls or {}
    idempotencyKey = requestID .. ":" .. callID
    if lease.llmToolCalls[idempotencyKey] then
        result = lease.llmToolCalls[idempotencyKey]
        sendResult(player, result)
        return result
    end

    if not PNC.PlayerCharacters or not PNC.PlayerCharacters.GetEntityKey then
        return rejected(player, args, "player_identity_unavailable")
    end
    targetKey, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "llm_social_reaction",
        worldAgeHours = worldAgeHours(),
    })
    if not targetKey then return rejected(player, args, reason) end

    before = relationshipFor(npcID, targetKey) or {}
    if not Tools or not Tools.IsAvailable or not Tools.GetEffect then
        return rejected(player, args, "social_reaction_policy_unavailable")
    end
    local available, availabilityReason = Tools.IsAvailable(reaction, before)
    if not available then
        return rejected(player, args, availabilityReason)
    end
    effect, reason = Tools.GetEffect(reaction, intensity)
    if not effect then return rejected(player, args, reason) end

    local at = worldAgeHours()
    applied, reason, details = PNC.Relationships.ApplyConversationEffect(
        npcID,
        targetKey,
        effect,
        {
            blockID = "llm_social_reaction",
            choiceID = requestID,
            outcomeID = callID .. ":" .. reaction,
            worldAgeHours = at,
        }
    )
    if applied ~= true then
        return rejected(player, args, reason or "relationship_rejected")
    end

    after = relationshipFor(npcID, targetKey) or {}
    local relationshipSummary = summaryFor(player, npcID, after)
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
        relationshipRevision = relationshipSummary
            and relationshipSummary.revision or nil,
        memoryID = details and details.memoryID or nil,
    }
    lease.llmToolCalls[idempotencyKey] = result
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

return Authority
