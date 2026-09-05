local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = {
    Registry = {},
    Core = { Now = function() return 1000 end },
}
local packets = {}
local bridgeActive = true
local playerSpeechEnabled = false
local sayCount = 0
local reactionCount = 0
local now = 1000

PsychopatzCore.BridgeBootstrap = {
    IsEnabled = function() return bridgeActive end,
}
PsychopatzCore.Bridge = {
    lifecycle = "READY",
    RegisterPacketChannel = function() return true end,
    SetPacketSnapshot = function() return true end,
    PublishPacket = function(namespace, channel, packet)
        packets[#packets + 1] = {
            namespace = namespace,
            channel = channel,
            packet = packet,
        }
        return true
    end,
    RegisterCommand = function() return true end,
}
PsychopatzCore.Audio = {
    IsPlayerSpeechEnabled = function() return playerSpeechEnabled end,
}
getTimeInMillis = function() return now end
getGameTime = function()
    return { getWorldAgeHours = function() return 24 end }
end

local player = {
    getUsername = function() return "player-one" end,
    getDescriptor = function()
        return {
            isFemale = function() return false end,
            getVoicePrefix = function() return "VoiceMale" end,
            getVoiceType = function() return 1 end,
            getVoicePitch = function() return -3 end,
        }
    end,
    Say = function(_, text)
        sayCount = sayCount + 1
        T.equal(text, "Hello from the player.", "fallback keeps flavor text")
    end,
}
getSpecificPlayer = function() return player end

PNC.CompanionCommandFlavor = {
    Resolve = function() return "Hello from the player." end,
}
PNC.SocialFlavorPresentation = {
    ReceivePlayerSpeech = function()
        reactionCount = reactionCount + 1
        return true
    end,
}

T.load("PsychopatzCore", "common", "PsychopatzCore/Events/PC_EventBus.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Voice/PsychopatzVoiceGateway.lua")
T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_VoiceGateway.lua")
T.load("ProjectHoomans", "client", "PNC/Audio/PNC_PlayerSpeech.lua")
T.load("ProjectHoomans", "client", "PNC/Commands/PNC_CompanionCommandPresentation.lua")

local Presentation = PNC.CompanionCommandPresentation

Presentation.ShowPlayerFlavor(player, "wave", {})
T.equal(sayCount, 1, "disabled player voice falls back to standard Say")
T.equal(#packets, 0, "disabled player voice publishes no packet")
T.equal(reactionCount, 1,
    "disabled player voice still reaches local social flavor")

playerSpeechEnabled = true
Presentation.ShowPlayerFlavor(player, "wave", { eventID = "event-one" })
T.equal(sayCount, 2, "enabled player voice keeps the visible speech bubble")
T.equal(#packets, 1, "enabled player voice uses the canonical endpoint")
T.equal(packets[1].packet.speaker_kind, "player", "player packet kind")
T.equal(packets[1].packet.speaker_id, "player-one", "player packet identity")
T.equal(packets[1].packet.text, "Hello from the player.", "player packet text")
T.equal(reactionCount, 2,
    "enabled player speech reaches local social flavor once")

bridgeActive = false
Presentation.ShowPlayerFlavor(player, "wave", {})
T.equal(sayCount, 3, "inactive brain falls back to standard Say")
T.equal(#packets, 1, "inactive brain publishes no player packet")
T.equal(reactionCount, 3,
    "inactive brain still allows deterministic local flavor fallback")

T.finish("pnc_player_speech_smoke")
