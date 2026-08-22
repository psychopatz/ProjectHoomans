local T = require "tests/support/test"

local appliedMode
PNC = {
    Core = { Now = function() return 1000 end },
    Const = {},
    PathService = {},
    NavigationRouter = {},
    Combat = { HasActiveAttack = function(record)
        return record.runtime.attackAction ~= nil
    end },
    Equipment = {
        Describe = function() return { combatModeResolved = "melee",
            weaponStatus = "equipped" } end,
        ApplyCombatState = function(_, _, attackMode)
            appliedMode = attackMode
            return true
        end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Common.lua")
local Common = PNC.BehaviorCommon
local body = {}
local record = { id = "npc:1", runtime = {
    target = { kind = "zombie" }, inCombatUntil = 9000,
} }
Common.ClearCombatTarget(record, "target_lost", body)
T.equal(record.runtime.target, nil, "disengage clears target")
T.equal(record.runtime.inCombatUntil, 0, "disengage clears combat lease")
T.equal(appliedMode, false, "disengage restores non-combat hands")

record.runtime.attackAction = { finishAt = 1200 }
record.runtime.inCombatUntil = 9000
Common.ClearCombatTarget(record, "perception_gap", body)
T.equal(record.runtime.inCombatUntil, 9000,
    "committed attack retains combat lease")
T.equal(appliedMode, true, "committed attack retains combat hands")
T.finish("pnc_combat_disengage_smoke")
