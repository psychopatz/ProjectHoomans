local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/PNC_Behavior_Treatment.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local threat
local treatable = true
local consumed = 0
local bumpType
local bumpFinished = 0
local moveRequest
local treatmentSounds = 0
local zombieModData = {}
local retreatAvailable = true
local maintainedBumps = 0
local bumpLeaseUntil

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        FACTION_HOSTILE = "hostile",
        SELF_BANDAGE_THREAT_RADIUS = 10,
        SELF_BANDAGE_INTERRUPT_RADIUS = 7,
        SELF_BANDAGE_RETREAT_DISTANCE = 5,
        SELF_BANDAGE_RETREAT_STOP_DISTANCE = 1,
        SELF_BANDAGE_RETRY_MS = 5000,
        ABSTRACT_SELF_BANDAGE_INTERVAL_MS = 30000,
    },
    Core = {
        Now = function() return now end,
    },
    Perception = {
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
        AvoidThreat = function(_, _, _, options)
            if not retreatAvailable then
                return false, "retreat_stalled"
            end
            moveRequest = {
                x = 5, y = 0, z = 0,
                mode = options.mode,
                stopDistance = options.stopDistance,
                reason = options.reason,
            }
            return true, options.reason
        end,
        ClearRetreatState = function() end,
    },
}

dofile(FILE)

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
                assertEqual(sound, "FirstAidApplyBandage", "vanilla bandage SFX")
                treatmentSounds = treatmentSounds + 1
            end,
        }
    end,
}

threat = { kind = "zombie", x = 1, y = 0, z = 0, distSq = 1 }
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "injured NPC retreats before treating")
assertEqual(moveRequest.mode, "walk", "exhausted treatment retreat preserves stamina")
assertEqual(moveRequest.reason, "self_treatment_retreat", "retreat intent")
assertEqual(consumed, 0, "retreat consumed no bandage")

threat = nil
now = now + 100
record.stamina.current = 100
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "safe NPC starts treatment")
assertEqual(bumpType, "BandageLeftArm", "body-part-specific animation")
assertEqual(record.runtime.selfTreatment.phase, "bandaging", "bandage phase")
assertEqual(treatmentSounds, 1, "self-bandage SFX")
assertEqual(bumpLeaseUntil, 2100, "bandage action lease covers treatment")
assertEqual(zombieModData.PNC_ClientTreatmentSoundKey, "Hand_L:1100",
    "local replicated SFX dedupe key")
assertEqual(zombieModData.PNC_ClientTreatmentAnimKey, "Hand_L:1100",
    "local replicated animation dedupe key")

now = now + 100
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "safe treatment remains active")
assertEqual(maintainedBumps, 1,
    "authority did not maintain the bandage selector")

threat = { kind = "zombie", x = 2, y = 0, z = 0, distSq = 4 }
now = now + 100
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now), false,
    "fit NPC interrupts treatment and returns to combat")
assertEqual(consumed, 0, "interrupted treatment consumed no item")
assertEqual(bumpFinished, 1, "interrupted animation released")

threat = nil
now = now + 5100
PNC.BehaviorTreatment.Tick(record, zombie, now)
now = now + 1000
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "completed treatment tick")
assertEqual(consumed, 1, "completed treatment consumes one item")
assertEqual(bumpFinished, 2, "completed animation released")

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
assertEqual(PNC.BehaviorTreatment.Tick(abstractRecord, nil, now), true,
    "abstract NPC simplifies treatment")
assertEqual(consumed, beforeAbstract + 1, "abstract treatment consumes once")
assertEqual(PNC.BehaviorTreatment.Tick(abstractRecord, nil, now + 1000), false,
    "abstract treatment cadence bounded")

treatable = true
threat = { kind = "zombie", x = 1, y = 0, z = 0, distSq = 1 }
retreatAvailable = false
record.runtime.selfTreatment.phase = "idle"
record.stamina.current = 10
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now + 2000), false,
    "stalled treatment retreat did not yield to defensive combat")
assertEqual(record.runtime.selfTreatment.interruptedReason, "retreat_stalled",
    "stalled treatment retreat reason")

print("pnc_self_treatment_smoke: ok")
