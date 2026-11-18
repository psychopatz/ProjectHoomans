local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local stopped, parameters, played, ticks = {}, {}, {}, 0
local actions, resumes, positions = {}, 0, 0
MainScreen = { instance = { inGame = false } }
local emitter = {
    stopSound = function(_, handle) stopped[#stopped + 1] = handle end,
    setParameterValueByName = function(_, handle, name, value) parameters[name] = { handle, value } end,
    tick = function() ticks = ticks + 1 end,
    setPos = function(_, x, y, z)
        T.equal(x, 0, "menu emitter origin x"); T.equal(y, 0, "menu emitter origin y"); T.equal(z, 0, "menu emitter origin z")
        positions = positions + 1; actions[#actions + 1] = "position"
    end,
}
getSoundManager = function() return {
    getUIEmitter = function() return emitter end,
    resumeSoundAndMusic = function() resumes = resumes + 1; actions[#actions + 1] = "resume" end,
    playUISound = function(_, name) actions[#actions + 1] = "play"; played[#played + 1] = name; return 100 + #played end,
} end
GameSounds = { isKnownSound = function(name) return name == "VoiceMaleShoutHey" end }
local Preview = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringVoicePreview"
local p = Preview.New()
T.truthy(p:Play({ prefix = "VoiceMale", voiceType = 2, pitch = 100 }, "ShoutHey"), "no player is required")
T.equal(parameters.CharacterVoicePitch[2], 100, "native pitch parameter receives endpoint")
T.equal(parameters.CharacterVoiceType[2], 2, "native type parameter is applied")
T.equal(ticks, 1, "emitter ticks after parameters are installed")
T.equal(actions[1], "resume", "character creation resumes the menu audio bus before playback")
T.equal(actions[2], "play", "native playback follows audio resume")
T.equal(actions[3], "position", "the actorless emitter is reset to the menu origin")
T.truthy(p:Play({ prefix = "VoiceMale", voiceType = 1, pitch = -100 }, "ShoutHey"), "replay works")
T.equal(stopped[1], 101, "replay stops only its previous handle")
p:Stop()
T.equal(stopped[2], 102, "Stop stops only the owned handle")
p:Stop()
T.equal(#stopped, 2, "Stop is idempotent")
T.falsy(p:Play({ prefix = "MissingVoice" }, "NoEvent"), "missing event fails without a native playback call")
T.equal(#played, 2, "missing event was not played")
MainScreen.instance.inGame = true
T.truthy(p:Play({ prefix = "VoiceMale" }, "ShoutHey"), "in-game debug preview works")
T.equal(resumes, 2, "debug playback does not resume unrelated paused gameplay audio")
T.equal(positions, 2, "debug playback retains the live player emitter position")
p:Stop()
getSoundManager = function() return {} end
T.falsy(p:Play({ prefix = "VoiceMale" }, "ShoutHey"), "dummy/unavailable audio is a normal rejection")
T.finish("pnc_npc_authoring_voice_preview_smoke")
