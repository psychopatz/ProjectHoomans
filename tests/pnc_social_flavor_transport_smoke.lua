local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local received
isServer = function() return false end
triggerEvent = function(_, _, _, payload) received = payload end

PNC = {
    Network = { Internal = {} },
    Core = { Now = function() return 1234 end },
    Const = {
        MODULE = "ProjectHoomans",
        CMD_CONVERSATION_RELATIONSHIP = "ConversationRelationship",
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_DebugPayloads.lua")
local Network = PNC.Network
local flavor = {
    flavorID = "social.witnessed_player_kill",
    eventType = "witnessed_player_kill",
    priority = 35,
}
Network.SendConversationRelationship(
    nil,
    { npcID = "npc-one", approval = 3 },
    "witnessed_player_kill",
    {
        npcID = "npc-one",
        ambientFlavor = flavor,
        relationshipDelta = { approval = 2 },
    }
)
T.truthy(received, "SP transport emits a local relationship packet")
T.equal(received.ambientFlavor.flavorID,
    "social.witnessed_player_kill",
    "relationship transport preserves the flavor hint")
T.equal(received.relationshipDelta.approval, 2,
    "relationship transport preserves authoritative delta")

T.finish("pnc_social_flavor_transport_smoke")
