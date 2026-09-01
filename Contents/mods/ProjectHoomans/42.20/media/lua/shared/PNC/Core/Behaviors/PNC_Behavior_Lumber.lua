-- Shared order projection for lumber work.
--
-- The server task executor owns tree mutation and movement decisions. This
-- shared handler keeps live clients and abstract records on the same durable
-- order/job identity without attempting to mutate world objects on clients.

PNC = PNC or {}
PNC.BehaviorLumber = PNC.BehaviorLumber or {}

local Lumber = PNC.BehaviorLumber
local Const = PNC.Const or {}

local KIND = Const.ORDER_LUMBER or "lumber"
local JOB = "Lumber"

local function normalize(_, spec)
    spec = type(spec) == "table" and spec or {}
    return {
        kind = KIND,
        lumberJobId = tostring(spec.lumberJobId or ""),
        zoneId = tostring(spec.zoneId or ""),
        phase = tostring(spec.phase or "WAITING"),
    }
end

function Lumber.Tick(record)
    local order = record and record.orderSpec or nil
    if not order or tostring(order.kind or "") ~= tostring(KIND) then
        return false
    end
    record.activeJob = JOB
    local runtime = record.runtime and record.runtime.lumber or nil
    record.activeBehavior = "Lumber:" .. tostring(
        runtime and runtime.phase or order.phase or "WAITING"
    )
    return true
end

-- WorkService projects live lumber orders as production_work. This handler
-- owns only movement/presentation; the server lumber adapter owns damage and
-- progress so abstract workers cannot accidentally advance twice.
function Lumber.TickWork(record, zombie, order)
    if not record or not order or order.operation ~= "LUMBER" then
        return false
    end
    record.activeJob = JOB
    local runtime = record.runtime and record.runtime.lumber or nil
    local phase = runtime and runtime.phase or order.phase or "WAITING"
    record.activeBehavior = "Lumber:" .. tostring(phase)
    local tx = runtime and runtime.approachX or order.x
    local ty = runtime and runtime.approachY or order.y
    local tz = runtime and runtime.approachZ or order.z
    if not tx or not ty or not tz then return true end
    -- A live record's x/y is a persisted projection and may lag the engine
    -- body by one or more behavior ticks.  Using it here kept reissuing the
    -- travel intent after the body had already reached the tree approach,
    -- which competed with the lumber executor's chop gate.  Abstract workers
    -- still use their canonical coordinates.
    local currentX = record.x
    local currentY = record.y
    local currentZ = record.z
    if zombie then
        if type(zombie.getX) == "function" then currentX = zombie:getX() end
        if type(zombie.getY) == "function" then currentY = zombie:getY() end
        if type(zombie.getZ) == "function" then currentZ = zombie:getZ() end
    end
    local distance = PNC.Core.Distance(currentX, currentY, tx, ty)
    -- Keep the behavior-side arrival envelope aligned with the server's
    -- adjacent-to-tree gate. A narrower envelope can hold the body just
    -- short of the selected approach point forever.
    if distance > 1.0
        or math.abs((tonumber(currentZ) or 0) - tonumber(tz)) >= 0.5
    then
        if PNC.BehaviorCommon and PNC.BehaviorCommon.ClearCombatTarget then
            PNC.BehaviorCommon.ClearCombatTarget(record,
                "lumber_travel", zombie)
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
            PNC.BehaviorCommon.MoveRecord(record, zombie, tx, ty, tz,
                "walk", 0.7, "lumber")
        end
        return true
    end
    if PNC.BehaviorCommon and PNC.BehaviorCommon.ClearCombatTarget then
        PNC.BehaviorCommon.ClearCombatTarget(record, "lumber_work", zombie)
    end
    if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
        PNC.BehaviorCommon.HaltMovement(record, zombie, "lumber_work")
    end
    local treeX = runtime and runtime.treeX or tx
    local treeY = runtime and runtime.treeY or ty
    if zombie and zombie.faceLocationF and treeX and treeY then
        zombie:faceLocationF(treeX + 0.5, treeY + 0.5)
    end
    if phase == "CHOPPING" then
        record.runtime = record.runtime or {}
        local scene = record.runtime.animationScene
        if zombie and PNC.AnimationScenes
            and PNC.AnimationScenes.Request
            and (not scene or scene.id ~= "lumber.chop")
        then
            PNC.AnimationScenes.Request(record, zombie, "lumber.chop", {
                reason = "lumber_chop", repeatMode = "loop",
            })
        end
        if zombie and zombie.setVariable then
            zombie:setVariable("PNCLumbering", true)
        end
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
    PNC.BehaviorRegistry.Register(JOB, Lumber.Tick)
end

return Lumber
