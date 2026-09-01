local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Networking/PNC_Network_Server.lua"
)
local providers = {
    "PNC_Network_Server_Transport",
    "PNC_Network_Server_RosterInterest",
    "PNC_Network_Server_Broadcasts",
    "PNC_Network_Server_Character",
    "PNC_Network_Server_DebugPayloads",
    "PNC_Network_Server_Colony",
    "PNC_Network_Server_Social",
}
local publicFunctions = {
    "QueueRosterDelta",
    "QueueRosterSnapshot",
    "QueuePeriodicRoster",
    "RefreshInterestSets",
    "FlushRosterDeltas",
    "BroadcastRecord",
    "BroadcastRemoval",
    "BroadcastDeathMarkerRemoval",
    "BroadcastBodyRemoval",
    "BroadcastFullSync",
    "SendCharacterPayload",
    "CanViewCharacter",
    "SendInventoryDelta",
    "SendDebugRoster",
    "SendRelationshipDebug",
    "SendConversationRelationship",
    "SendConversationRelationshipForNPC",
    "SendNPCKnowledge",
    "SendPlayerBootstrap",
    "SendNPCPresentation",
    "SendKnowledgeDisclosure",
    "SendKnowledgeDebug",
    "SendFactionDebug",
    "SendFactionMembers",
    "SendCommunityDebug",
    "SendNeedsDebug",
    "SendDirectorDebug",
    "SendColonyManagement",
    "SendSettlementDelta",
    "SendColonyKnowledgeDelta",
    "SendWorldDiscovery",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Networking/PNC_Network_Server/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Core = { Now = function() return 12 end },
    Const = {},
    RelationshipPresentation = {
        BuildForConversation = function(_, npcID)
            return {
                npcID = tostring(npcID),
                exists = true,
                approval = 4,
                respect = 2,
                familiarity = 1,
                state = "indifferent",
                revision = 3,
            }
        end,
    },
    Network = {
        ServerState = {
            interests = {},
            rosterDeltas = {},
        },
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Networking/PNC_Network_Server.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Network[functionName]),
        "function",
        "entry point should preserve Network." .. functionName
    )
end

local sent
isServer = function() return true end
sendServerCommand = function(_, module, command, payload)
    sent = { module = module, command = command, payload = payload }
end
T.truthy(PNC.Network.SendConversationRelationshipForNPC(
    {},
    "npc-central",
    "gift",
    {
        source = "gift",
        eventID = "event-central",
        relationshipDelta = { approval = 2, respect = 1 },
        relationshipBefore = { approval = 2, respect = 1 },
    }
), "central relationship sender")
T.equal(sent.payload.summary.npcID, "npc-central",
    "central sender includes NPC summary")
T.equal(sent.payload.source, "gift",
    "central sender preserves source")
T.equal(sent.payload.relationshipDelta.approval, 2,
    "central sender preserves relationship delta")
T.equal(sent.payload.eventID, "event-central",
    "central sender preserves event id")

T.finish("pnc_network_server_presence_boundary_smoke")
