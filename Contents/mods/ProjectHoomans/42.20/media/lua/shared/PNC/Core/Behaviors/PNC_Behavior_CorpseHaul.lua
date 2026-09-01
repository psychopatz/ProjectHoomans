-- Physical corpse hauling behavior. The server task owns the phase; this
-- behavior only exposes the current movement target to the normal PNC path
-- controller and keeps the actor out of ordinary combat/idle movement.

PNC = PNC or {}
PNC.BehaviorCorpseHaul = PNC.BehaviorCorpseHaul or {}

local Haul = PNC.BehaviorCorpseHaul
local Const = PNC.Const
local Common = PNC.BehaviorCommon

local KIND = Const.ORDER_CORPSE_HAUL or "corpse_haul"
local JOB = "CorpseHaul"

local function normalize(_, spec)
    spec = type(spec) == "table" and spec or {}
    return {
        kind = KIND,
        taskId = tostring(spec.taskId or ""),
        haulToken = tostring(spec.haulToken or ""),
        phase = tostring(spec.phase or "SOURCE_APPROACH"),
        baseId = tostring(spec.baseId or ""),
        facilityId = tostring(spec.facilityId or ""),
        sourceX = tonumber(spec.sourceX) or 0,
        sourceY = tonumber(spec.sourceY) or 0,
        sourceZ = tonumber(spec.sourceZ) or 0,
        interactionX = tonumber(spec.interactionX) or tonumber(spec.sourceX) or 0,
        interactionY = tonumber(spec.interactionY) or tonumber(spec.sourceY) or 0,
        interactionZ = tonumber(spec.interactionZ) or tonumber(spec.sourceZ) or 0,
        dropX = tonumber(spec.dropX) or 0,
        dropY = tonumber(spec.dropY) or 0,
        dropZ = tonumber(spec.dropZ) or 0,
        executorOnlineID = spec.executorOnlineID ~= nil
            and tonumber(spec.executorOnlineID) or nil,
        revision = tonumber(spec.revision) or 0,
    }
end

local function target(order)
    if order.phase == "DESTINATION_APPROACH"
        or order.phase == "DROP_PENDING"
    then
        return order.dropX, order.dropY, order.dropZ
    end
    if order.phase == "SOURCE_APPROACH"
        or order.phase == "GRAB_PENDING"
    then
        return order.interactionX, order.interactionY, order.interactionZ
    end
    return nil
end

function Haul.Tick(record, zombie)
    local order = record and record.orderSpec or nil
    local x, y, z
    if not order or order.kind ~= KIND then return false end

    record.activeJob = JOB
    record.activeBehavior = "CorpseHaul:" .. tostring(order.phase)
    Common.ClearCombatTarget(record, "corpse_haul", zombie)

    x, y, z = target(order)
    if x then
        if PNC.Core.Distance(record.x, record.y, x, y) > 0.8
            or math.abs((tonumber(record.z) or 0) - z) >= 0.5
        then
            Common.MoveRecord(record, zombie, x, y, z, "walk", 0.65,
                "corpse_haul")
            return true
        end
    end
    Common.HaltMovement(record, zombie, "corpse_haul")
    if zombie and zombie.faceLocationF and x then
        zombie:faceLocationF(x, y)
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(KIND, normalize)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(KIND, JOB)
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register(JOB, Haul.Tick)
end

return Haul
