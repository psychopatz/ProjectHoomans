local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local stopped, parameters, played, ticks = {}, {}, {}, 0
local actions, resumes, positions, music = {}, 0, 0, "MainMenu"
local playing = true
MainScreen = { instance = { inGame = false } }
local emitter = {
    isPlaying = function() return playing end,
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
    setMusicState = function(_, value) music = value; actions[#actions + 1] = "music:" .. value end,
    resumeSoundAndMusic = function() resumes = resumes + 1; actions[#actions + 1] = "resume" end,
    playUISound = function(_, name) if name ~= "VoiceMaleShoutHey" then return 0 end; T.equal(music, "InGame", "native menu routing is active before starting the voice"); actions[#actions + 1] = "play"; played[#played + 1] = name; return 100 + #played end,
} end
GameSounds = { isKnownSound = function(name) return name == "VoiceMaleShoutHey" end }
local Preview = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringVoicePreview"
local p = Preview.New()
T.truthy(p:Play({ prefix = "VoiceMale", voiceType = 2, pitch = 100 }, "ShoutHey"), "no player is required")
T.equal(parameters.CharacterVoicePitch[2], 100, "native pitch parameter receives endpoint")
T.equal(parameters.CharacterVoiceType[2], 2, "native type parameter is applied")
T.equal(ticks, 1, "emitter ticks after parameters are installed")
T.equal(actions[1], "music:InGame", "menu playback follows native FMOD state routing")
T.equal(actions[2], "resume", "character creation resumes the menu audio bus before playback")
T.equal(actions[3], "play", "native playback follows audio resume")
T.equal(actions[4], "position", "the actorless emitter is reset to the menu origin")
T.truthy(p:Play({ prefix = "VoiceMale", voiceType = 1, pitch = -100 }, "ShoutHey"), "replay works")
T.equal(stopped[1], 101, "replay stops only its previous handle")
playing = false; p:Update()
T.equal(music, "MainMenu", "completion restores menu music state")
T.equal(stopped[2], 102, "Stop stops only the owned handle")
p:Stop()
T.equal(#stopped, 2, "Stop is idempotent")
T.falsy(p:Play({ prefix = "MissingVoice" }, "NoEvent"), "native playback failure is reported")
T.equal(#played, 2, "failed event did not create an owned handle")
MainScreen.instance.inGame = true
music = "InGame"; playing = true
local beforeDebug = #actions
T.truthy(p:Play({ prefix = "VoiceMale" }, "ShoutHey"), "in-game debug preview works")
T.equal(resumes, 3, "debug playback does not resume unrelated paused gameplay audio")
T.equal(positions, 2, "debug playback retains the live player emitter position")
p:Stop()
for index = beforeDebug + 1, #actions do T.falsy(string.find(actions[index], "music:", 1, true), "debug playback does not change world music state") end
getSoundManager = function() return {} end
T.falsy(p:Play({ prefix = "VoiceMale" }, "ShoutHey"), "dummy/unavailable audio is a normal rejection")
T.finish("pnc_npc_authoring_voice_preview_smoke")
