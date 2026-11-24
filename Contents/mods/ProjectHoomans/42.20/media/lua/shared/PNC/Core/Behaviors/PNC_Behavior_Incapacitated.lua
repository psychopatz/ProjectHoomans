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
    local now = Core and Core.Now and Core.Now() or 0
    local onFire = zombie and zombie.isOnFire and zombie:isOnFire() == true or false
    local square = zombie and zombie.getSquare and zombie:getSquare() or nil
    local fireSafety = PNC.BehaviorFireSafety
    local onHazardFire = fireSafety and fireSafety.IsHazardFireSquare
        and fireSafety.IsHazardFireSquare(square) == true or false

    record.activeJob = "Incapacitated"
    record.activeBehavior = "Incapacitated"
    owner = Common.GetOwner(record)
    Common.ClearCombatTarget(record, "incapacitated")
    record.runtime.attackAction = nil
    local crawlingFromFire = false
    if zombie and (onFire or onHazardFire) then
        record.runtime = record.runtime or {}
        if onHazardFire and fireSafety and fireSafety.FindSafeTileAwayFromFire then
            local safeSq = fireSafety.FindSafeTileAwayFromFire(zombie, square)
            record.runtime.incapFireExtinguishAt = nil
            if safeSq then
                Common.MoveRecord(
                    record, zombie,
                    safeSq:getX() + 0.5, safeSq:getY() + 0.5, safeSq:getZ(),
                    "crawl", 0.5, "crawl_from_fire"
                )
                crawlingFromFire = true
            end
        elseif onFire then
            local extinguishAt = tonumber(record.runtime.incapFireExtinguishAt)
            if not extinguishAt then
                extinguishAt = now + (tonumber(Const and Const.FIRE_INCAP_EXTINGUISH_MS) or 3000)
                record.runtime.incapFireExtinguishAt = extinguishAt
            elseif now >= extinguishAt then
                if zombie.StopBurning then
                    zombie:StopBurning()
                elseif zombie.setOnFire then
                    zombie:setOnFire(false)
                end
                record.runtime.fireState = nil
                record.runtime.incapFireExtinguishAt = nil
            end
        end
    elseif record and record.runtime then
        record.runtime.incapFireExtinguishAt = nil
    end
    if not crawlingFromFire and zombie and owner and record.orderSpec and record.orderSpec.kind == Const.ORDER_FOLLOW then
        ownerDist = Core.Distance(record.x, record.y, owner:getX(), owner:getY())
        if ownerDist > (Const.FOLLOW_DISTANCE + 0.5) then
            Common.MoveRecord(record, zombie, owner:getX(), owner:getY(), owner:getZ(), "crawl", 1.2, "crawl_to_owner")
        else
            Common.HaltMovement(record, zombie, "incap_hold")
            if Animation and Animation.ApplyDowned then
                Animation.ApplyDowned(zombie, record, false)
            end
        end
    elseif not crawlingFromFire and zombie then
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
