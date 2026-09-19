local T = require "tests/support/test"
T.addPackagePaths()

local sent = {}
local now = 100

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_PLAYER_BOOTSTRAP_REQUEST = "PlayerBootstrapRequest",
        CMD_FULL_SYNC_REQUEST = "FullSyncRequest",
        CMD_NPC_PRESENTATION_REQUEST = "NPCPresentationRequest",
        CMD_KNOWLEDGE_DISCLOSURE_REQUEST = "KnowledgeDisclosureRequest",
        CMD_SEMANTIC_IDENTITY_REQUEST = "SemanticIdentityRequest",
        CMD_SEMANTIC_COGNITION_REQUEST = "SemanticCognitionRequest",
        CMD_COLONY_MANAGEMENT_ACTION = "ColonyManagementAction",
        CMD_WORLD_DISCOVERY_REQUEST = "WorldDiscoveryRequest",
        CMD_WORLD_DISCOVERY_ACTION = "WorldDiscoveryAction",
        CMD_REQUEST_CHARACTER = "RequestCharacterPayload",
    },
    Core = {
        Now = function() return now end,
        IsClientOnly = function() return true end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, entry in pairs(value) do
                output[key] = PNC.Core.DeepCopy(entry)
            end
            return output
        end,
    },
    Network = { ClientState = {} },
    Client = { Internal = {} },
    KnowledgeInterest = {
        CollectNPCIDs = function() return { "npc_interest" } end,
    },
    Semantics = {},
}

getSpecificPlayer = function() return { id = "player-1" } end
sendClientCommand = function(player, module, command, args)
    sent[#sent + 1] = {
        player = player,
        module = module,
        command = command,
        args = args,
    }
end

T.load("ProjectHoomans", "client",
    "PNC/Networking/PNC_ClientRequests.lua")

local Client = PNC.Client
local required = {
    "RequestPlayerBootstrap", "EnsurePlayerBootstrap", "RequestFullSync",
    "RequestWorldDiscovery", "EnsureWorldDiscovery",
    "RequestNPCKnowledge", "RequestKnownNPCKnowledge",
    "RequestNPCKnowledgeTopic",
    "SubmitSemanticIdentity", "RequestSemanticCognition",
    "RequestSemanticTask", "RequestSemanticInventoryQuery",
    "RequestColonyManagement", "RequestColonyJournal", "RequestColonyAction",
    "RequestBaseBootstrap", "RequestCreateBase", "TransferPlayerStorage",
    "DepositPlayerItemsToColony", "RenameColony", "SetFactionEmblem",
    "RequestCharacterPayload",
    "CanUseDebug", "RequestDebugRoster", "RequestRelationshipDebug",
    "RequestConversationRelationship", "RequestKnowledgeDebug",
    "RequestFactionDebug", "RequestFactionMembers", "RequestNeedsDebug",
    "RequestDirectorDebug", "RequestWorldEffectDebug",
}
for _, name in ipairs(required) do
    T.truthy(type(Client[name]) == "function",
        "request composition did not expose " .. name)
end
T.truthy(type(Client.Internal.RequestID) == "function",
    "request spokes do not share the internal request-id contract")
T.truthy(type(Client.Internal.DispatchIdentity) == "function",
    "request spokes do not share the identity transport contract")

T.truthy(Client.RequestPlayerBootstrap(),
    "bootstrap spoke did not send through the hub composition")
T.equal(sent[#sent].command, "PlayerBootstrapRequest",
    "bootstrap spoke changed its network command")
T.equal(sent[#sent].args.npcIDs[1], "npc_interest",
    "bootstrap spoke changed its interest scope payload")

T.truthy(Client.RequestSemanticCognition("npc-1", {
    subject = "identity.name",
    conversationToken = "conversation-1",
}), "semantic cognition spoke was not callable")
T.equal(sent[#sent].command, "SemanticCognitionRequest",
    "semantic cognition used the wrong transport")
T.equal(sent[#sent].args.conversationToken, "conversation-1",
    "semantic cognition lost its conversation token")

PNC.Core.IsClientOnly = function() return false end
PNC.Semantics.CognitionService = {
    HandleRequest = function(_, args)
        return args.npcID == "npc-local", "accepted"
    end,
}
local localAccepted, localReason = Client.RequestSemanticCognition(
    "npc-local", {
        subject = "identity.name",
        conversationToken = "conversation-local",
    })
T.truthy(localAccepted, "semantic cognition lost its single-player route")
T.equal(localReason, "accepted",
    "single-player semantic cognition changed its service reason")
PNC.Core.IsClientOnly = function() return true end

T.truthy(Client.SubmitSemanticIdentity("npc-1", {
    kind = "identity_claim",
    claimedName = "Patrick",
}), "identity spoke was not callable")
T.equal(sent[#sent].command, "SemanticIdentityRequest",
    "identity exchange used the wrong transport")
T.equal(sent[#sent].args.claimedName, "Patrick",
    "identity exchange lost the claimed name")

T.truthy(Client.RequestColonyAction("building_queue", {
    recipeID = "bed",
}), "colony spoke was not callable")
T.equal(sent[#sent].command, "ColonyManagementAction",
    "colony spoke used the wrong transport")
T.equal(sent[#sent].args.snapshotScope, "base",
    "colony spoke lost the base snapshot scope")
T.truthy(sent[#sent].args.requestId,
    "colony spoke lost the request correlation id")

T.truthy(Client.RequestWorldDiscovery("snapshot"),
    "world spoke was not callable")
T.equal(sent[#sent].command, "WorldDiscoveryRequest",
    "world spoke used the wrong transport")

T.truthy(Client.RequestCharacterPayload("npc-1", true),
    "character spoke was not callable")
T.equal(sent[#sent].command, "RequestCharacterPayload",
    "character spoke used the wrong transport")
T.equal(sent[#sent].args.forceFull, true,
    "character spoke lost forceFull")

T.finish("pnc_client_requests_modules_smoke")
