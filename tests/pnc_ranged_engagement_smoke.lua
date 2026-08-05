local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function countValue(values, expected)
    local count = 0
    local i
    for i = 1, #values do
        if values[i] == expected then
            count = count + 1
        end
    end
    return count
end

-- Engagement sequencing: an in-range shooter must discard stale locomotion,
-- acquire authoritative facing, and continue checking its cooldown without
-- flooding one log line per 75 ms AI pass.
local now = 10000
local calls = {}
local logs = {}
local repositionClose = false
local rangedAttempts = 0

PNC = {
    Const = {
        PRESENCE_LIVE = "LIVE",
        MELEE_RANGE = 1.3,
        RANGED_RANGE = 8.5,
        RANGED_MIN_STANDOFF = 2.2,
        COMBAT_BLOCK_LOG_REPEAT_MS = 5000,
    },
    Core = {
        Now = function() return now end,
        LogRecordDebug = function(_, message)
            logs[#logs + 1] = message
        end,
    },
    Combat = {
        Internal = {
            ATTACK_TIMINGS = {
                ranged = { duration = 620 },
            },
        },
        PumpAttackAction = function()
            return false, "no_attack"
        end,
        FaceTarget = function()
            calls[#calls + 1] = "face"
            return true
        end,
        TryRanged = function(_, _, target)
            rangedAttempts = rangedAttempts + 1
            calls[#calls + 1] = "try_ranged"
            if math.sqrt(target.distSq) > 8.5 then
                return false, "target_out_of_range"
            end
            return false, "cooldown_active"
        end,
        TryMelee = function()
            calls[#calls + 1] = "try_melee"
            return false, "target_out_of_range"
        end,
    },
    Equipment = {
        Describe = function()
            return {
                combatModeResolved = "ranged",
                weaponStatus = "ranged_ready",
            }
        end,
        ApplyCombatState = function() end,
    },
    CombatTactics = {
        MaintainRangedSpacing = function()
            calls[#calls + 1] = "spacing"
            return false, nil
        end,
        TryReposition = function(_, _, _, _, reason)
            calls[#calls + 1] = "reposition:" .. tostring(reason)
            if repositionClose and reason == "target_too_close" then
                return true, "maintaining_range"
            end
            return false, nil
        end,
        ClearRetreatState = function() end,
    },
    BehaviorCommon = {
        SetCombatDebug = function(record, _, reason)
            record.runtime.combatBlockReason = reason
        end,
        HaltMovement = function()
            calls[#calls + 1] = "hold"
        end,
        MoveRecord = function()
            calls[#calls + 1] = "move"
        end,
        ResolveCombatApproachMode = function(_, mode)
            return mode
        end,
    },
    PathService = {
        IsTraversalActive = function() return false end,
    },
}

dofile(ROOT .. "Combat/PNC_Combat_Engagement.lua")
dofile(ROOT .. "Behaviors/PNC_Behavior_Combat.lua")

local record = {
    id = "ranged_test",
    presenceState = "LIVE",
    runtime = {
        weaponStatus = "ranged_ready",
    },
}
local target = {
    kind = "zombie",
    zombieId = 42,
    x = 3,
    y = 0,
    z = 0,
    distSq = 9,
    visible = true,
}

PNC.BehaviorCombat.TickEngage(record, {}, target)
assertEqual(calls[1], "spacing", "ranged spacing owns movement before aiming")
assertEqual(calls[2], "hold", "ranged aim stops stale movement first")
assertEqual(calls[3], "face", "ranged aim faces after stopping")
assertEqual(calls[4], "try_ranged", "ranged attack evaluates after facing")

for _ = 1, 39 do
    now = now + 75
    PNC.BehaviorCombat.TickEngage(record, {}, target)
end
assertEqual(rangedAttempts, 40, "cooldown does not starve ranged attack checks")
assertEqual(#logs, 1, "identical cooldown log is rate limited")

now = now + 5000
PNC.BehaviorCombat.TickEngage(record, {}, target)
assertEqual(#logs, 2, "cooldown diagnostic can repeat after throttle window")

calls = {}
target.distSq = 100
PNC.BehaviorCombat.TickEngage(record, {}, target)
assertEqual(countValue(calls, "hold"), 0, "out-of-range travel is not held")
assertEqual(countValue(calls, "face"), 0, "travel facing is not leased out of range")
assertEqual(countValue(calls, "move"), 1, "out-of-range shooter closes distance")

calls = {}
target.distSq = 1
repositionClose = true
local attemptsBeforeClose = rangedAttempts
PNC.BehaviorCombat.TickEngage(record, {}, target)
assertEqual(rangedAttempts, attemptsBeforeClose, "unsafe point-blank range repositions before firing")
assertEqual(calls[1], "spacing", "preferred-distance controller evaluates point-blank response first")
assertEqual(calls[2], "reposition:target_too_close", "short standoff remains the fallback point-blank response")

-- Tactics: a normal cooldown with only one enemy in safe firing range must not
-- generate a retreat intent.
local retreatMoves = 0
local spatialZombies = {}
now = 20000
PNC = {
    Const = {
        PRESENCE_LIVE = "LIVE",
        MELEE_RANGE = 1.3,
        RANGED_MIN_STANDOFF = 2.2,
        COMBAT_RETREAT_STAMINA_RATIO = 0.10,
        COMBAT_REENGAGE_STAMINA_RATIO = 0.28,
        COMBAT_SURROUND_RADIUS = 1.8,
        COMBAT_PRESSURE_RADIUS = 3.0,
        COMBAT_HORDE_RADIUS = 5.5,
        COMBAT_HORDE_COUNT = 6,
        COMBAT_TARGET_CROWD_RADIUS = 2.2,
        COMBAT_TARGET_CROWD_COUNT = 3,
        COMBAT_KITE_RETREAT_LOCK_MS = 450,
        COMBAT_KITE_DAMAGE_PRESSURE_MS = 2500,
        COMBAT_KITE_DAMAGE_LOCK_MS = 900,
        COMBAT_KITE_DAMAGE_DISTANCE = 2.2,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
        IsManagedNPCBody = function() return false end,
    },
    PathService = {
        MoveToward = function()
            retreatMoves = retreatMoves + 1
            return true
        end,
    },
    BehaviorMoveIntent = {
        RequestMove = function()
            retreatMoves = retreatMoves + 1
            return true
        end,
    },
    Perception = {
        CountEnemyZombies = function(_, radius)
            return radius == 2.6 and 1 or 0
        end,
    },
    SpatialIndex = {
        QueryZombies = function() return spatialZombies end,
    },
    Skills = {
        GetLevel = function() return 0 end,
    },
    Stamina = {
        GetRatio = function() return 1 end,
    },
}

dofile(ROOT .. "Combat/PNC_Combat_Tactics.lua")

record = {
    id = "tactics_test",
    presenceState = "LIVE",
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
}
target = {
    kind = "zombie",
    x = 3,
    y = 0,
    z = 0,
    distSq = 9,
}
local repositioned = PNC.CombatTactics.TryReposition(
    record,
    {},
    target,
    "ranged",
    "cooldown_active",
    {}
)
assertEqual(repositioned, false, "safe cooldown does not trigger ranged retreat")
assertEqual(retreatMoves, 0, "safe cooldown does not author movement")

repositioned = PNC.CombatTactics.MaintainRangedSpacing(record, {}, target)
assertEqual(repositioned, true, "ranged spacing retreats from a nearby enemy")
assertEqual(retreatMoves, 1, "ranged spacing authors retreat movement")
PNC.CombatTactics.ClearRetreatState(record)
target.x = 6
target.distSq = 36
spatialZombies = {
    {
        isDead = function() return false end,
        getX = function() return 6 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    },
    {
        isDead = function() return false end,
        getX = function() return 6.5 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    },
    {
        isDead = function() return false end,
        getX = function() return 6 end,
        getY = function() return 0.5 end,
        getZ = function() return 0 end,
    },
}
repositioned = PNC.CombatTactics.MaintainRangedSpacing(record, {}, target)
assertEqual(repositioned, false, "safe ranged distance holds even when the target has a crowd")
assertEqual(retreatMoves, 1, "safe ranged distance authors no movement")

spatialZombies = {}
target.x = 1
target.distSq = 1
repositioned = PNC.CombatTactics.TryReposition(
    record,
    {},
    target,
    "ranged",
    "target_too_close",
    {}
)
assertEqual(repositioned, true, "point-blank target still triggers ranged retreat")
assertEqual(retreatMoves, 2, "point-blank retreat authors one movement intent")

-- Facing: the server immediately faces the live object and also records the
-- PathService lease used by multiplayer snapshots.
local directTarget
local leasedTarget
local liveTarget = {
    getX = function() return 4 end,
    getY = function() return 5 end,
    getZ = function() return 0 end,
}
local attacker = {
    faceThisObject = function(_, value)
        directTarget = value
    end,
}

PNC = {
    Core = {},
    Registry = {
        GetLiveZombie = function() return liveTarget end,
    },
    Animation = {},
    Equipment = {},
    Perception = {},
    PathService = {
        IsTraversalActive = function() return false end,
        RequestCombatFacing = function(_, _, value)
            leasedTarget = value
            return true
        end,
    },
}

dofile(ROOT .. "Combat/PNC_Combat.lua")

local faced = PNC.Combat.FaceTarget(
    { runtime = {} },
    attacker,
    { kind = "npc", id = "live_target" },
    620,
    "ranged_windup"
)
assertEqual(faced, true, "combat facing succeeds")
assertEqual(directTarget, liveTarget, "engine faces the live target object")
assertEqual(leasedTarget.x, 4, "network-facing lease uses live target x")
assertEqual(leasedTarget.y, 5, "network-facing lease uses live target y")

print("pnc_ranged_engagement_smoke: ok")
