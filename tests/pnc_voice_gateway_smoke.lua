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
    Network = {
        ClientState = {
            snapshots = {
                ["snapshot-only"] = {
                    id = "snapshot-only",
                    identitySeed = 17,
                    isFemale = true,
                },
            },
        },
    },
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
PsychopatzCore.Audio = {
    IsPlayerSpeechEnabled = function() return false end,
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

local player = {
    isFemale = function() return true end,
    getUsername = function() return "player-one" end,
    getDescriptor = function()
        return {
            isFemale = function() return true end,
            getVoicePrefix = function() return "VoiceFemale" end,
            getVoiceType = function() return 2 end,
            getVoicePitch = function() return 7.4 end,
        }
    end,
}
getSpecificPlayer = function() return player end

Message.Publish(Message.New({
    saveUUID = "voice-save",
    conversationID = "voice-conversation",
    sequence = 2,
    speaker = "player",
    speakerID = "unbound",
    speakerName = "Player One",
    speakerKind = "player",
    playerUUID = "unbound",
    npcUUID = "npc-one",
    text = "I will speak now.",
    worldAgeHours = 72,
}))
T.equal(#packets, 1, "player speech remains disabled by default")

PsychopatzCore.Audio.IsPlayerSpeechEnabled = function() return true end
Message.Publish(Message.New({
    saveUUID = "voice-save",
    conversationID = "voice-conversation",
    sequence = 3,
    speaker = "player",
    speakerID = "unbound",
    speakerName = "Player One",
    speakerKind = "player",
    playerUUID = "unbound",
    npcUUID = "npc-one",
    text = "I will speak now.",
    worldAgeHours = 72,
}))
T.equal(#packets, 2, "enabled player speech publishes a voice packet")
T.equal(packets[2].packet.speaker_kind, "player", "player kind is preserved")
T.equal(packets[2].packet.speaker_id, "player-one", "player identity is preserved")
T.equal(packets[2].packet.voice_binding.speaker_kind, "player", "player binding kind is preserved")
T.equal(packets[2].packet.voice_binding.player_uuid, "player-one", "player binding identity is preserved")
T.equal(packets[2].packet.voice_binding.slot, "VoiceFemale:2", "player descriptor selects voice slot")
T.equal(packets[2].packet.voice_binding.pitch, 7, "player descriptor pitch is rounded safely")

Message.Publish(Message.New({
    saveUUID = "voice-save",
    conversationID = "voice-conversation-snapshot",
    sequence = 1,
    speaker = "npc",
    speakerID = "snapshot-only",
    speakerName = "Snapshot Only",
    speakerKind = "npc",
    npcUUID = "snapshot-only",
    text = "I am still loading.",
    worldAgeHours = 72,
}))
T.equal(#packets, 3, "snapshot-only MP NPC publishes a voice packet")
T.equal(packets[3].packet.voice_binding.npc_uuid, "snapshot-only",
    "snapshot-only NPC binding preserves identity")

T.finish("pnc_voice_gateway_smoke")
