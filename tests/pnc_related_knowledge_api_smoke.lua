local T = require "tests/support/test"

T.addPackagePaths()

local validated
local discovery
local committed
local player = {}

PNC = {
    API = {},
    PlayerContext = {
        Resolve = function(_, reason)
            return {
                characterUUID = "player-related",
                bindingRevision = 4,
                reason = reason,
            }
        end,
    },
    Registry = {
        Get = function(npcID)
            if npcID == "guard-related" or npcID == "merchant-related" then
                return { id = npcID }
            end
            return nil
        end,
    },
    Conversation = {
        Authority = {
            ValidateLease = function(target, record, token)
            validated = {
                player = target, npcID = record.id, token = token,
            }
                return true, nil, {
                    token = token,
                    processedConversationRequests = {
                        ["referral-related-1"] = {
                            success = true, choiceID = "trade",
                        },
                    },
                }
            end,
        },
    },
    NPCKnowledge = {
        DiscoverTopicForPlayer = function(
            target, npcID, topicID, _, sourceType, deferCommit
        )
            discovery = {
                player = target,
                npcID = npcID,
                topicID = topicID,
                sourceType = sourceType,
                deferCommit = deferCommit,
            }
            return { revealed = { "identity.name" }, failures = {} }
        end,
        BuildPlayerSnapshotForPlayer = function(_, npcID)
            return { npcID = npcID, revision = 7 }
        end,
    },
    PersistenceCoordinator = {
        Commit = function(reason)
            committed = reason
            return true
        end,
    },
}

T.load(
    "ProjectHoomans", "server",
    "PNC/Knowledge/PNC_NPCKnowledgeAPI.lua")

local result, reason = PNC.NPCKnowledgeAPI.DiscloseRelatedForPlayer(
    player,
    "guard-related",
    "merchant-related",
    {
        topicID = "identity_name",
        requestID = "referral-related-1",
        conversationRequestID = "referral-related-1",
        requiredChoiceID = "trade",
        conversationToken = "lease-related-1",
        origin = "conversation",
    }
)
T.truthy(result, reason or "related disclosure result")
T.equal(validated.npcID, "guard-related",
    "related disclosure validates the speaking NPC")
T.equal(validated.token, "lease-related-1",
    "related disclosure validates the active lease")
T.equal(discovery.npcID, "merchant-related",
    "related disclosure reveals the target NPC")
T.equal(discovery.topicID, "identity_name",
    "related disclosure is limited to identity")
T.equal(discovery.sourceType, "conversation_referral",
    "related disclosure preserves provenance")
T.equal(discovery.deferCommit, true,
    "related disclosure defers to the API commit boundary")
T.equal(committed, "knowledge_disclosure:referral-related-1",
    "related disclosure persists through Hoomans")
T.equal(result.snapshot.npcID, "merchant-related",
    "related disclosure returns the target snapshot")

local sameResult, sameReason =
    PNC.NPCKnowledgeAPI.DiscloseRelatedForPlayer(
        player,
        "guard-related",
        "guard-related",
        { topicID = "identity_name", conversationToken = "lease" }
    )
T.falsy(sameResult, "same-NPC referral is rejected")
T.equal(sameReason, "related_disclosure_target_required",
    "same-NPC rejection is explicit")

T.finish("pnc_related_knowledge_api_smoke")
