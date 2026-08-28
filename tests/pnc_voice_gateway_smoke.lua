local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = {
    Registry = {
        GetLiveZombie = function() return {
            isFemale = function() return true end,
            getModData = function() return { PNC_UUID = "npc-one" } end,
        } end,
        Get = function() return { id = "npc-one" } end,
    },
    Network = { ClientState = { snapshots = {} } },
}
local packets = {}
PsychopatzCore.Bridge = {
    lifecycle = "READY",
    RegisterPacketChannel = function() return true end,
    SetPacketSnapshot = function() return true end,
    PublishPacket = function(namespace, channel, packet)
        packets[#packets + 1] = { namespace = namespace, channel = channel, packet = packet }
        return true, #packets
    end,
    RegisterCommand = function() return true end,
}
getTimeInMillis = function() return 2000 end
getGameTime = function()
    return { getWorldAgeHours = function() return 72 end }
end

T.load("PsychopatzCore", "common", "PsychopatzCore/Events/PC_EventBus.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Voice/PsychopatzVoiceGateway.lua")
T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_VoiceGateway.lua")

local Message = PsychopatzCore.Conversation.Message
Message.Publish(Message.New({
    saveUUID = "voice-save",
    conversationID = "voice-conversation",
    sequence = 1,
    speaker = "npc",
    speakerID = "npc-one",
    speakerName = "One",
    speakerKind = "npc",
    npcUUID = "npc-one",
    text = "Hello there.",
    worldAgeHours = 72,
}))

T.equal(#packets, 1, "Hoomans adapter publishes NPC voice packet")
T.equal(packets[1].packet.voice_binding.npc_uuid, "npc-one", "adapter binds NPC")
T.equal(packets[1].packet.voice_binding.slot, "VoiceFemale:0", "adapter uses NPC profile")

T.finish("pnc_voice_gateway_smoke")
