local T = require "tests/support/test"

T.addPackagePaths()

local now = 1000
local playedBumps = {}
local staggerCalls = 0

PNC = {
    Const = {
        ZOMBIE_BITE_APPLY_DELAY_MS = 450,
    },
    Core = {
        Now = function() return now end,
    },
    Animation = {
        PlayBump = function(body, record, bumpType, opts)
            playedBumps[#playedBumps + 1] = {
                body = body,
                bumpType = bumpType,
                opts = opts,
            }
            return true
        end,
    },
    CombatZombieReaction = {
        ApplyHitReaction = function(zombie, attacker, opts)
            staggerCalls = staggerCalls + 1
            return true
        end,
    },
    ZombieAggro = {
        State = { bites = {} },
        BiteInternal = {},
    },
}

SandboxVars = { ZombieLore = { ZombiesDragDown = true } }

T.load("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_Bite/PNC_ZombieAggro_Bite_Grapple.lua")
local BiteInternal = PNC.ZombieAggro.BiteInternal
local State = PNC.ZombieAggro.State

local function makeBody(side, item)
    local faced, onFloor = 0, false
    return {
        getFaced = function() return faced end,
        isOnFloor = function() return onFloor end,
        faceThisObject = function() faced = faced + 1 end,
        setOnFloor = function(_, v) onFloor = v == true end,
        testDotSide = function() return side or "front" end,
        getPrimaryHandItem = function() return item end,
    }
end

local zombie1 = makeBody()
local npcBody = makeBody("front", {
    isRanged = function() return false end,
    isTwoHandWeapon = function() return true end,
})
local record = { id = "npc_grapple_1", runtime = {} }
local entry1 = { zombieId = "z1", npcId = "npc_grapple_1", bumpType = "Bite", phase = "windup" }
State.bites.z1 = entry1

-- 1. Front grab starts struggle bump + movement hold + mutual facing
local struggleBump = BiteInternal.BeginGrapple(entry1, record, zombie1, npcBody, now)
T.equal(struggleBump, "PNC_BiteDefended", "front grab uses PNC_BiteDefended")
T.truthy(record.runtime.grappleHoldUntil > now, "grapple sets bounded movement hold")
T.equal(zombie1.getFaced(), 1, "zombie faces NPC")
T.equal(npcBody.getFaced(), 1, "NPC faces zombie")
T.equal(playedBumps[1].bumpType, "PNC_BiteDefended", "NPC plays paired struggle clip")

-- 2. Defended shove-off plays weapon-matched shove, staggers zombie, frees hold
entry1.pushed = true
local phase, outBump = BiteInternal.ResolveGrappleOutcome(
    entry1, record, zombie1, npcBody, false, true, now + 450
)
T.equal(phase, "defended", "defended outcome phase")
T.equal(outBump, "PNC_ShoveBat", "2H melee weapon picks PNC_ShoveBat")
T.equal(staggerCalls, 1, "zombie receives break-free staggerback")
T.equal(record.runtime.grappleHoldUntil, nil, "break-free clears movement hold")

-- 3. Rear grab uses PNC_Anim_bite
local rearNpc = makeBody("behind", nil)
T.equal(
    BiteInternal.ResolveNPCStruggleBump(zombie1, rearNpc),
    "PNC_Anim_bite",
    "rear grab uses PNC_Anim_bite"
)

-- 4. Multi-zombie drag-down (>= 3 simultaneous grapplers -> OnFloor + BiteLow)
local entry2 = { zombieId = "z2", npcId = "npc_grapple_1", bumpType = "Bite", phase = "windup" }
local entry3 = { zombieId = "z3", npcId = "npc_grapple_1", bumpType = "Bite", phase = "windup" }
State.bites.z2 = entry2
State.bites.z3 = entry3
BiteInternal.BeginGrapple(entry3, record, zombie1, npcBody, now + 100)
T.truthy(entry3.dragDown, "3 simultaneous grapplers trigger drag-down")
T.equal(entry3.bumpType, "BiteLow", "drag-down switches bite bump to BiteLow")
T.truthy(npcBody.isOnFloor(), "drag-down knocks NPC to floor")

-- 5. Heroic interrupt clears grapple hold once last grappler releases
State.bites.z1 = nil
State.bites.z2 = nil
BiteInternal.ReleaseGrappleHold(record, entry2)
T.truthy(record.runtime.grappleHoldUntil ~= nil, "hold stays while z3 still grappling")
State.bites.z3 = nil
BiteInternal.ReleaseGrappleHold(record, entry3)
T.equal(record.runtime.grappleHoldUntil, nil, "hold clears immediately once all grapplers release")
