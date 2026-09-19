local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local sent = {}
local disclosures = 0
local relationship = {
    approval = 0,
    respect = 0,
    familiarity = 0,
    revision = 1,
}
local effects = {}

PNC = {
    Core = {},
    Const = {},
    Semantics = {},
    PlayerKnowledgeCommands = {
        Internal = {
            SafeID = function(value)
                value = tostring(value or "")
                return value ~= "" and value or nil
            end,
            ContextFor = function()
                return {
                    characterUUID = "char_patrick",
                    playerEntityKey = "player:sp:char_patrick",
                }
            end,
            IntroductionText = function()
                return "I'm Mara."
            end,
        },
    },
    Registry = {
        Get = function(id)
            return id == "npc_mara" and {
                id = id,
                name = "Mara Vale",
                identity = { displayName = "Mara Vale" },
            } or nil
        end,
    },
    PlayerCharacters = {
        GetRegistryRecord = function()
            return {
                displayName = "SteamAccount",
                forename = "Patrick",
                surname = "Patz",
            }
        end,
    },
    Conversation = {
        Authority = {
            Internal = {
                ValidateLease = function(_, _, token)
                    return token == "lease", token == "lease"
                        and "validated" or "invalid_lease", { token = token }
                end,
            },
        },
    },
    Relationships = {
        Get = function()
            return relationship
        end,
        ApplyConversationEffect = function(_, _, effect, context)
            effects[#effects + 1] = effect
            relationship.approval = relationship.approval
                + (tonumber(effect.approval) or 0)
            relationship.respect = relationship.respect
                + (tonumber(effect.respect) or 0)
            relationship.familiarity = relationship.familiarity
                + (tonumber(effect.familiarity) or 0)
            relationship.revision = relationship.revision + 1
            return true, "applied", {
                eventID = context.eventID,
                memoryID = context.eventID,
                memoryType = effect.memoryType,
            }
        end,
    },
    NPCKnowledgeAPI = {
        DiscloseForPlayer = function()
            disclosures = disclosures + 1
            return { revealed = { "identity.name" } }
        end,
    },
    Network = {
        SendSemanticIdentityResult = function(_, payload)
            sent[#sent + 1] = payload
        end,
        SendConversationRelationship = function() end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticIdentityExchange.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Identity.lua"
)

local Commands = PNC.PlayerKnowledgeCommands
local Identity = PNC.Semantics.IdentityExchange
local IdentityPolicy = require
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_IdentityPolicy"

local truthfulEffect, truthfulTrust = IdentityPolicy.EffectFor(
    Identity.EVENT_CLAIM,
    true
)
T.equal(truthfulEffect.memoryType, "identity_introduction",
    "truthful claim selects introduction relationship policy")
T.equal(truthfulEffect.approval, 1,
    "truthful introduction preserves its approval effect")
T.equal(truthfulEffect.respect, 2,
    "truthful introduction preserves its respect effect")
T.equal(truthfulEffect.familiarity, 6,
    "truthful introduction preserves its familiarity effect")
T.equal(truthfulTrust, nil,
    "truthful introduction does not mark the player untrustworthy")

local falseEffect, falseTrust = IdentityPolicy.EffectFor(
    Identity.EVENT_CLAIM,
    false
)
T.equal(falseEffect.memoryType, "identity_deception",
    "false claim selects deception relationship policy")
T.equal(falseEffect.approval, -4,
    "deception preserves its approval effect")
T.equal(falseEffect.respect, -6,
    "deception preserves its respect effect")
T.equal(falseTrust, Identity.TRUST_UNTRUSTWORTHY,
    "deception marks the player untrustworthy")

local evasionEffect, evasionTrust = IdentityPolicy.EffectFor(
    Identity.EVENT_EVASION
)
T.equal(evasionEffect.memoryType, "identity_evasion",
    "evasion selects its relationship policy")
T.equal(evasionEffect.approval, -2,
    "evasion preserves its approval effect")
T.equal(evasionEffect.respect, -3,
    "evasion preserves its respect effect")
T.equal(evasionTrust, Identity.TRUST_UNTRUSTWORTHY,
    "evasion marks the player untrustworthy")

local missingTruthEffect, _, missingTruthReason = IdentityPolicy.EffectFor(
    Identity.EVENT_CLAIM
)
T.equal(missingTruthEffect, nil,
    "unresolved truth cannot produce a reputation effect")
T.equal(missingTruthReason, "identity_truth_unresolved",
    "unresolved claim policy has an explicit failure reason")

local invalidEffect, _, invalidEventReason = IdentityPolicy.EffectFor(
    "unknown_identity_event",
    false
)
T.equal(invalidEffect, nil,
    "unknown identity event cannot produce a reputation effect")
T.equal(invalidEventReason, "identity_event_invalid",
    "unknown policy events have an explicit failure reason")

local invalidLeaseEffectCount = #effects
local invalidLease, invalidLeaseReason = Commands.HandleSemanticIdentity({}, {
    requestID = "identity:invalid-lease",
    npcID = "npc_mara",
    kind = Identity.EVENT_CLAIM,
    claimedName = "Patrick Patz",
    conversationToken = "stale-lease",
})
T.falsy(invalidLease, "stale semantic identity lease is rejected")
T.equal(invalidLeaseReason, "invalid_lease",
    "stale identity lease keeps its explicit rejection reason")
T.equal(#effects, invalidLeaseEffectCount,
    "stale identity lease cannot mutate relationship state")
T.equal(sent[#sent].accepted, false,
    "stale identity lease returns a rejected identity result")

local originalAuthority = PNC.Conversation.Authority
PNC.Conversation.Authority = { Internal = {} }
local missingAuthorityEffectCount = #effects
local missingAuthority, missingAuthorityReason =
    Commands.HandleSemanticIdentity({}, {
        requestID = "identity:missing-authority",
        npcID = "npc_mara",
        kind = Identity.EVENT_CLAIM,
        claimedName = "Patrick Patz",
        conversationToken = "lease",
    })
T.falsy(missingAuthority,
    "missing lease validator rejects semantic identity requests")
T.equal(missingAuthorityReason, "conversation_authority_unavailable",
    "missing validator returns an explicit authority failure")
T.equal(#effects, missingAuthorityEffectCount,
    "missing lease validator cannot mutate relationship state")
PNC.Conversation.Authority = originalAuthority

local originalApplyConversationEffect =
    PNC.Relationships.ApplyConversationEffect
PNC.Relationships.ApplyConversationEffect = nil
local missingServiceEffectCount = #effects
local missingService, missingServiceReason =
    Commands.HandleSemanticIdentity({}, {
        requestID = "identity:missing-service",
        npcID = "npc_mara",
        kind = Identity.EVENT_CLAIM,
        claimedName = "Patrick Patz",
        conversationToken = "lease",
    })
T.falsy(missingService,
    "missing relationship mutation service rejects the identity exchange")
T.equal(missingServiceReason, "relationship_service_unavailable",
    "missing mutation service has an explicit rejection reason")
T.equal(#effects, missingServiceEffectCount,
    "missing mutation service cannot change relationship state")
PNC.Relationships.ApplyConversationEffect = originalApplyConversationEffect

local truthful, truthfulPayload = Commands.HandleSemanticIdentity({}, {
    requestID = "identity:truth",
    npcID = "npc_mara",
    kind = "identity_claim",
    claimedName = "Patrick Patz",
    conversationToken = "lease",
})
T.truthy(truthful, "exact player name claim is accepted")
T.truthy(truthfulPayload.truthful, "truthful claim is marked truthful")
T.equal(truthfulPayload.responseText,
    "Nice to meet you. I'm Mara Vale.",
    "truthful claim receives the canonical NPC name")
T.equal(truthfulPayload.responseKey,
    "UI_PNC_Conversation_ToolReply_AskNameNamed_1",
    "truthful claim carries the localized NPC-name response key")
T.equal(truthfulPayload.responseArgs[1], "Mara Vale",
    "truthful claim carries the canonical NPC name as a format argument")
T.equal(disclosures, 1,
    "truthful claim commits the existing NPC identity disclosure fact")
T.truthy(effects[1].respect > 0,
    "truthful introduction improves the relationship")

local falseClaim, falsePayload = Commands.HandleSemanticIdentity({}, {
    requestID = "identity:false",
    npcID = "npc_mara",
    kind = "identity_claim",
    claimedName = "Patricia",
    conversationToken = "lease",
})
T.truthy(falseClaim, "false name claim is processed authoritatively")
T.falsy(falsePayload.truthful, "false name claim is rejected as untruthful")
T.equal(falsePayload.trustLabel, "untrustworthy",
    "false name claim creates the untrustworthy label")
T.equal(falsePayload.responseKey,
    "UI_PNC_Conversation_Identity_FalseName",
    "false name claim carries a dedicated localized response key")
T.falsy(string.find(falsePayload.responseText or "", "Mara", 1, true),
    "false name claim never discloses the NPC name")
T.truthy(effects[2].respect < 0 and effects[2].approval < 0,
    "false name claim causes reputation loss")

local evasion, evasionPayload = Commands.HandleSemanticIdentity({}, {
    requestID = "identity:evasion",
    npcID = "npc_mara",
    kind = "identity_evasion",
    conversationToken = "lease",
})
T.truthy(evasion, "identity evasion is processed authoritatively")
T.equal(evasionPayload.trustLabel, "untrustworthy",
    "identity evasion also creates the untrustworthy label")
T.truthy(effects[3].respect < 0 and effects[3].approval < 0,
    "identity evasion causes reputation loss")

T.finish("pnc_semantic_identity_exchange_smoke")
