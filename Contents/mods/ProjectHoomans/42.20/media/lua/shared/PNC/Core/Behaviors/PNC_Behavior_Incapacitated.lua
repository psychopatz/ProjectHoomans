--[[
    PNC Behavior Incapacitated
    Handles the downed state so the main behavior coordinator does not mix
    crawl and revive-hold logic with normal jobs or combat.
]]

PNC = PNC or {}
PNC.BehaviorIncapacitated = PNC.BehaviorIncapacitated or {}

local Incapacitated = PNC.BehaviorIncapacitated
local Core = PNC.Core
local Const = PNC.Const
local Animation = PNC.Animation
local Common = PNC.BehaviorCommon

function Incapacitated.Tick(record, zombie)
    local owner
    local ownerDist

    record.activeJob = "Incapacitated"
    record.activeBehavior = "Incapacitated"
    owner = Common.GetOwner(record)
    Common.ClearCombatTarget(record, "incapacitated")
    record.runtime.attackAction = nil
    if zombie and owner and record.orderSpec and record.orderSpec.kind == Const.ORDER_FOLLOW then
        ownerDist = Core.Distance(record.x, record.y, owner:getX(), owner:getY())
        if ownerDist > (Const.FOLLOW_DISTANCE + 0.5) then
            Common.MoveRecord(record, zombie, owner:getX(), owner:getY(), owner:getZ(), "crawl", 1.2, "crawl_to_owner")
        else
            Common.HaltMovement(record, zombie, "incap_hold")
            if Animation and Animation.ApplyDowned then
                Animation.ApplyDowned(zombie, record, false)
            end
        end
    elseif zombie then
        Common.HaltMovement(record, zombie, "incap_hold")
        if Animation and Animation.ApplyDowned then
            Animation.ApplyDowned(zombie, record, false)
        else
            Animation.Apply(zombie, record, "Crawl")
        end
    end
    -- Keep asking for help while down.  This rides the tick that already runs
    -- for downed NPCs, so it costs one timestamp comparison per downed NPC
    -- per tick and never scans the world.  Only the server owns the audience
    -- gate and the network send; the hook is absent on a pure client, and
    -- presentation may never fail behavior.
    local hooks = PNC.SocialEventHooks
    local tick = hooks and hooks.TickIncapacitatedDistress
    if type(tick) == "function" then
        pcall(tick, record)
    end
    return true
end
