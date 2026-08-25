local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Treatment.lua")

local now = 1000
local threat
local treatable = true
local consumed = 0
local bumpType
local bumpFinished = 0
local moveRequest
local treatmentSounds = 0
local zombieModData = {}
local maintainedBumps = 0
local bumpLeaseUntil
local retreatClears = 0

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        FACTION_HOSTILE = "hostile",
        SELF_BANDAGE_THREAT_RADIUS = 10,
        SELF_BANDAGE_INTERRUPT_RADIUS = 7,
        NPC_ZOMBIE_DEFENSE_RADIUS = 2.2,
        SELF_BANDAGE_RETREAT_DISTANCE = 5,
        SELF_BANDAGE_RETREAT_STOP_DISTANCE = 1,
        SELF_BANDAGE_RETRY_MS = 5000,
        ABSTRACT_SELF_BANDAGE_INTERVAL_MS = 30000,
    },
    Core = {
        Now = function() return now end,
    },
    Perception = {
        ResolveRecentAttacker = function() return nil end,
        FindImmediateZombieThreat = function() return threat end,
        FindNearestEnemyNPC = function() return nil end,
        FindNearestEnemyZombie = function() return threat end,
        FindNearestEnemyPlayer = function() return nil end,
    },
    NPCWounds = {
        FindTreatableWound = function()
            return treatable and "Hand_L" or nil
        end,
    },
    Treatment = {
        FindNPCBandage = function()
            return {
                fullType = "Base.RippedSheets",
                displayName = "Ripped Sheets",
            }
        end,
        HasNPCBandage = function() return true end,
        GetNPCBandageDuration = function() return 1000 end,
        TryNPCBandage = function()
            consumed = consumed + 1
            treatable = false
            return true, "Ripped Sheets"
        end,
    },
    Animation = {
        PlayBump = function(_, _, selected, options)
            bumpType = selected
            bumpLeaseUntil = options and options.leaseUntil or nil
        end,
        MaintainBump = function(_, _, selected, leaseUntil)
            bumpType = selected
            bumpLeaseUntil = leaseUntil
            maintainedBumps = maintainedBumps + 1
        end,
        FinishBump = function()
            bumpFinished = bumpFinished + 1
        end,
    },
    BehaviorMoveIntent = {
        Hold = function() end,
        RequestMove = function(_, x, y, z, mode, stopDistance, reason)
            moveRequest = {
                x = x, y = y, z = z, mode = mode,
                stopDistance = stopDistance, reason = reason,
            }
        end,
    },
    CombatTactics = {
        NeedsRecoveryRetreat = function(targetRecord)
            return targetRecord
                and targetRecord.stamina
                and (tonumber(targetRecord.stamina.current) or 100) < 20
                or false
        end,
        ClearRetreatState = function()
            retreatClears = retreatClears + 1
        end,
    },
}

T.load(FILE)

local record = {
    id = "live_treatment",
    alive = true,
    faction = "neutral",
    hostility = { attackNPCs = true, attackZombies = true },
    presenceState = "live",
    x = 0, y = 0, z = 0,
    runtime = {},
    health = { state = "normal" },
    stamina = { current = 10, max = 100 },
}
local zombie = {
    getModData = function() return zombieModData end,
    getEmitter = function()
        return {
            playSound = function(_, sound)
                T.equal(sound, "FirstAidApplyBandage", "vanilla bandage SFX")
                treatmentSounds = treatmentSounds + 1
            end,
        }
    end,
}

threat = { kind = "zombie", x = 1, y = 0, z = 0, distSq = 1 }
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now), false,
    "injured NPC yields the tick to combat")
T.equal(moveRequest, nil, "treatment did not replace combat with retreat")
T.equal(record.runtime.target, threat, "threat handed directly to combat")
T.equal(record.runtime.selfTreatment.interruptedReason, "threat_nearby",
    "unsafe treatment reason")
T.equal(retreatClears, 1, "stale treatment retreat released")
T.equal(consumed, 0, "unsafe treatment consumed no bandage")

threat = nil
now = now + 5100
record.stamina.current = 100
record.runtime.inCombatUntil = now + 2500
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "safe NPC starts treatment")
T.equal(bumpType, "BandageLeftArm", "body-part-specific animation")
T.equal(record.runtime.selfTreatment.phase, "bandaging", "bandage phase")
T.equal(record.runtime.inCombatUntil, 0,
    "bandaging clears the previous combat presentation lease")
T.equal(treatmentSounds, 1, "self-bandage SFX")
T.equal(bumpLeaseUntil, 7100, "bandage action lease covers treatment")
T.equal(zombieModData.PNC_ClientTreatmentSoundKey, "Hand_L:6100",
    "local replicated SFX dedupe key")
T.equal(zombieModData.PNC_ClientTreatmentAnimKey, "Hand_L:6100",
    "local replicated animation dedupe key")

now = now + 100
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "safe treatment remains active")
T.equal(maintainedBumps, 1,
    "authority did not maintain the bandage selector")

threat = { kind = "zombie", x = 2.3, y = 0, z = 0, distSq = 5.29 }
now = now + 100
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "enemy outside red safety radius does not cancel treatment")

threat = { kind = "zombie", x = 2, y = 0, z = 0, distSq = 4 }
now = now + 100
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now), false,
    "fit NPC interrupts treatment and returns to combat")
T.equal(consumed, 0, "interrupted treatment consumed no item")
T.equal(bumpFinished, 1, "interrupted animation released")

threat = nil
now = now + 5100
PNC.BehaviorTreatment.Tick(record, zombie, now)
now = now + 1000
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "completed treatment tick")
T.equal(consumed, 1, "completed treatment consumes one item")
T.equal(bumpFinished, 2, "completed animation released")

treatable = true
local abstractRecord = {
    id = "abstract_treatment",
    alive = true,
    faction = "neutral",
    hostility = { attackNPCs = true, attackZombies = true },
    presenceState = "abstract",
    x = 50, y = 50, z = 0,
    runtime = {},
    health = { state = "normal" },
}
local beforeAbstract = consumed
T.equal(PNC.BehaviorTreatment.Tick(abstractRecord, nil, now), true,
    "abstract NPC simplifies treatment")
T.equal(consumed, beforeAbstract + 1, "abstract treatment consumes once")
T.equal(PNC.BehaviorTreatment.Tick(abstractRecord, nil, now + 1000), false,
    "abstract treatment cadence bounded")

treatable = true
threat = { kind = "zombie", x = 1, y = 0, z = 0, distSq = 1 }
record.runtime.selfTreatment.phase = "idle"
record.stamina.current = 10
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now + 2000), false,
    "low stamina does not let treatment starve defensive combat")
T.equal(record.runtime.selfTreatment.interruptedReason, "threat_nearby",
    "low stamina still reports combat interruption")

record.hostility.attackZombies = false
T.equal(PNC.BehaviorTreatment.Tick(record, zombie, now + 2100), false,
    "non-aggressive NPC still treats a targeting zombie as danger")
T.equal(record.runtime.target, threat,
    "defensive zombie bypasses no-initiation policy")
T.finish("pnc_self_treatment_smoke")

T.finish("pnc_self_treatment_smoke")
