local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Behaviors/PNC_Behavior_Roaming.lua"

local now = 1000
local haltCount = 0
local moveCount = 0
local threatScans = 0
local registeredTick

PNC = {
    Const = {
        JOB_ROAM = "Roam",
        ORDER_ROAM = "roam",
        ORDER_HOSTILE_ROAM = "hostile_roam",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 8,
        ROAM_TARGET_RADIUS = 12,
        ROAM_REACHED_DISTANCE = 0.8,
        ROAM_PAUSE_MIN_MS = 5000,
        ROAM_PAUSE_MAX_MS = 12000,
        ROAM_THREAT_MOVING_SCAN_MS = 250,
        ROAM_THREAT_IDLE_SCAN_MS = 500,
    },
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            record.runtime.target = nil
        end,
        HaltMovement = function()
            haltCount = haltCount + 1
        end,
        MoveRecord = function(
            record,
            _,
            x,
            y,
            z,
            mode,
            reachedDistance,
            reason
        )
            moveCount = moveCount + 1
            record.lastMove = {
                x = x,
                y = y,
                z = z,
                mode = mode,
                reachedDistance = reachedDistance,
                reason = reason,
            }
            return true
        end,
    },
    BehaviorTargeting = {
        ResolveRoamingEngageTarget = function()
            threatScans = threatScans + 1
            return nil
        end,
    },
    BehaviorCombat = {
        TickEngage = function()
            error("combat should not run without a target")
        end,
    },
    BehaviorRegistry = {
        Register = function(_, tick)
            registeredTick = tick
        end,
    },
    JobSystem = {
        RegisterOrder = function() end,
    },
    OrderSystem = {
        RegisterNormalizer = function() end,
    },
}

-- Deterministic pause/goal generation: the first sample selects the minimum
-- dwell and later samples produce a valid center goal.
ZombRandFloat = function()
    return 0
end

dofile(FILE)
assert(type(registeredTick) == "function",
    "roaming behavior did not register")

local record = {
    id = "roamer",
    x = 10,
    y = 20,
    z = 0,
    anchorX = 10,
    anchorY = 20,
    anchorZ = 0,
    runtime = {},
    -- Old saves persist this former default pair. It should migrate to the
    -- calmer dwell profile without changing explicitly customized orders.
    orderSpec = {
        kind = "roam",
        roamMode = "area",
        x = 10,
        y = 20,
        z = 0,
        radius = 8,
        targetRadius = 12,
        reachedDistance = 0.8,
        moveMode = "walk",
        pauseMinMs = 2500,
        pauseMaxMs = 7000,
    },
}

assert(registeredTick(record, {}))
assert(record.runtime.roaming.phase == "idle",
    "new roaming order immediately started walking")
assert(record.runtime.roaming.waitUntil == 6000,
    "legacy default roaming order did not adopt the new dwell minimum")
assert(record.activeBehavior == "Roam:area:idle",
    "idle roam phase was not exposed to scene eligibility/debugging")
assert(haltCount == 1 and moveCount == 0,
    "initial roam dwell did not halt movement")
assert(threatScans == 1,
    "initial safety scan did not run")

now = 1100
assert(registeredTick(record, {}))
assert(moveCount == 0,
    "roamer moved during its dwell window")
assert(threatScans == 1,
    "idle threat query ignored its negative-result cache")
now = 1500
record.runtime.target = { id = "stale_target" }
assert(registeredTick(record, {}))
assert(threatScans == 2,
    "idle threat scan did not refresh at its bounded interval")
assert(moveCount == 0,
    "threat refresh broke the dwell phase")
assert(record.runtime.target == nil,
    "invalid roam target kept an idle NPC in combat LOD")

now = 6000
assert(registeredTick(record, {}))
assert(record.runtime.roaming.phase == "moving",
    "expired dwell did not transition to a movement phase")
assert(moveCount == 1,
    "expired dwell did not issue a roaming move")
assert(record.lastMove.reason == "roam_area",
    "roaming move lost its navigation reason")

print("pnc_roaming_dwell_smoke: ok")
