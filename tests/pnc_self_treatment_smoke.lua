local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Behaviors/PNC_Behavior_Treatment.lua"

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
        PlayBump = function(_, _, selected)
            bumpType = selected
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
assertEqual(moveRequest.mode, "run", "treatment retreat runs")
assertEqual(moveRequest.reason, "self_treatment_retreat", "retreat intent")
assertEqual(consumed, 0, "retreat consumed no bandage")

threat = nil
now = now + 100
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "safe NPC starts treatment")
assertEqual(bumpType, "BandageLeftArm", "body-part-specific animation")
assertEqual(record.runtime.selfTreatment.phase, "bandaging", "bandage phase")
assertEqual(treatmentSounds, 1, "self-bandage SFX")
assertEqual(zombieModData.PNC_ClientTreatmentSoundKey, "Hand_L:1100",
    "local replicated SFX dedupe key")

threat = { kind = "zombie", x = 2, y = 0, z = 0, distSq = 4 }
now = now + 100
assertEqual(PNC.BehaviorTreatment.Tick(record, zombie, now), true,
    "near threat interrupts treatment")
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

print("pnc_self_treatment_smoke: ok")
