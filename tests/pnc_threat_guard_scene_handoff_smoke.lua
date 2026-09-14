local T = require "tests/support/test"

local now = 1000
local engagements = 0
local interrupts = 0
local stops = 0

local target = {
    kind = "npc",
    id = "attacker",
    x = 1,
    y = 0,
    z = 0,
    visible = true,
    threatening = true,
    immediateSelfDefense = true,
}

local function basePNC()
    return {
        Const = {
            ORDER_CAMP = "camp",
            ORDER_GUARD = "guard",
            ORDER_PATROL = "patrol",
            ORDER_ROAM = "roam",
            ORDER_LUMBER = "lumber",
            ORDER_FISHING = "fishing",
            ORDER_SCAVENGE = "scavenge",
            ATTACK_TYPE_AUTO = "auto",
            ATTACK_TYPE_NONE = "none",
            CAMP_ENGAGE_RADIUS = 3,
            CAMP_RADIUS = 3,
            TARGET_IMMEDIATE_THREAT_RADIUS = 6,
            TARGET_RECENT_ATTACKER_MS = 5000,
            THREAT_GUARD_SCAN_MS = 350,
            THREAT_GUARD_VALIDATE_MS = 250,
            THREAT_GUARD_RELEASE_GRACE_MS = 900,
        },
        Core = {
            Now = function() return now end,
        },
        BehaviorTargeting = {
            ResolveImmediateNPCThreat = function() return target end,
            UpdateTargetFromWorld = function() return target end,
        },
        BehaviorCompanion = {
            Internal = {
                ResolveThreatTarget = function() return nil end,
                EngageResolvedTarget = function(record, _, resolved)
                    engagements = engagements + 1
                    record.runtime.target = resolved
                    return true
                end,
            },
        },
        BehaviorCommon = {
            SetCombatTarget = function(record, resolved)
                record.runtime.target = resolved
                return true
            end,
            ClearCombatTarget = function(record)
                record.runtime.target = nil
            end,
        },
        AnimationScenes = {
            Interrupt = function(record, _, reason)
                T.equal(reason, "combat",
                    "threat guard uses the combat scene reason")
                interrupts = interrupts + 1
                return false
            end,
            Stop = function(record)
                stops = stops + 1
                record.runtime.animationScene = nil
                return true
            end,
        },
    }
end

PNC = basePNC()
local ThreatGuard = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard.lua"
)

local record = {
    id = "victim",
    alive = true,
    attackType = "auto",
    x = 0,
    y = 0,
    z = 0,
    runtime = {
        animationScene = {
            id = "social.surrender",
            blocking = true,
        },
    },
    orderSpec = { kind = "camp", x = 0, y = 0, z = 0, radius = 3 },
}

T.truthy(ThreatGuard.Tick(record, {}, now),
    "combat handoff succeeds after forcing a stale blocking scene to stop")
T.equal(interrupts, 1, "normal scene interruption is attempted first")
T.equal(stops, 1, "a surviving blocking scene receives a force-stop fallback")
T.equal(engagements, 1, "combat starts after the blocking scene is released")

-- A sleep stop starts a native wake transaction. The guard must release this
-- tick so FacilityJobs can pump the wake instead of advertising Fighting while
-- the body is still owned by the sleep carrier.
interrupts = 0
stops = 0
engagements = 0
PNC.AnimationScenes.Interrupt = function(record)
    interrupts = interrupts + 1
    record.runtime.facilityActivity.sleepWakePending = true
    return true
end
PNC.AnimationScenes.Stop = function(record)
    stops = stops + 1
    record.runtime.animationScene = nil
    return true
end
record = {
    id = "sleeping-victim",
    alive = true,
    attackType = "auto",
    x = 0,
    y = 0,
    z = 0,
    runtime = {
        facilityActivity = {
            capability = "sleep",
        },
        animationScene = {
            id = "facility.sleep.bed",
            blocking = true,
        },
    },
    orderSpec = { kind = "facility_activity", capability = "sleep" },
}

T.falsy(ThreatGuard.Tick(record, {}, now),
    "sleep wake releases the threat guard to the facility wake owner")
T.equal(engagements, 0,
    "sleep wake does not claim combat before the native carrier is released")
T.falsy(record.runtime.threatGuard,
    "sleep wake does not retain a stale combat guard")

-- The sleep owner preserves the just-acquired target so a hostile that stops
-- refreshing its target during the wake animation cannot erase self-defense.
local facilityInternal = {
    State = function(value) return value.runtime.facilityActivity end,
}
PNC.FacilityJobsBehaviorInternal = facilityInternal
local sleepRecord = {
    id = "sleeping-victim",
    runtime = {
        facilityActivity = {
            capability = "sleep",
        },
        threatGuard = {
            target = target,
        },
    },
}
facilityInternal.BeginSleepWake = nil
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Lifecycle.lua"
)
T.truthy(PNC.FacilityJobsBehaviorInternal.BeginSleepWake(
    sleepRecord,
    {},
    "interrupted:combat"
), "sleep wake transaction starts")
T.equal(sleepRecord.runtime.recentThreat.kind, "npc",
    "sleep combat wake preserves the NPC threat kind")
T.equal(sleepRecord.runtime.recentThreat.id, "attacker",
    "sleep combat wake preserves the NPC threat identity")

T.finish("pnc_threat_guard_scene_handoff_smoke")
