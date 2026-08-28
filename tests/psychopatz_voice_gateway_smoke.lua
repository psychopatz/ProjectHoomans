local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
local packets = {}
local registrations = {}
local now = 1000
getTimeInMillis = function() return now end
getGameTime = function()
    return { getWorldAgeHours = function() return 48 end }
end

PsychopatzCore.Bridge = {
    lifecycle = "READY",
    RegisterPacketChannel = function(namespace, channel, options)
        registrations[#registrations + 1] = { namespace, channel, options }
        return true
    end,
    SetPacketSnapshot = function() return true end,
    PublishPacket = function(namespace, channel, packet)
        packets[#packets + 1] = { namespace = namespace, channel = channel, packet = packet }
        return true, #packets
    end,
    RegisterCommand = function() return true end,
}

T.load("PsychopatzCore", "common", "PsychopatzCore/Events/PC_EventBus.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Voice/PsychopatzVoiceGateway.lua")

local Message = PsychopatzCore.Conversation.Message
local Gateway = PsychopatzCore.VoiceGateway
local Events = PsychopatzCore.Events

T.truthy(Gateway.RegisterSource("TestMod", {
    bufferUntilReady = true,
    filter = function(message)
        return message.speakerKind == "npc"
    end,
    enrich = function(message)
        return {
            voice_binding = {
                npc_uuid = message.speakerID,
                slot = "VoiceFemale:2",
                pitch = 4,
            },
            speech = { mode = "RESPONSE" },
        }
    end,
}), "source registers")
T.equal(#registrations, 1, "voice channel registers once")

Message.Publish(Message.New({
    saveUUID = "voice-save",
    conversationID = "voice-conversation",
    sequence = 3,
    speaker = "npc",
    speakerID = "npc-one",
    speakerName = "One",
    speakerKind = "npc",
    npcUUID = "npc-one",
    text = "What is your name?",
    payload = { key = "npc.name", domain = "test", args = { tone = "warm" } },
    worldAgeHours = 48,
}))

T.equal(#packets, 1, "NPC message becomes one voice packet")
local packet = packets[1].packet
T.equal(packet.event_type, "speech.enqueue", "packet event is enqueue")
T.equal(packet.source_mod, "TestMod", "packet identifies source mod")
T.equal(packet.text, "What is your name?", "packet carries resolved text")
T.equal(packet.text_key, "npc.name", "packet keeps compact text reference")
T.equal(packet.game_day, 2, "packet carries save-aware game day")
T.equal(packet.voice_binding.slot, "VoiceFemale:2", "packet carries voice binding")

Message.Publish(Message.New({
    conversationID = "voice-conversation",
    sequence = 4,
    speaker = "player",
    speakerID = "player-one",
    speakerKind = "player",
    text = "This must not be spoken by the NPC.",
}))
T.equal(#packets, 1, "source filter excludes player messages")

T.truthy(Gateway.UnregisterSource("TestMod"), "source unregisters")
T.falsy(Events.hasSubscribers(Message.EVENT_TYPE), "unused gateway has no listener")
T.equal(Gateway.GetStatus().pending, 0, "disabled gateway keeps no pending work")

T.finish("psychopatz_voice_gateway_smoke")
