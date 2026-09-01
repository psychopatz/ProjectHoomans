PNC = PNC or {}

local KIND = "production_work"
local JOB = "ProductionWork"
local SCENE_BY_OPERATION = {
    RESEARCH = "production.research",
    CRAFT = "production.craft",
    DISASSEMBLE = "production.disassemble",
    CONSTRUCT = "production.construct",
    RECONSTRUCT = "production.construct",
    DECONSTRUCT = "production.construct",
    BUILD_OBJECT = "production.construct",
}

local function normalize(_, spec)
    return { kind = KIND, workOrderId = tostring(spec.workOrderId or ""),
        operation = tostring(spec.operation or ""),
        phase = tostring(spec.phase or "WORK_AT_STATION"),
        haulToken = tostring(spec.haulToken or ""),
        sourceX = tonumber(spec.sourceX) or 0,
        sourceY = tonumber(spec.sourceY) or 0,
        sourceZ = tonumber(spec.sourceZ) or 0,
        interactionX = tonumber(spec.interactionX) or 0,
        interactionY = tonumber(spec.interactionY) or 0,
        interactionZ = tonumber(spec.interactionZ) or 0,
        dropX = tonumber(spec.dropX) or 0,
        dropY = tonumber(spec.dropY) or 0,
        dropZ = tonumber(spec.dropZ) or 0,
        facilityId = tostring(spec.facilityId or ""),
        stationId = tostring(spec.stationId or ""),
        stockpileNodeId = tostring(spec.stockpileNodeId or ""),
        x = tonumber(spec.x) or 0, y = tonumber(spec.y) or 0,
        z = tonumber(spec.z) or 0 }
end

local function tick(record, zombie)
    local order = record.orderSpec or {}
    if order.kind ~= KIND or not PNC.WorkService then return false end
    if order.operation == "CORPSE_HAUL"
        and PNC.BehaviorCorpseHaul
        and PNC.BehaviorCorpseHaul.TickWork
    then
        return PNC.BehaviorCorpseHaul.TickWork(record, zombie, order) == true
    end
    if order.operation == "LUMBER"
        and PNC.BehaviorLumber
        and PNC.BehaviorLumber.TickWork
    then
        return PNC.BehaviorLumber.TickWork(record, zombie, order) == true
    end
    record.activeJob = PNC.WorkDefinitions.JOB_BY_OPERATION[order.operation]
        or JOB
    record.activeBehavior = "Work:" .. tostring(order.operation)
    local distance = PNC.Core.Distance(record.x, record.y, order.x, order.y)
    if distance > 0.8 or math.abs((tonumber(record.z) or 0) - order.z) >= 0.5 then
        PNC.BehaviorCommon.ClearCombatTarget(record, "production_travel", zombie)
        PNC.BehaviorCommon.MoveRecord(record, zombie, order.x, order.y, order.z,
            "walk", 0.7, "production_work")
        return true
    end
    PNC.BehaviorCommon.ClearCombatTarget(record, "production_work", zombie)
    PNC.BehaviorCommon.HaltMovement(record, zombie, "production_work")
    if order.phase == "COLLECT_INPUTS" then
        record.activeBehavior = "Work:CollectInputs"
        local ok = PNC.WorkService.Commands.CollectInputs(
            order.workOrderId, record.id)
        if not ok then record.activeBehavior = "Work:CollectionBlocked" end
        return true
    end
    if zombie and zombie.faceLocationF then
        zombie:faceLocationF(order.x, order.y - 1)
    end
    record.runtime = record.runtime or {}
    local sceneId = SCENE_BY_OPERATION[order.operation]
    local scene = record.runtime.animationScene
    if sceneId and PNC.AnimationScenes and PNC.AnimationScenes.Request
        and (not scene or scene.id ~= sceneId)
    then
        PNC.AnimationScenes.Request(record, zombie, sceneId, {
            reason = "production_" .. string.lower(order.operation),
            repeatMode = "loop",
        })
    end
    local at = PNC.Core.Now()
    local previous = tonumber(record.runtime.lastProductionWorkAt) or at
    record.runtime.lastProductionWorkAt = at
    if zombie and zombie.setVariable then
        zombie:setVariable("PNCWorkOperation", tostring(order.operation))
    end
    PNC.WorkService.Commands.AddElapsed(order.workOrderId, record.id,
        math.max(0, (at - previous) / 1000))
    return true
end

PNC.OrderSystem.RegisterNormalizer(KIND, normalize)
PNC.JobSystem.RegisterOrder(KIND, JOB)
PNC.BehaviorRegistry.Register(JOB, tick)

return true
