local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local sent = {}
local applyCount = 0
local appliedEffect
local appliedContext
local relation = {
    exists = true,
    state = "Acquaintance",
    approval = 10,
    respect = 10,
    familiarity = 5,
    revision = 1,
    cooldowns = {},
}
local player = {
    getUsername = function() return "Tester" end,
    getOnlineID = function() return 7 end,
}
local record = {
    id = "npc-tool",
    alive = true,
    runtime = {
        conversationLease = {
            token = "lease-token",
            playerUsername = "Tester",
            playerOnlineID = 7,
        },
    },
}

getGameTime = function()
    return { getWorldAgeHours = function() return 20 end }
end

PNC = {
    Const = { CMD_LLM_SOCIAL_REACTION = "LLMSocialReaction" },
    ServerCommandRouter = {},
    Registry = { Get = function(id) return id == record.id and record or nil end },
    Network = {
        SendLLMSocialReactionResult = function(_, result)
            sent[#sent + 1] = result
            return true
        end,
        SendConversationRelationship = function() return true end,
    },
    Conversation = {
        Authority = { Internal = {
            ValidateLease = function(_, receivedRecord, token)
                if receivedRecord ~= record or token ~= "lease-token" then
                    return false, "invalid_lease"
                end
                return true, "renewed", receivedRecord.runtime.conversationLease
            end,
            ValidateLLMRequest = function(_, receivedRecord, token, requestID)
                if requestID == "pending-request"
                    and receivedRecord == record
                    and token == "lease-token"
                then
                    return true, "reserved", receivedRecord.runtime.llmRequestLease
                end
                return PNC.Conversation.Authority.Internal.ValidateLease(
                    _, receivedRecord, token
                )
            end,
        } },
    },
    PlayerCharacters = {
        GetEntityKey = function() return "player:account:character-1" end,
    },
    Relationships = {
        Personal = { Queries = {
            Get = function() return relation end,
        } },
        ApplyConversationEffect = function(_, _, effect, context)
            applyCount = applyCount + 1
            appliedEffect = effect
            appliedContext = context
            relation.approval = relation.approval + (effect.approval or 0)
            relation.respect = relation.respect + (effect.respect or 0)
            relation.familiarity = relation.familiarity + (effect.familiarity or 0)
            relation.revision = relation.revision + 1
            if context.cooldownType and context.cooldownUntil then
                relation.cooldowns[context.cooldownType] =
                    context.cooldownUntil
            end
            return true, "applied", { memoryID = "memory-1" }
        end,
    },
}

T.load(SHARED .. "PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load(SHARED .. "PNC/Conversation/PNC_ConversationLLMTools.lua")
T.load(SERVER .. "PNC/Networking/PNC_ServerCommandRouter.lua")
T.load(SERVER .. "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler.lua")

local Authority = PNC.Conversation.Authority
local accepted = Authority.HandleLLMSocialReaction(player, {
    requestID = "request-1",
    callID = "call-1",
    npcID = record.id,
    token = "lease-token",
    kind = "comfort",
    intensity = "normal",
})
T.truthy(accepted.accepted, "social reaction accepted")
T.equal(accepted.reaction, "comfort", "reaction normalized")
T.equal(applyCount, 1, "relationship effect applied once")
T.truthy(sent[1] and sent[1].relationship, "bounded result returned")
T.equal(appliedContext.cooldownType, "llm_positive_social",
    "positive reaction carries the shared cooldown into mutation")
T.equal(appliedContext.cooldownUntil, 44,
    "positive reaction cooldown is one in-game day")
T.equal(accepted.capabilities.positive_action_cooldown_active, true,
    "accepted result reports the positive cooldown")

local positiveBlocked = Authority.HandleLLMSocialReaction(player, {
    requestID = "request-positive-blocked",
    callID = "call-positive-blocked",
    npcID = record.id,
    token = "lease-token",
    kind = "admire",
    intensity = "normal",
})
T.falsy(positiveBlocked.accepted,
    "a second positive reaction is blocked during the shared cooldown")
T.equal(positiveBlocked.reason, "positive_cooldown_active",
    "positive cooldown rejection is diagnostic")
T.equal(positiveBlocked.retryAfterWorldHours, 24,
    "cooldown rejection tells the LLM when it can retry")

local duplicate = Authority.HandleLLMSocialReaction(player, {
    requestID = "request-1",
    callID = "call-1",
    npcID = record.id,
    token = "lease-token",
    kind = "comfort",
    intensity = "normal",
})
T.truthy(duplicate.accepted, "duplicate returns original result")
T.equal(applyCount, 1, "duplicate does not mutate relationship twice")

local insult = Authority.HandleLLMSocialReaction(player, {
    requestID = "request-3",
    callID = "call-3",
    npcID = record.id,
    token = "lease-token",
    kind = "insult",
    intensity = "normal",
})
T.truthy(insult.accepted, "insult reaction accepted")
T.equal(applyCount, 2, "insult relationship effect applied")
T.equal(appliedEffect.memoryType, "player_insulted",
    "insult creates a named player-insulted memory")
T.equal(appliedEffect.interactionType, "player_insulted",
    "insult creates a named interaction event")
T.equal(appliedEffect.approval, -4, "insult lowers approval")
T.equal(appliedEffect.respect, -3, "insult lowers respect")
T.equal(appliedContext.interactionType, "player_insulted",
    "named interaction type reaches the mutation boundary")
T.equal(insult.relationshipDelta.approval, -4,
    "authoritative result reports the applied approval delta")
T.equal(insult.relationshipDelta.respect, -3,
    "authoritative result reports the applied respect delta")
T.equal(insult.relationshipDelta.familiarity, 0,
    "authoritative result reports the applied familiarity delta")
T.equal(insult.relationshipBefore.approval, 13,
    "authoritative result preserves the pre-mutation relationship")
T.equal(insult.relationshipAfter.approval, 9,
    "authoritative result exposes the post-mutation relationship")
T.equal(insult.capabilities.available_reactions[1], "insult",
    "insult remains available while positive actions are cooling down")

record.runtime.llmRequestLease = {
    requestID = "pending-request",
    token = "lease-token",
    playerUsername = "Tester",
    playerOnlineID = 7,
    llmToolCalls = {},
    consumed = false,
}
local pendingInsult = Authority.HandleLLMSocialReaction(player, {
    requestID = "pending-request",
    callID = "pending-call",
    npcID = record.id,
    token = "lease-token",
    kind = "insult",
    intensity = "normal",
})
T.truthy(pendingInsult.accepted,
    "reserved request applies its social reaction after UI close")
T.equal(record.runtime.llmRequestLease.consumed, true,
    "reserved request is consumed exactly once")
local secondPendingCall = Authority.HandleLLMSocialReaction(player, {
    requestID = "pending-request",
    callID = "pending-call-2",
    npcID = record.id,
    token = "lease-token",
    kind = "insult",
    intensity = "normal",
})
T.falsy(secondPendingCall.accepted,
    "a consumed request rejects a second distinct tool call")
T.equal(secondPendingCall.reason, "llm_request_consumed",
    "consumed request rejection is diagnostic")

relation.cooldowns = {}
local admire = Authority.HandleLLMSocialReaction(player, {
    requestID = "request-admire",
    callID = "call-admire",
    npcID = record.id,
    token = "lease-token",
    kind = "admire",
    intensity = "normal",
})
T.truthy(admire.accepted, "admire reaches the authoritative mutation path")
T.equal(appliedEffect.memoryType, "player_admired",
    "admire creates a typed relationship memory")
T.equal(appliedEffect.interactionType, "player_admired",
    "admire creates a typed interaction event")

relation.state = "Acquaintance"
relation.approval = 10
relation.familiarity = 5
local gated = Authority.HandleLLMSocialReaction(player, {
    requestID = "request-2",
    callID = "call-2",
    npcID = record.id,
    token = "lease-token",
    kind = "flirt",
    intensity = "normal",
})
T.falsy(gated.accepted, "flirt is relationship-gated")
T.equal(gated.reason, "relationship_gate", "relationship gate reason")

T.finish("pnc_hoomans_llm_social_reaction_smoke")
