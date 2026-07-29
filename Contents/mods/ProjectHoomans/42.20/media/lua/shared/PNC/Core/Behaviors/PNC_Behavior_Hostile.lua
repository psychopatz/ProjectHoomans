--[[
    PNC Behavior Hostile
    Owns hostile hunt and direct engage job handlers so aggression logic stays
    separate from faction-neutral roaming and colonist-follow rules.
]]

PNC = PNC or {}
PNC.BehaviorHostile = PNC.BehaviorHostile or {}

local Hostile = PNC.BehaviorHostile
local Common = PNC.BehaviorCommon
local Targeting = PNC.BehaviorTargeting
local BehaviorCombat = PNC.BehaviorCombat

function Hostile.Tick(record, zombie, job)
    local target
    local order = record.orderSpec or {}

    if job == "HuntNearestPlayer" then
        target = Targeting.ResolveHostileEngageTarget(record)
        if target then
            record.runtime.target = target
            BehaviorCombat.TickEngage(record, zombie, target)
            return true
        end
        Common.ClearCombatTarget(record, "seeking_hostile_target")
        Common.MoveRecord(
            record,
            zombie,
            tonumber(order.x) or record.anchorX,
            tonumber(order.y) or record.anchorY,
            tonumber(order.z) or record.anchorZ,
            "walk",
            2.0,
            "hunt_return_anchor"
        )
        return true
    end

    if job == "EngageTarget" then
        target = Targeting.UpdateTargetFromWorld(record, record.runtime.target)
        if target then
            record.runtime.target = target
            BehaviorCombat.TickEngage(record, zombie, target)
            return true
        end
        Common.ClearCombatTarget(record, "target_lost")
        return true
    end

    return false
end
