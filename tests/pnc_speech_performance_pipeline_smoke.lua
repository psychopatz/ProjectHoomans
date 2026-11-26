local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

PNC = { Core = { Now = function() return 100000 end, NowWorldAgeHours = function() return 10 end } }

local zombieNear = false
PNC.Perception = {
    GetZombieCandidatesAt = function()
        return zombieNear and { { id = "z1" } } or {}
    end,
    IsActualZombieBody = function() return true end,
}

local Perf = require "PNC/Semantics/PNC_SemanticSpeechPerformance"
local Ceasefire = require "PNC/Social/PNC_CeasefireService"

local playedSounds = {}
local bumpHistory = {}
local function makeNPC(id, isFemale)
    return {
        id = id,
        alive = true,
        isFemale = isFemale == true,
        x = 100,
        y = 100,
        z = 0,
        runtime = {},
        zombie = {
            isFemale = function() return isFemale == true end,
            playSound = function(_, snd) playedSounds[#playedSounds + 1] = snd end,
            setBumpType = function(_, b) bumpHistory[#bumpHistory + 1] = b end,
        },
    }
end

-- 1. Play wavebye + gender-aware base-game voice, then auto-expire via Pump (never stuck)
Perf.ResetRuntime()
local npcF = makeNPC("npc_female", true)
local ok, anim = Perf.Perform(npcF, { anim = "wavebye", animDurationMs = 2500, voice = "farewell" }, 100000)
T.equal(ok, true, "wavebye animation started")
T.equal(anim, "wavebye", "anim ID matches")
T.equal(playedSounds[#playedSounds], "VoiceFemaleShoutHey", "female base-game voice cue played")
T.equal(Perf.ActiveCount(), 1, "active animation tracked")
T.equal(Perf.Pump(101000), 0, "still playing before duration expires")
T.equal(Perf.Pump(103000), 1, "auto-cleared after bounded duration")
T.equal(Perf.ActiveCount(), 0, "no stuck animation")
T.equal(bumpHistory[#bumpHistory], "", "bumpType reset cleanly on expiry")

-- 2. Smart zombie interruption cancels active animation immediately & blocks new ones
local npcM = makeNPC("npc_male", false)
local ok2 = Perf.Perform(npcM, { anim = "wavehi", animDurationMs = 4000, voice = "greet" }, 200000)
T.equal(ok2, true, "wavehi started while safe")
T.equal(playedSounds[#playedSounds], "VoiceMaleShoutHey", "male base-game voice cue played")
zombieNear = true
T.equal(Perf.Pump(200500), 1, "nearby zombie immediately interrupts active animation")
T.equal(Perf.ActiveCount(), 0, "active count back to 0")
local okBlocked, blockReason = Perf.Perform(npcM, { anim = "clap", animDurationMs = 2000 }, 201000)
T.equal(okBlocked, false, "casual animation blocked when zombie is near")
T.equal(blockReason, "zombie_danger", "blocked with zombie_danger")

-- 3. Surrender plays bounded 5000ms animation even in human combat, and no_mercy interrupts it
zombieNear = false
Ceasefire.ResetRuntime()
local looter = makeNPC("looter_1", false)
local playerRef = { isPlayer = true, key = "player:1", id = "player:1", x = 105, y = 100 }
looter.runtime.target = playerRef
local okS, rS = Ceasefire.AttemptSurrender(looter, { playerRef }, { now = 300000 })
T.equal(okS, true, "AI surrender initiated")
T.equal(rS, "pending_player_mercy", "awaits player mercy choice")
local activeSurr = Perf.GetActive("looter_1")
T.truthy(activeSurr ~= nil and activeSurr.animID == "surrender", "surrender animation playing")
T.equal(activeSurr.expiresAt, 305000, "surrender animation bounded to 5000ms")
Ceasefire.ResolveMercyDecision(looter, playerRef, "no_mercy", { now = 301000 })
T.equal(Perf.GetActive("looter_1"), nil, "no_mercy immediately interrupts surrender animation")

-- 4. Verify declarative cue resolution across non-compat pools & compat exclusion
local byeCue = Perf.ResolveCue({ poolID = "semantic.farewell", act = "FAREWELL" })
T.truthy(byeCue and byeCue.anim == "wavebye" and byeCue.voice == "farewell", "farewell resolves wavebye + voice")
local reliefCue = Perf.ResolveCue({ poolID = "semantic.world.exposure.relief", role = "out_of_rain_open" })
T.truthy(reliefCue and reliefCue.anim == "thumbsup" and reliefCue.voice == "relief", "out_of_rain resolves thumbsup + relief sigh")
local coldCue = Perf.ResolveCue({ poolID = "semantic.world.exposure.suggest", role = "freezing_exposure_open" })
T.truthy(coldCue and coldCue.voice == "shiver", "freezing resolves shiver voice")
local compatCue = Perf.ResolveCue({ poolID = "semantic.compat.bandits.hooman_hurt", act = "GREET" })
T.equal(compatCue, nil, "modded compat pools are excluded from auto-cues")

-- 5. Verify actor-agnostic PerformForPlayer (emote + gender-aware voice)
local playerEmotes, playerSounds = {}, {}
local mockPlayer = {
    isDead = function() return false end,
    isAttacking = function() return false end,
    isFemale = function() return true end,
    playEmote = function(_, e) playerEmotes[#playerEmotes + 1] = e end,
    playSound = function(_, s) playerSounds[#playerSounds + 1] = s end,
}
local okP = Perf.PerformForPlayer(mockPlayer, { act = "FAREWELL" }, 400000)
T.equal(okP, true, "PerformForPlayer executes farewell emote + voice")
T.equal(playerEmotes[#playerEmotes], "wavebye", "player waves goodbye")
T.equal(playerSounds[#playerSounds], "VoiceFemaleShoutHey", "player plays gender-matched voice")

print("pnc_speech_performance_pipeline_smoke: ok")
