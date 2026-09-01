-- Physical corpse hauling behavior. The server task owns the phase; this
-- behavior only exposes the current movement target to the normal PNC path
-- controller and keeps the actor out of ordinary combat/idle movement.

PNC = PNC or {}
PNC.BehaviorCorpseHaul = PNC.BehaviorCorpseHaul or {}

local Haul = PNC.BehaviorCorpseHaul
local Common = PNC.BehaviorCommon

local JOB = "CorpseHaul"

-- Generic WorkService orders use the shared `production_work` order kind. The
-- server-side operation handler owns grapple/drop state; this shared handler
-- only drives the actor toward the authoritative current target.
function Haul.TickWork(record, zombie, order)
    local x = tonumber(order and order.x)
    local y = tonumber(order and order.y)
    local z = tonumber(order and order.z) or 0
    if not record or not order or order.operation ~= "CORPSE_HAUL"
        or not x or not y
    then return false end

    record.activeJob = JOB
    record.activeBehavior = "CorpseHaul:" .. tostring(order.phase)
    Common.ClearCombatTarget(record, "corpse_haul", zombie)
    if PNC.Core.Distance(record.x, record.y, x, y) > 0.8
        or math.abs((tonumber(record.z) or 0) - z) >= 0.5
    then
        Common.MoveRecord(record, zombie, x, y, z, "walk", 0.65,
            "corpse_haul")
        return true
    end
    Common.HaltMovement(record, zombie, "corpse_haul")
    if zombie and zombie.faceLocationF then zombie:faceLocationF(x, y) end
    return true
end

return Haul
