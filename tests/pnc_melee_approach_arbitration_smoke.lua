local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Engagement.lua")

local move
local tryReason = "cooldown_active"

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogRecordDebug = function() end,
    },
    Const = {
        MELEE_RANGE = 1.3,
        MELEE_COMMIT_RANGE = 1.15,
        MELEE_APPROACH_STOP_DISTANCE = 0.92,
        COMBAT_BLOCK_LOG_REPEAT_MS = 5000,
    },
    Combat = {
        Internal = {
            refreshTargetDistance = function(_, _, target)
                return math.sqrt(target.distSq)
            end,
        },
        PumpAttackAction = function() return false, "no_attack" end,
        TryMelee = function()
            return false, tryReason
        end,
    },
    Equipment = {
        Describe = function()
            return {
                combatModeResolved = "melee",
                weaponStatus = "melee_ready",
                hasWeapon = true,
            }
        end,
        ApplyCombatState = function() end,
    },
    CombatTactics = {
        PreAttackDecision = function(record)
            record.runtime.combatTactical =
                record.runtime.combatTactical or {}
            record.runtime.combatTactical.decision =
                "melee_commit_window"
            return false, nil, nil
        end,
        ResolveMeleeApproach = function()
            return true, 0.92, "run"
        end,
        GetMeleeApproachPoint = function(_, target)
            return target.x, target.y, false
        end,
        TryReposition = function() return false end,
        ClearRetreatState = function() end,
    },
    CombatDefense = {
        Refresh = function() end,
    },
    BehaviorCommon = {
        HaltMovement = function() end,
        SetCombatDebug = function(record, _, reason)
            record.runtime.combatBlockReason = reason
        end,
        ResolveCombatApproachMode = function(_, preferred)
            return preferred
        end,
        MoveRecord = function(_, _, x, y, z, mode, stopDistance, reason)
            move = {
                x = x,
                y = y,
                z = z,
                mode = mode,
                stopDistance = stopDistance,
                reason = reason,
            }
            return true, "move_intent"
        end,
    },
    PathService = {
        IsTraversalActive = function() return false end,
    },
}

T.load(FILE)

local record = {
    id = "proactive_fighter",
    runtime = {},
}
local target = {
    kind = "zombie",
    zombieId = "z1",
    x = 1.91,
    y = 0,
    z = 0,
    distSq = 1.91 * 1.91,
    visible = true,
}

T.equal(
    PNC.CombatEngagement.Tick(record, {}, target),
    true,
    "engagement did not own melee tick"
)
T.equal(move and move.reason, "closing_to_melee",
    "cooldown blocked proactive melee approach")
T.equal(move and move.stopDistance, 0.92,
    "melee approach used the wrong strike stop distance")
T.equal(
    record.runtime.combatTactical.decision,
    "closing_to_melee",
    "overlay concealed the active melee approach"
)
T.equal(
    record.runtime.combatTactical.approachAccepted,
    true,
    "accepted approach was not exposed to diagnostics"
)

move = nil
target.distSq = 1.1 * 1.1
tryReason = "cooldown_active"
PNC.CombatEngagement.Tick(record, {}, target)
T.equal(move, nil,
    "formation-slot distance remained outside the melee commit window")
T.finish("pnc_melee_approach_arbitration_smoke")

T.finish("pnc_melee_approach_arbitration_smoke")
