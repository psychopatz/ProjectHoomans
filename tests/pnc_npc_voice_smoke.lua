local T = require "tests/support/test"

local calls = {
    played = {},
    stopped = {},
    world = {},
    parameters = {},
}

PNC = {
    Core = {},
    NPCVoice = {},
}

local emitter = {
    setParameterValueByName = function(_, handle, name, value)
        calls.parameters[#calls.parameters + 1] = {
            handle = handle,
            name = name,
            value = value,
        }
    end,
    stopSoundLocal = function(_, handle)
        calls.stopped[#calls.stopped + 1] = handle
    end,
}

local body = {
    isFemale = function() return true end,
    playSoundLocal = function(_, alias)
        calls.played[#calls.played + 1] = alias
        return #calls.played
    end,
    getEmitter = function() return emitter end,
    addWorldSoundUnlessInvisible = function(_, radius, volume, stressHumans)
        calls.world[#calls.world + 1] = {
            radius = radius,
            volume = volume,
            stressHumans = stressHumans,
        }
    end,
}

local voice = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Audio/PNC_NPCVoice.lua"
)

local snapshot = {
    id = "voice-profile",
    identitySeed = 321,
    isFemale = true,
}
local profile = voice.GetProfile(snapshot, body)
local alias = voice.GetAlias(body, "PainFromBite", snapshot)
local deathProfile = voice.GetProfile({
    id = "voice-profile",
    alive = false,
    deathMarker = true,
}, body)

T.truthy(profile.prefix == "VoiceFemale", "female prefix was not preserved")
T.truthy(profile.voiceType >= 0 and profile.voiceType <= 3,
    "voice type was outside the engine range")
T.truthy(profile.pitch >= voice.FEMALE_PITCH_MIN
    and profile.pitch <= voice.FEMALE_PITCH_MAX,
    "female pitch was outside the configured range")
T.equal(deathProfile.seed, profile.seed,
    "death marker discarded the identity-seeded voice profile")
T.equal(alias, "VoiceFemalePainFromBite", "gendered alias was not resolved")

T.truthy(voice.PlayLocal(body, "PainFromBite", { snapshot = snapshot }) ~= 0,
    "local voice did not start")
T.equal(calls.played[1], "VoiceFemalePainFromBite",
    "local voice used the wrong alias")
T.equal(#calls.world, 0, "local voice created a world-sound event")
T.equal(#calls.parameters, 2, "voice parameters were not applied")

T.truthy(voice.PlayWorld(body, "PainFromFallHigh", {
    snapshot = snapshot,
    radius = 12,
    volume = 14,
    stressHumans = false,
}) ~= 0, "world voice did not start")
T.equal(calls.played[2], "VoiceFemalePainFromFallHigh",
    "world voice used the wrong alias")
T.equal(#calls.world, 1, "world voice did not create one world-sound event")
T.equal(calls.world[1].radius, 12, "world radius was not forwarded")
T.equal(calls.world[1].volume, 14, "world volume was not forwarded")
T.falsy(calls.world[1].stressHumans,
    "world voice unexpectedly stressed humans")
T.equal(#calls.stopped, 1, "new voice did not stop the previous lane")

T.finish("pnc_npc_voice_smoke")
