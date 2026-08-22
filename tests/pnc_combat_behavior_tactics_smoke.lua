local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Combat.lua")
local ENGAGEMENT_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Engagement.lua")

local calls = {}
local mode = "melee"
local preMoved = false
local preAction = "shove"
local rangedReason = "friendly_fire_risk"
local reloadPressure = false

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogRecordDebug = function() end,
    },
    Const = {
        MELEE_RANGE = 1.3,
        RANGED_RANGE = 8.5,
        RANGED_MIN_STANDOFF = 2.2,
        COMBAT_BLOCK_LOG_REPEAT_MS = 5000,
    },
    Combat = {
        Internal = {
            ATTACK_TIMINGS = {
                ranged = { duration = 620 },
            },
        },
        PumpAttackAction = function() return false, "no_attack" end,
        TryShove = function()
            calls[#calls + 1] = "shove"
            return true, "pressure_shove"
        end,
        TryMelee = function()
            calls[#calls + 1] = "melee"
            return true, "melee_attack_started"
        end,
        TryRanged = function()
            calls[#calls + 1] = "ranged"
            return false, rangedReason
        end,
        FaceTarget = function() calls[#calls + 1] = "face" end,
        CancelAttackAction = function(record)
            calls[#calls + 1] = "cancel_reload"
            record.runtime.attackAction = nil
            return true
        end,
    },
    Equipment = {
        Describe = function()
            return {
                combatModeResolved = mode,
                weaponStatus = mode .. "_ready",
                hasWeapon = true,
            }
        end,
        ApplyCombatState = function() end,
    },
    CombatTactics = {
        PreAttackDecision = function()
            calls[#calls + 1] = "pre"
            return preMoved, preMoved and "melee_pressure_retreat"
                or (preAction == "shove" and "pressure_shove" or nil),
                preAction
        end,
        MaintainRangedSpacing = function()
            calls[#calls + 1] = "spacing"
            return false
        end,
        TryReposition = function(_, _, _, _, reason)
            calls[#calls + 1] = "reposition:" .. tostring(reason)
            return reason == "friendly_fire_risk", "clearing_fire_lane"
        end,
        ClearRetreatState = function() end,
        ShouldInterruptReload = function()
            return reloadPressure, "reload_interrupted_by_pressure"
        end,
    },
    BehaviorCommon = {
        HaltMovement = function() calls[#calls + 1] = "hold" end,
        SetCombatDebug = function(record, _, reason)
            record.runtime.combatBlockReason = reason
        end,
        MoveRecord = function() calls[#calls + 1] = "move" end,
        ResolveCombatApproachMode = function(_, preferred) return preferred end,
    },
    PathService = {
        IsTraversalActive = function() return false end,
    },
}

T.load(ENGAGEMENT_FILE)
T.load(FILE)

local record = {
    id = "fighter",
    runtime = {},
}
local target = {
    kind = "zombie",
    zombieId = "z1",
    x = 1,
    y = 0,
    z = 0,
    distSq = 1,
    visible = true,
}

PNC.BehaviorCombat.TickEngage(record, {}, target)
T.equal(calls[1], "pre", "tactical decision runs before attacks")
T.equal(calls[2], "shove", "pressure shove runs before melee strike")
T.equal(calls[3], "hold", "shove owns movement")
for i = 1, #calls do
    T.truthy(calls[i] ~= "melee", "normal melee bypassed tactical shove")
end

calls = {}
preMoved = true
preAction = nil
PNC.BehaviorCombat.TickEngage(record, {}, target)
T.equal(calls[1], "pre", "retreat decision evaluated")
T.equal(#calls, 1, "retreat prevents attack commitment")

calls = {}
preMoved = false
mode = "ranged"
PNC.BehaviorCombat.TickEngage(record, {}, target)
T.equal(calls[1], "pre", "ranged precheck runs")
T.equal(calls[2], "hold", "ranged attack holds before spacing")
T.equal(calls[#calls - 1], "ranged", "ranged attack checks fire lane")
T.equal(
    calls[#calls],
    "reposition:friendly_fire_risk",
    "blocked fire lane causes strafe request"
)

calls = {}
mode = "mixed"
target.distSq = 2.25
PNC.BehaviorCombat.TickEngage(record, {}, target)
T.equal(calls[1], "pre", "mixed close-range precheck runs")
T.equal(calls[2], "melee",
    "mixed close-range combat commits melee before ranged spacing")
for i = 1, #calls do
    T.truthy(calls[i] ~= "spacing",
        "mixed melee switch backed away through ranged spacing")
end

calls = {}
target.distSq = 9
PNC.BehaviorCombat.TickEngage(record, {}, target)
T.truthy(calls[#calls] == "hold",
    "blocked mixed firearm lane did not commit melee fallback")
local sawMeleeFallback = false
for i = 1, #calls do
    if calls[i] == "melee" then sawMeleeFallback = true end
    T.truthy(calls[i] ~= "reposition:friendly_fire_risk",
        "mixed friendly-fire block strafed instead of melee fallback")
end
T.truthy(sawMeleeFallback,
    "mixed friendly-fire block never attempted melee fallback")

calls = {}
reloadPressure = true
record.runtime.attackAction = { attackType = "reload" }
T.equal(
    PNC.BehaviorCombat.TickCommittedAction(record, {}),
    false,
    "unsafe reload releases committed behavior"
)
T.equal(calls[1], "cancel_reload", "unsafe reload is cancelled")
T.equal(record.runtime.attackAction, nil, "cancelled reload state cleared")
T.finish("pnc_combat_behavior_tactics_smoke")

T.finish("pnc_combat_behavior_tactics_smoke")
