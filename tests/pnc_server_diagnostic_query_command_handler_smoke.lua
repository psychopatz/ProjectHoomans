local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local player = {
    access = "",
    getAccessLevel = function(self) return self.access end,
}
local rosterCall
local relationshipCall
local conversationCall
local knowledgeCalls = {}
local knowledgeDebugCall
local audited
local relationshipArgs
local debugArgs
local discovered

PNC = {
    Const = {
        CMD_DEBUG_ROSTER_REQUEST = "DebugRosterRequest",
        CMD_RELATIONSHIP_DEBUG_REQUEST = "RelationshipDebugRequest",
        CMD_CONVERSATION_RELATIONSHIP_REQUEST = "ConversationRelationshipRequest",
        CMD_NPC_KNOWLEDGE_REQUEST = "NPCKnowledgeRequest",
        CMD_KNOWLEDGE_DEBUG_REQUEST = "KnowledgeDebugRequest",
    },
    Core = { Now = function() return 123 end },
    BodyLifecycle = {
        LastAudit = { marker = "audit" },
        AuditLoadedBodies = function(now, forced)
            audited = { now = now, forced = forced }
        end,
        BuildDebugRoster = function()
            return { { id = "npc-1" } }
        end,
    },
    Network = {
        SendDebugRoster = function(...)
            rosterCall = { ... }
        end,
        SendRelationshipDebug = function(...)
            relationshipCall = { ... }
        end,
        SendConversationRelationship = function(...)
            conversationCall = { ... }
        end,
        SendNPCKnowledge = function(...)
            knowledgeCalls[#knowledgeCalls + 1] = { ... }
        end,
        SendKnowledgeDebug = function(...)
            knowledgeDebugCall = { ... }
        end,
    },
    RelationshipDebug = {
        BuildSnapshotForRequest = function(receivedPlayer, args)
            relationshipArgs = args
            return { kind = "relationship" }, "relationship_reason"
        end,
    },
    RelationshipPresentation = {
        BuildForConversation = function(receivedPlayer, npcID)
            return { npcID = npcID }, "conversation_reason"
        end,
    },
    NPCKnowledge = {
        BuildKnownSnapshotsForPlayer = function()
            return { { id = "known-1" }, { id = "known-2" } }, "ignored"
        end,
        DiscoverTopicForPlayer = function(receivedPlayer, npcID, topicID,
                sourcePlayer, source)
            discovered = {
                player = receivedPlayer,
                npcID = npcID,
                topicID = topicID,
                sourcePlayer = sourcePlayer,
                source = source,
            }
            return true, "disclosed"
        end,
        BuildPlayerSnapshotForPlayer = function(receivedPlayer, npcID)
            return { npcID = npcID }, "snapshot_reason"
        end,
        BuildDebugSnapshotForPlayer = function(receivedPlayer, npcID,
                showTruth, descriptorID)
            debugArgs = {
                player = receivedPlayer,
                npcID = npcID,
                showTruth = showTruth,
                descriptorID = descriptorID,
            }
            return { kind = "knowledge_debug" }, "debug_reason"
        end,
    },
}

isServer = function() return true end

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerDiagnosticQueryCommandHandler"

Router.Handle("DebugRosterRequest", player, { audit = true })
T.equal(rosterCall[1], player, "unauthorized roster player")
T.equal(#rosterCall[2], 0, "unauthorized roster not empty")
T.equal(rosterCall[3], false, "unauthorized roster authorized")
T.equal(rosterCall[4], PNC.BodyLifecycle.LastAudit,
    "unauthorized roster audit")
T.equal(audited, nil, "unauthorized roster ran audit")

player.access = "admin"
Router.Handle("DebugRosterRequest", player, { audit = true })
T.equal(audited.now, 123, "roster audit time")
T.equal(audited.forced, true, "roster audit force")
T.equal(rosterCall[2][1].id, "npc-1", "authorized roster payload")
T.equal(rosterCall[3], true, "authorized roster flag")

player.access = ""
Router.Handle("RelationshipDebugRequest", player, nil)
T.equal(relationshipCall[2], nil, "unauthorized relationship snapshot")
T.equal(relationshipCall[3], false, "unauthorized relationship flag")
T.equal(relationshipCall[4], "not_authorized",
    "unauthorized relationship reason")

player.access = "admin"
local requestArgs = { npcID = "npc-2" }
Router.Handle("RelationshipDebugRequest", player, requestArgs)
T.equal(relationshipArgs, requestArgs, "relationship payload identity")
T.equal(relationshipCall[2].kind, "relationship",
    "relationship snapshot")
T.equal(relationshipCall[4], "relationship_reason",
    "relationship reason")

Router.Handle("ConversationRelationshipRequest", player, requestArgs)
T.equal(conversationCall[2].npcID, "npc-2",
    "conversation relationship NPC")
T.equal(conversationCall[3], "conversation_reason",
    "conversation relationship reason")
PNC.RelationshipPresentation = nil
Router.Handle("ConversationRelationshipRequest", player, nil)
T.equal(conversationCall[2], nil,
    "unavailable relationship presentation snapshot")
T.equal(conversationCall[3], "presentation_unavailable",
    "unavailable relationship presentation reason")

knowledgeCalls = {}
Router.Handle("NPCKnowledgeRequest", player, { allKnown = true })
T.equal(#knowledgeCalls, 2, "known knowledge snapshot count")
T.equal(knowledgeCalls[1][2].id, "known-1", "first known snapshot")
T.equal(knowledgeCalls[2][2].id, "known-2", "second known snapshot")

knowledgeCalls = {}
local disclosureArgs = { npcID = "npc-3", topicID = "topic-1" }
Router.Handle("NPCKnowledgeRequest", player, disclosureArgs)
T.equal(discovered.npcID, "npc-3", "disclosure NPC")
T.equal(discovered.topicID, "topic-1", "disclosure topic")
T.equal(discovered.sourcePlayer, nil, "disclosure source player")
T.equal(discovered.source, "direct_disclosure", "disclosure source")
T.equal(knowledgeCalls[1][2].npcID, "npc-3", "knowledge snapshot")
T.equal(knowledgeCalls[1][3], "disclosed", "disclosure reason priority")

player.access = ""
Router.Handle("KnowledgeDebugRequest", player, {})
T.equal(knowledgeDebugCall[2], nil, "unauthorized knowledge snapshot")
T.equal(knowledgeDebugCall[3], false, "unauthorized knowledge flag")
T.equal(knowledgeDebugCall[4], "not_authorized",
    "unauthorized knowledge reason")

player.access = "admin"
Router.Handle("KnowledgeDebugRequest", player, nil)
T.equal(debugArgs.showTruth, nil, "nil show-truth behavior changed")
T.equal(knowledgeDebugCall[3], true, "knowledge debug flag")
T.equal(knowledgeDebugCall[4], "debug_reason", "knowledge debug reason")

Router.Handle("KnowledgeDebugRequest", player, {})
T.equal(debugArgs.showTruth, true, "empty show-truth behavior changed")

Router.Handle("KnowledgeDebugRequest", player, {
    npcID = "npc-4",
    showTruth = false,
    descriptorID = "descriptor-1",
})
T.equal(debugArgs.npcID, "npc-4", "knowledge debug NPC")
T.equal(debugArgs.showTruth, false, "knowledge show-truth flag")
T.equal(debugArgs.descriptorID, "descriptor-1",
    "knowledge debug descriptor")

PNC.NPCKnowledge = nil
knowledgeCalls = {}
Router.Handle("NPCKnowledgeRequest", player, nil)
T.equal(knowledgeCalls[1][3], "knowledge_service_unavailable",
    "knowledge unavailable reason")
Router.Handle("KnowledgeDebugRequest", player, {})
T.equal(knowledgeDebugCall[4], "knowledge_service_unavailable",
    "knowledge debug unavailable reason")
T.finish("pnc_server_diagnostic_query_command_handler_smoke")

T.finish("pnc_server_diagnostic_query_command_handler_smoke")
