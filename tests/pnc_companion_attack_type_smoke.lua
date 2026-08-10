local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
package.path = ROOT .. "../../?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local engaged = 0
local avoided = 0
local cleared = 0
local stealthSuspended = 0

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
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    BehaviorCommon = {
        GetOwner = function() return owner end,
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
        MoveRecord = function() return true end,
        HaltMovement = function() end,
    },
    BehaviorTargeting = {
        ResolveCompanionEngageTarget = function()
            return {
                kind = "zombie",
                x = 2,
                y = 0,
                z = 0,
                distSq = 4,
            }
        end,
    },
    BehaviorCombat = {
        TickEngage = function()
            engaged = engaged + 1
        end,
    },
    Perception = {
        ResolveCompanionTarget = function()
            return {
                kind = "zombie",
                x = 2,
                y = 0,
                z = 0,
                distSq = 4,
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

dofile(
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

assertEqual(PNC.BehaviorCompanion.Tick(record, {}, "FollowOwner"),
    true, "don't attack follow tick handled")
assertEqual(avoided, 1, "don't attack did not avoid threat")
assertEqual(engaged, 0, "don't attack engaged a target")
assertEqual(record.runtime.target, nil, "don't attack retained combat target")
assertEqual(record.activeBehavior, "AvoidThreat:no_attack",
    "avoid behavior label")
assertEqual(record.runtime.combatModeResolved, "none",
    "avoid debug combat mode")

record.attackType = "auto"
record.runtime.stealthActive = true
assertEqual(PNC.BehaviorCompanion.Tick(record, {}, "FollowOwner"),
    true, "auto attack follow tick handled")
assertEqual(engaged, 1, "auto attack did not engage")
assertEqual(avoided, 1, "auto attack used avoid-only branch")
assert(cleared >= 1, "don't attack did not clear combat state")
assertEqual(stealthSuspended, 1,
    "combat target did not suspend follow stealth")
assertEqual(record.runtime.stealthActive, false,
    "combat engagement retained sneak locomotion")

print("pnc_companion_attack_type_smoke: ok")
