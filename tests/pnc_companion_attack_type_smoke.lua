local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
T.addPackagePaths()

local engaged = 0
local avoided = 0
local shoved = 0
local moved = 0
local cleared = 0
local stealthSuspended = 0
local immediateThreat = nil

local owner = {
    getUsername = function() return "alice" end,
    getOnlineID = function() return 7 end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getVehicle = function() return nil end,
}

PNC = {
    Const = {
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_NONE = "none",
        COMBAT_SHOVE_RANGE = 1.35,
        PRESENCE_LIVE = "live",
        ORDER_FOLLOW = "follow",
        FOLLOW_IDLE_ENTER_DISTANCE = 2.4,
        FOLLOW_IDLE_EXIT_DISTANCE = 3.2,
        FOLLOW_SLOT_DISTANCE = 1.5,
        FOLLOW_SLOT_LATERAL = 0.95,
        FOLLOW_SLOT_ROW_DISTANCE = 0.75,
        FOLLOW_SLOT_ROW_LATERAL = 0.2,
        FOLLOW_SLOT_STOP_DISTANCE = 0.65,
        FOLLOW_DISTANCE = 1.8,
        FOLLOW_RUN_DISTANCE = 8,
    },
    Core = {
        Now = function() return 1000 end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    BehaviorCommon = {
        GetOwner = function() return owner end,
        SetCombatTarget = function(record, target)
            record.runtime.target = target
            return true
        end,
        ClearCombatTarget = function(record, reason)
            cleared = cleared + 1
            record.runtime.target = nil
            record.runtime.combatBlockReason = reason
        end,
        SetCombatDebug = function(record, _, reason, mode, status)
            record.runtime.combatBlockReason = reason
            record.runtime.combatModeResolved = mode
            record.runtime.weaponStatus = status
        end,
        MoveRecord = function()
            moved = moved + 1
            return true
        end,
        HaltMovement = function() end,
    },
    BehaviorTargeting = {
        ResolveCompanionProtectionTarget = function()
            return {
                kind = "zombie",
                x = 2,
                y = 0,
                z = 0,
                distSq = 4,
                immediateSelfDefense = true,
            }
        end,
    },
    BehaviorCombat = {
        TickEngage = function()
            engaged = engaged + 1
        end,
    },
    Combat = {
        TryShove = function()
            shoved = shoved + 1
            return true, "follow_no_attack_shove"
        end,
    },
    Perception = {
        FindImmediateZombieThreat = function()
            return immediateThreat
        end,
        ResolveCompanionProtectionTarget = function()
            return {
                kind = "zombie",
                x = 2,
                y = 0,
                z = 0,
                distSq = 4,
                immediateSelfDefense = true,
            }
        end,
    },
    CombatTactics = {
        AvoidThreat = function()
            avoided = avoided + 1
            return true, "companion_avoiding_threat"
        end,
    },
    Stealth = {
        UpdateFollowState = function() end,
        SuspendForCombat = function(record)
            stealthSuspended = stealthSuspended + 1
            record.runtime.stealthActive = false
            return true
        end,
    },
    Registry = {
        ForEach = function(callback)
            callback(PNC.TestRecord)
        end,
        MarkDirty = function() end,
    },
}

T.load(
    ROOT
        .. "Behaviors/BehaviorCompanion/PNC_BehaviorCompanion.lua"
)

local record = {
    id = "companion",
    alive = true,
    ownerUsername = "alice",
    ownerOnlineID = 7,
    attackType = "none",
    presenceState = "live",
    x = 4,
    y = 0,
    z = 0,
    orderSpec = { kind = "follow" },
    runtime = {
        target = { kind = "zombie" },
    },
}
PNC.TestRecord = record

-- Threat outside shove range: follower ignores horde and follows owner directly.
immediateThreat = { kind = "zombie", x = 6, y = 0, z = 0, distSq = 4 }
T.equal(PNC.BehaviorCompanion.Tick(record, {}, "FollowOwner"),
    true, "don't attack follow tick handled")
T.equal(avoided, 0, "don't attack should not flee with AvoidThreat")
T.equal(engaged, 0, "don't attack engaged a target")
T.equal(shoved, 0, "don't attack should not shove distant threat")
T.equal(moved, 1, "don't attack should continue following owner")
T.equal(record.runtime.target, nil, "don't attack retained combat target")
T.equal(record.activeBehavior, "FollowOwner:moving",
    "don't attack keeps following owner")

-- Immediate zombie inside shove range: follower pushes threat without engaging.
immediateThreat = { kind = "zombie", x = 4.8, y = 0, z = 0, distSq = 0.64 }
T.equal(PNC.BehaviorCompanion.Tick(record, {}, "FollowOwner"),
    true, "don't attack shove tick handled")
T.equal(shoved, 1, "don't attack should push nearby threat")
T.equal(engaged, 0, "don't attack shove should not enter combat engage")
T.equal(record.activeBehavior, "FollowOwner:push_threat",
    "push behavior label")
T.equal(record.runtime.combatModeResolved, "none",
    "push debug combat mode")

immediateThreat = nil
record.attackType = "auto"
record.runtime.stealthActive = true
T.equal(PNC.BehaviorCompanion.Tick(record, {}, "FollowOwner"),
    true, "auto attack follow tick handled")
T.equal(engaged, 1, "auto attack did not engage")
T.equal(avoided, 0, "auto attack used avoid-only branch")
T.truthy(cleared >= 1, "don't attack did not clear combat state")
T.equal(stealthSuspended, 1,
    "combat target did not suspend follow stealth")
T.equal(record.runtime.stealthActive, false,
    "combat engagement retained sneak locomotion")
T.finish("pnc_companion_attack_type_smoke")
