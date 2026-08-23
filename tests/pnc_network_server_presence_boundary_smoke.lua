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
    Core = {},
    Const = {},
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

T.finish("pnc_network_server_presence_boundary_smoke")
