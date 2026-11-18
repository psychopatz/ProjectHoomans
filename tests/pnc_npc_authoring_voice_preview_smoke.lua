local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local stopped, parameters, played, ticks = {}, {}, {}, 0
local emitter = {
    stopSound = function(_, handle) stopped[#stopped + 1] = handle end,
    setParameterValueByName = function(_, handle, name, value) parameters[name] = { handle, value } end,
    tick = function() ticks = ticks + 1 end,
}
getSoundManager = function() return {
    getUIEmitter = function() return emitter end,
    playUISound = function(_, name) played[#played + 1] = name; return 100 + #played end,
} end
GameSounds = { isKnownSound = function(name) return name == "VoiceMaleShoutHey" end }
local Preview = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringVoicePreview"
local p = Preview.New()
T.truthy(p:Play({ prefix = "VoiceMale", voiceType = 2, pitch = 100 }, "ShoutHey"), "no player is required")
T.equal(parameters.CharacterVoicePitch[2], 100, "native pitch parameter receives endpoint")
T.equal(parameters.CharacterVoiceType[2], 2, "native type parameter is applied")
T.equal(ticks, 1, "emitter ticks after parameters are installed")
T.truthy(p:Play({ prefix = "VoiceMale", voiceType = 1, pitch = -100 }, "ShoutHey"), "replay works")
T.equal(stopped[1], 101, "replay stops only its previous handle")
p:Stop()
T.equal(stopped[2], 102, "Stop stops only the owned handle")
p:Stop()
T.equal(#stopped, 2, "Stop is idempotent")
T.falsy(p:Play({ prefix = "MissingVoice" }, "NoEvent"), "missing event fails without a native playback call")
T.equal(#played, 2, "missing event was not played")
getSoundManager = function() return {} end
T.falsy(p:Play({ prefix = "VoiceMale" }, "ShoutHey"), "dummy/unavailable audio is a normal rejection")
T.finish("pnc_npc_authoring_voice_preview_smoke")
