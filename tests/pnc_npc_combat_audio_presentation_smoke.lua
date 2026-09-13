local T = require "tests/support/test"

local emitted = {}
local voices = {}

PNC = {
    NPCVoice = {
        PlayLocal = function(_, suffix)
            voices[#voices + 1] = suffix
            return 1
        end,
    },
}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Audio/PNC_NPCCombatAudio.lua"
)

local body = {
    getEmitter = function()
        return {
            playSound = function(_, sound)
                emitted[#emitted + 1] = sound
                return #emitted
            end,
        }
    end,
}

local snapshot = {
    id = "npc-audio-test",
    liveBodyLease = 1,
    isFemale = false,
    visualState = {
        attackStartedAt = 100,
        attackAudio = {
            sequence = 7,
            swingSound = "AxeSwing",
            voiceSuffix = "MeleeAttack",
        },
    },
}

local Audio = PNC.NPCCombatAudio
T.truthy(Audio.Observe(snapshot, body), "combat audio snapshot is observed")
T.truthy(Audio.Observe(snapshot, body), "repeated snapshot is safe")
T.equal(#emitted, 1, "swing sound is played once")
T.equal(emitted[1], "AxeSwing", "weapon swing sound is presented")
T.equal(#voices, 1, "attack voice is played once")
T.equal(voices[1], "MeleeAttack", "attack voice suffix is presented")

snapshot.visualState.attackAudio.hitSequence = 1
snapshot.visualState.attackAudio.hitSound = "AxeZombieHit"
T.truthy(Audio.Observe(snapshot, body), "hit audio snapshot is observed")
T.truthy(Audio.Observe(snapshot, body), "repeated hit snapshot is safe")
T.equal(#emitted, 2, "hit sound is played once")
T.equal(emitted[2], "AxeZombieHit", "weapon zombie hit sound is presented")

T.finish("pnc_npc_combat_audio_presentation_smoke")
