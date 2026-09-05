local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local cancelled = 0
local held = 0
local reactions = 0
local stateName = "onground"
local onFloor = true
local knockedDown = true
local reanimateTimer = 60
local useless = true
local attackedBy
local thumpTargetClears = 0
local onFloorWrites = 0
local stateChanges = 0
local authority = true
local ragdollSimulationActive = false
local variables = {}

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
    isRagdollSimulationActive = function()
        return ragdollSimulationActive
    end,
    isOnFloor = function() return onFloor end,
    isKnockedDown = function() return knockedDown end,
    isUseless = function() return useless end,
    isNoTeeth = function() return true end,
    isReanimatedForGrappleOnly = function() return false end,
    getAttackedBy = function() return attackedBy end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getModData = function() return modData end,
    setTarget = function() end,
    setTargetSeenTime = function() end,
    setEatBodyTarget = function() end,
    setThumpTarget = function()
        thumpTargetClears = thumpTargetClears + 1
    end,
    clearAggroList = function() end,
    setAttackedBy = function() attackedBy = nil end,
    setStaggerBack = function() end,
    setHitReaction = function() end,
    setBumpDone = function() end,
    setBumpStaggered = function() end,
    setBumpFall = function() end,
    setBumpType = function() end,
    setKnockedDown = function(_, value) knockedDown = value end,
    setOnFloor = function(_, value)
        onFloorWrites = onFloorWrites + 1
        onFloor = value
    end,
    setFallOnFront = function() end,
    setReanimateTimer = function(_, value) reanimateTimer = value end,
    getReanimateTimer = function() return reanimateTimer end,
    setCanWalk = function() end,
    setVariable = function(_, key, value) variables[key] = value end,
    setSitAgainstWall = function() end,
    setCrawler = function() end,
    setFakeDead = function() end,
    setAnimatingBackwards = function() end,
    setUseless = function(_, value) useless = value end,
    setNoTeeth = function() end,
    setReanimatedForGrappleOnly = function() end,
    changeState = function()
        stateChanges = stateChanges + 1
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
    Core = {
        Now = function() return now end,
        IsAuthority = function() return authority end,
        IsManagedNPCBody = function(candidate) return candidate == body end,
    },
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
            T.truthy(attacker == hostileZombie, "wrong counter-stagger target")
            T.truthy(options.knockdown == false,
                "ground defense was allowed to knock down its attacker")
            reactions = reactions + 1
            return true
        end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_LiveBodyControl.lua"
)

local record = {
    id = "follower",
    ownerOnlineID = 7,
    runtime = { attackAction = { attackType = "melee" } },
}
PNC.Registry = {
    FindRecordByZombie = function(candidate)
        return candidate == body and record or nil
    end,
}

attackedBy = friendlyPlayer
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "friendly owner push was not handled")
T.equal(stateName, "onground",
    "recovery bypassed the engine action context")
T.equal(reanimateTimer, 0,
    "friendly owner push did not trigger native get-up")
T.truthy(onFloor and knockedDown,
    "recovery cleared pose flags before native get-up selected a clip")
T.falsy(useless, "native get-up did not lease the engine body")
T.equal(stateChanges, 0, "recovery changed only the Java state machine")
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now + 100),
    "pending native get-up released movement ownership")
T.equal(reanimateTimer, 0, "pending native get-up timer drifted")
T.equal(record.runtime.attackAction, nil,
    "grounded companion retained an attack")
T.equal(reactions, 0, "friendly owner counter-staggers")
T.truthy(thumpTargetClears > 0, "grounded recovery retained thump target")
local floorWritesBeforeSafety = onFloorWrites
T.truthy(PNC.LiveBodyControl.EnforceManagedSafety(body, "test"),
    "managed safety did not recognize get-up lease")
T.equal(onFloorWrites, floorWritesBeforeSafety,
    "managed safety cleared floor state during native get-up")

local floorWritesBeforeGroundedMaintenance = onFloorWrites
PNC.LiveBodyControl.ApplyHumanizedBodyFlags(body)
T.equal(onFloorWrites, floorWritesBeforeGroundedMaintenance,
    "periodic body maintenance erased a landing signal")
T.truthy(onFloor and knockedDown,
    "periodic body maintenance cleared the grounded pose")

stateName = "getup-fromonback"
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now + 200),
    "native get-up state released movement ownership")
stateName = "idle"
onFloor = false
knockedDown = false
T.falsy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "completed get-up action retained grounded ownership")
T.equal(modData.PNC_NativeGetUpLease, nil,
    "completed get-up retained its engine lease")

stateName = "onground"
onFloor = true
knockedDown = true
attackedBy = hostileZombie
record.runtime.attackAction = { attackType = "melee" }
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "hostile knockdown was not held for recovery")
T.equal(stateName, "onground", "hostile early recovery state")
T.equal(reactions, 1, "grounded counter count")
T.equal(record.runtime.attackAction, nil,
    "grounded hostile victim retained an attack")

now = now + 500
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "ground recovery stopped being authoritative")
T.equal(reactions, 1, "repeated ground counters")

now = now + 1000
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "grounded timeout recovery was not handled")
T.equal(stateName, "onground",
    "hostile recovery bypassed the action context")
T.equal(reanimateTimer, 0,
    "hostile knockdown did not trigger native get-up after timeout")
T.equal(variables.ShouldStandUp, true,
    "grounded recovery did not request the native stand-up transition")
T.truthy(cancelled >= 2 and held >= 2,
    "ground recovery did not suppress combat and movement")

record.runtime.groundedRecovery = nil
record.activeJob = "Sleep"
record.health = { state = "normal" }
record.runtime.facilityActivity = {
    capability = "sleep",
    phase = "SLEEPING",
}
reanimateTimer = 60
T.falsy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "sleeping NPC was forced to stand")
T.equal(reanimateTimer, 60, "sleeping NPC get-up timer changed")
T.equal(modData.PNC_NativeGetUpLease, nil,
    "sleeping NPC retained a native get-up lease")

record.activeJob = nil
record.runtime.facilityActivity = nil
record.health.state = "incapacitated"
T.falsy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now),
    "incapacitated NPC was forced to stand")
T.equal(reanimateTimer, 60, "incapacitated NPC get-up timer changed")

record.health.state = "normal"
stateName = "getup-fromonback"
authority = false
local replicaFloorWrites = onFloorWrites
T.truthy(PNC.LiveBodyControl.ShouldKeepEngineMovementActive(record, body),
    "replica did not preserve its native get-up ActionContext")
PNC.LiveBodyControl.MaintainHumanizedBody(body, now, true, true)
T.equal(onFloorWrites, replicaFloorWrites,
    "replica safety cleared floor state during native get-up")

local ragdollStateChanges = stateChanges
stateName = "falldown-ragdoll"
onFloor = false
knockedDown = true
ragdollSimulationActive = true
record.runtime.groundedRecovery = nil
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now + 100),
    "active ragdoll was not held for physics settlement")
T.equal(stateChanges, ragdollStateChanges,
    "active ragdoll was forced into a grounded animation state")
ZombieOnGroundState = {
    instance = function() return "ground_state" end,
}
ragdollSimulationActive = false
T.truthy(PNC.LiveBodyControl.TickGroundedRecovery(record, body, now + 200),
    "settled ragdoll was not handed to native ground recovery")
T.truthy(stateChanges > ragdollStateChanges,
    "settled ragdoll never left the ragdoll state")
stateName = "idle"
onFloor = false
knockedDown = false
record.runtime.groundedRecovery = nil

local bodyControlSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_LiveBodyControl.lua"
)
T.falsy(string.find(
        bodyControlSource,
        'setVariable("bKnockedDown"',
        1,
        true
    ),
    "ground recovery writes callback-owned bKnockedDown")
T.falsy(string.find(
        bodyControlSource,
        "PNC.Animation.PlayBump",
        1,
        true
    ),
    "ground recovery still routes native onground through bumped")

T.finish("pnc_grounded_recovery_smoke")
