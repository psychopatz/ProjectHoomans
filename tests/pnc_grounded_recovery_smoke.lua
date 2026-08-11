local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_LiveBodyControl.lua"

local now = 1000
local cancelled = 0
local held = 0
local reactions = 0
local stateName = "onground"
local onFloor = true
local knockedDown = true
local attackedBy

local friendlyPlayer = {
    getObjectName = function() return "Player" end,
    getOnlineID = function() return 7 end,
    getUsername = function() return "alice" end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

local hostileZombie = {
    getObjectName = function() return "Zombie" end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

local modData = {}
local body = {
    getActionStateName = function() return stateName end,
    isOnFloor = function() return onFloor end,
    isKnockedDown = function() return knockedDown end,
    getAttackedBy = function() return attackedBy end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getModData = function() return modData end,
    setTarget = function() end,
    setTargetSeenTime = function() end,
    setEatBodyTarget = function() end,
    clearAggroList = function() end,
    setAttackedBy = function() attackedBy = nil end,
    setStaggerBack = function() end,
    setHitReaction = function() end,
    setBumpDone = function() end,
    setBumpStaggered = function() end,
    setBumpFall = function() end,
    setBumpType = function() end,
    setKnockedDown = function(_, value) knockedDown = value end,
    setOnFloor = function(_, value) onFloor = value end,
    setFallOnFront = function() end,
    setCanWalk = function() end,
    setVariable = function() end,
    setSitAgainstWall = function() end,
    setCrawler = function() end,
    setFakeDead = function() end,
    setAnimatingBackwards = function() end,
    setUseless = function() end,
    setNoTeeth = function() end,
    setReanimatedForGrappleOnly = function() end,
    changeState = function()
        stateName = "idle"
    end,
}

ZombieIdleState = { instance = function() return {} end }
ZombRand = function() return 100 end
PNC = {
    Const = {
        NPC_GROUNDED_RECOVERY_MS = 1400,
        NPC_GROUNDED_COUNTER_STAGGER_CHANCE = 0.40,
        NPC_GROUNDED_COUNTER_STAGGER_RANGE = 2.25,
    },
    Core = { Now = function() return now end },
    Combat = {
        CancelAttackAction = function(record)
            cancelled = cancelled + 1
            record.runtime.attackAction = nil
            return true
        end,
    },
    BehaviorMoveIntent = {
        Hold = function()
            held = held + 1
            return true
        end,
    },
    PlayerDamage = {
        IsFriendlyOwner = function(record, attacker)
            return attacker == friendlyPlayer
                and record.ownerOnlineID == 7
        end,
    },
    CombatZombieReaction = {
        Start = function(_, attacker, options)
            assert(attacker == hostileZombie, "wrong counter-stagger target")
            assert(options.knockdown == false,
                "ground defense was allowed to knock down its attacker")
            reactions = reactions + 1
            return true
        end,
    },
}

dofile(FILE)

local record = {
    id = "follower",
    ownerOnlineID = 7,
    runtime = { attackAction = { attackType = "melee" } },
}

attackedBy = friendlyPlayer
assert(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "friendly owner push was not handled")
assert(stateName == "idle" and not onFloor and not knockedDown,
    "friendly owner push did not restore the companion immediately")
assert(record.runtime.attackAction == nil,
    "grounded companion retained an attack")
assert(reactions == 0, "friendly owner was counter-staggered")

stateName = "onground"
onFloor = true
knockedDown = true
attackedBy = hostileZombie
record.runtime.attackAction = { attackType = "melee" }
assert(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "hostile knockdown was not held for recovery")
assert(stateName == "onground", "hostile knockdown recovered too early")
assert(reactions == 1, "40 percent grounded counter did not trigger")
assert(record.runtime.attackAction == nil,
    "grounded hostile victim retained an attack")

now = now + 500
assert(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "ground recovery stopped being authoritative")
assert(reactions == 1, "ground counter repeated every tick")

now = now + 1000
assert(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "grounded timeout recovery was not handled")
assert(stateName == "idle" and not onFloor and not knockedDown,
    "hostile knockdown did not recover after timeout")
assert(cancelled >= 2 and held >= 2,
    "ground recovery did not suppress combat and movement")

print("pnc_grounded_recovery_smoke: ok")
