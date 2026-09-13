local T = require "tests/support/test"

local now = 1000
local threatActive = true
local interruptions = 0
local engagements = 0
local clears = 0
local threatScans = 0
local target = {
    kind = "zombie",
    zombieId = 101,
    x = 11,
    y = 10,
    z = 0,
    visible = true,
    threatening = true,
}

PNC = {
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
        GUARD_ENGAGE_RADIUS = 4,
        GUARD_RADIUS = 4,
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
        THREAT_GUARD_SCAN_MS = 350,
        THREAT_GUARD_VALIDATE_MS = 250,
        THREAT_GUARD_RELEASE_GRACE_MS = 900,
    },
    Core = {
        Now = function() return now end,
    },
    BehaviorTargeting = {
        UpdateTargetFromWorld = function(_, current)
            return threatActive and current or nil
        end,
        ResolveImmediateZombieThreat = function()
            threatScans = threatScans + 1
            return threatActive and target or nil
        end,
    },
    BehaviorCompanion = {
        Internal = {
            ResolveThreatTarget = function(_, constraint, options)
                T.equal(options.areaDefense, true,
                    "passive threat guard uses area-defense targeting")
                T.truthy(constraint.radius,
                    "passive threat guard supplies an engagement radius")
                return threatActive and target or nil
            end,
            EngageResolvedTarget = function(record, _, resolved)
                engagements = engagements + 1
                record.runtime.target = resolved
                return true
            end,
        },
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            clears = clears + 1
            record.runtime.target = nil
            record.runtime.inCombatUntil = 0
        end,
    },
    AnimationScenes = {
        Interrupt = function(record, _, reason)
            T.equal(reason, "combat",
                "threat guard interrupts a passive presentation for combat")
            interruptions = interruptions + 1
            record.runtime.animationScene = nil
            return true
        end,
    },
}

local ThreatGuard = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard.lua"
)

local facilityRecord = {
    id = "facility-worker",
    alive = true,
    attackType = "auto",
    x = 10,
    y = 10,
    z = 0,
    runtime = {
        facilityActivity = {
            capability = "living",
            seating = true,
            taskLeaseId = "lease-1",
            startedAt = 1,
            previousOrder = {
                kind = "camp",
                x = 10,
                y = 10,
                z = 0,
                radius = 3,
            },
        },
        animationScene = {
            id = "facility.living.sitFurniture",
            blocking = true,
        },
    },
    orderSpec = { kind = "facility_activity", capability = "living" },
}

T.truthy(ThreatGuard.Tick(facilityRecord, {}, now),
    "facility activity enters the temporary threat guard")
T.equal(facilityRecord.activeBehavior, "CombatGuard:engaged",
    "all passive owners expose the same combat guard behavior")
T.equal(engagements, 1, "facility threat enters the shared combat pipeline")
T.equal(interruptions, 1, "facility presentation is interrupted once")
T.equal(facilityRecord.orderSpec.kind, "facility_activity",
    "temporary combat preserves the durable facility order")
T.truthy(facilityRecord.runtime.facilityActivity,
    "temporary combat preserves the facility task lease state")

threatActive = false
now = 1250
T.truthy(ThreatGuard.Tick(facilityRecord, {}, now),
    "threat guard holds briefly while reacquiring a lost target")
T.equal(facilityRecord.activeBehavior, "CombatGuard:reacquiring",
    "target loss uses a bounded reacquisition phase")

now = 2000
T.falsy(ThreatGuard.Tick(facilityRecord, {}, now),
    "facility owner resumes after the threat-loss grace period")
T.equal(clears, 1, "threat guard clears its transient combat target once")
T.falsy(facilityRecord.runtime.threatGuard,
    "threat guard state is removed after combat ends")
local scansAfterRelease = threatScans
now = 2100
T.falsy(ThreatGuard.Tick(facilityRecord, {}, now),
    "passive threat scans remain quiet during the scan interval")
T.equal(threatScans, scansAfterRelease,
    "inactive threat probing retains its scan throttle")

target.x = 31
target.y = 30
target.threatening = false
threatActive = true
now = 3000
local workRecord = {
    id = "zone-worker",
    alive = true,
    attackType = "auto",
    x = 30,
    y = 30,
    z = 0,
    runtime = {},
    orderSpec = {
        kind = "production_work",
        x = 30,
        y = 30,
        z = 0,
        operation = "CRAFT",
    },
}

T.truthy(ThreatGuard.Tick(workRecord, {}, now),
    "zone work enters the same temporary threat guard for a nearby zombie")
T.equal(workRecord.activeBehavior, "CombatGuard:engaged",
    "zone work uses the shared combat guard behavior")
T.equal(engagements, 2, "zone work enters the shared combat pipeline")

local wakingRecord = {
    id = "waking-sleeper",
    alive = true,
    attackType = "auto",
    x = 30,
    y = 30,
    z = 0,
    runtime = {
        facilityActivity = {
            capability = "sleep",
            sleepWakePending = true,
            previousOrder = { kind = "colony_home", x = 30, y = 30,
                z = 0, radius = 3 },
        },
    },
    orderSpec = { kind = "facility_activity", capability = "sleep" },
}

T.falsy(ThreatGuard.Tick(wakingRecord, {}, now),
    "sleep wake cleanup retains ownership during its native release")
T.falsy(wakingRecord.runtime.threatGuard,
    "sleep wake cleanup does not create a competing combat lease")

T.finish("pnc_threat_guard_smoke")
