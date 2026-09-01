local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local threatActive = true
local interrupts = 0
local engagements = 0
local clears = 0
local expectedRadius = 3
local target = {
    kind = "zombie",
    zombieId = 42,
    x = 11,
    y = 10,
    z = 0,
    visible = true,
}

PNC = {
    Const = {
        CAMP_ENGAGE_RADIUS = 3,
        CAMP_RADIUS = 3,
    },
    Core = {
        Now = function() return now end,
    },
    BehaviorTargeting = {
        UpdateTargetFromWorld = function(_, current)
            return threatActive and current or nil
        end,
        ResolveRoamingEngageTarget = function(_, radius)
            T.equal(radius, expectedRadius,
                "seated threat search uses the stay engagement radius")
            return threatActive and target or nil
        end,
    },
    BehaviorCombat = {
        TickEngage = function() engagements = engagements + 1 end,
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
                "seated threat uses the combat scene interruption reason")
            interrupts = interrupts + 1
            record.runtime.animationScene = nil
            return true
        end,
    },
}

local SeatedThreat = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_SeatedThreat.lua"
)

local record = {
    id = "camp-seat-threat",
    alive = true,
    x = 10,
    y = 10,
    z = 0,
    runtime = {
        facilityActivity = {
            automatic = true,
            seating = true,
            taskLeaseId = "",
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
    orderSpec = { kind = "facility_activity" },
}

local body = {}
T.truthy(SeatedThreat.Tick(record, body, now),
    "seated camp NPC enters combat when a nearby zombie is visible")
T.equal(interrupts, 1, "seated scene is interrupted exactly once")
T.equal(engagements, 1, "seated threat enters the existing combat pipeline")
T.equal(record.runtime.target, target,
    "seated threat stores the resolved combat target")
T.truthy(record.runtime.seatedThreat
        and record.runtime.seatedThreat.active == true,
    "seated combat keeps a transient resume state")

threatActive = false
now = 1500
T.falsy(SeatedThreat.Tick(record, body, now),
    "seated combat yields when the zombie is resolved")
T.equal(clears, 1, "seated combat clears its transient combat lease")
T.falsy(record.runtime.target, "resolved seated combat has no stale target")
T.falsy(record.runtime.seatedThreat,
    "resolved seated combat clears its resume state")
T.truthy(record.runtime.facilityActivity,
    "resolved seated combat preserves the facility activity for resumption")
T.equal(record.orderSpec.kind, "facility_activity",
    "resolved seated combat does not replace the facility order")

expectedRadius = 2
target = {
    kind = "zombie",
    zombieId = 43,
    x = 21,
    y = 20,
    z = 0,
    visible = true,
}
threatActive = true
now = 2000
local homeRecord = {
    id = "home-seat-threat",
    alive = true,
    x = 21,
    y = 20,
    z = 0,
    runtime = {
        facilityActivity = {
            automatic = true,
            seating = true,
            taskLeaseId = "",
            previousOrder = {
                kind = "colony_home",
                x = 20,
                y = 20,
                z = 0,
                radius = 2,
            },
        },
        animationScene = {
            id = "facility.living.sitFurniture",
            blocking = true,
        },
    },
    orderSpec = { kind = "facility_activity" },
}
T.truthy(SeatedThreat.Tick(homeRecord, body, now),
    "seated home NPC enters combat when a nearby zombie is visible")
T.equal(interrupts, 2,
    "seated home scene is interrupted by a nearby hostile")
T.equal(engagements, 2,
    "seated home threat uses the existing combat pipeline")

threatActive = false
now = 2500
T.falsy(SeatedThreat.Tick(homeRecord, body, now),
    "seated home combat yields when the zombie is resolved")
T.truthy(homeRecord.runtime.facilityActivity,
    "resolved home combat preserves the facility activity for resumption")

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Safety.lua"
)
local coordinateRecord = {
    runtime = {
        animationScene = { id = "facility.living.sitFurniture" },
        target = { x = 12, y = 12, z = 0 },
    },
    health = {},
}
T.falsy(PNC.AnimationScenes.InterruptForSafety(
    coordinateRecord,
    body,
    now
), "facility coordinates do not masquerade as combat targets")

local combatRecord = {
    runtime = {
        animationScene = { id = "facility.living.sitFurniture" },
        target = target,
    },
    health = {},
}
T.truthy(PNC.AnimationScenes.InterruptForSafety(
    combatRecord,
    body,
    now
), "actor targets still interrupt a blocking scene")

T.finish("pnc_seated_threat_smoke")
