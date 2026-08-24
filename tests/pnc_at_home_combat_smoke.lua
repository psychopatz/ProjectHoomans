local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_AtHome.lua"
)
local STATIC_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_StaticOrders.lua"
)

local responses = 0
local cleared = 0
local halted = 0
local applied = 0
local threatActive = true
local expectedDefenseRadius = 2

PNC = {
    Const = { GUARD_ENGAGE_RADIUS = 4 },
    Core = {
        Distance = function(x, y, targetX, targetY)
            local dx = (tonumber(x) or 0) - (tonumber(targetX) or 0)
            local dy = (tonumber(y) or 0) - (tonumber(targetY) or 0)
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            cleared = cleared + 1
            record.runtime.inCombatUntil = 0
        end,
        HaltMovement = function() halted = halted + 1 end,
        MoveRecord = function() end,
    },
    Animation = { Apply = function() applied = applied + 1 end },
    NavigationRouter = { Clear = function() end },
    OrderSystem = { RegisterNormalizer = function() end },
    JobSystem = { RegisterOrder = function() end },
    BehaviorRegistry = { Register = function() end },
}

T.load(FILE)

-- AtHome is loaded before the companion module in the real behavior-system
-- dependency order; it must resolve the combat dependency when it ticks.
PNC.BehaviorCompanion = { Internal = {
    TryRespondToThreat = function(_, _, constraint, options)
        responses = responses + 1
        T.equal(constraint.radius, expectedDefenseRadius,
            "At Home uses its bounded stay radius for defense")
        T.equal(options.areaDefense, true,
            "At Home opts into area-defense targeting")
        return threatActive
    end,
} }
T.load(STATIC_FILE)

local record = {
    id = "resident",
    x = 10,
    y = 10,
    z = 0,
    runtime = { inCombatUntil = 999999 },
    orderSpec = {
        kind = "colony_home",
        baseId = "base-1",
        x = 10,
        y = 10,
        z = 0,
        radius = 2,
    },
}

T.truthy(PNC.BehaviorAtHome.Tick(record, {}),
    "At Home handles an area threat through combat")
T.equal(record.activeBehavior, "AtHome:combat",
    "At Home temporarily exposes combat behavior")
T.equal(responses, 1, "At Home checks for threats while staying home")
T.equal(cleared, 0,
    "active At Home combat does not clear the live combat target")

threatActive = false
T.truthy(PNC.BehaviorAtHome.Tick(record, {}),
    "At Home resumes after its threat disappears")
T.equal(record.activeBehavior, "AtHome",
    "At Home returns to idle behavior after combat")
T.equal(cleared, 1,
    "At Home clears the stale combat lease after combat")
T.equal(halted, 1, "At Home resumes its idle movement hold")
T.equal(applied, 1, "At Home resumes its idle animation")
T.equal(record.orderSpec.kind, "colony_home",
    "temporary combat does not replace the durable home order")

local stayRecord = {
    id = "guard",
    x = 10,
    y = 10,
    z = 0,
    anchorX = 10,
    anchorY = 10,
    anchorZ = 0,
    orderSpec = { kind = "guard", x = 10, y = 10, z = 0 },
    runtime = {},
}
threatActive = true
expectedDefenseRadius = 4
T.truthy(PNC.BehaviorCompanion.Internal.TickGuardAnchor(stayRecord, {}),
    "Stay handles an area threat through combat")
T.equal(stayRecord.activeBehavior, "GuardAnchor:combat",
    "Stay temporarily exposes combat behavior")
threatActive = false
T.truthy(PNC.BehaviorCompanion.Internal.TickGuardAnchor(stayRecord, {}),
    "Stay resumes after its threat disappears")
T.equal(stayRecord.activeBehavior, "GuardAnchor",
    "Stay returns to its idle behavior after combat")

T.finish("pnc_at_home_combat_smoke")

T.finish("pnc_at_home_combat_smoke")
