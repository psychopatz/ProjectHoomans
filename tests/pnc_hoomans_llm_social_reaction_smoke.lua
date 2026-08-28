local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local sent = {}
local applyCount = 0
local relation = {
    exists = true,
    state = "Acquaintance",
    approval = 10,
    respect = 10,
    familiarity = 5,
    revision = 1,
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
        } },
    },
    PlayerCharacters = {
        GetEntityKey = function() return "player:account:character-1" end,
    },
    Relationships = {
        Personal = { Queries = {
            Get = function() return relation end,
        } },
        ApplyConversationEffect = function(_, _, effect)
            applyCount = applyCount + 1
            relation.revision = relation.revision + 1
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
