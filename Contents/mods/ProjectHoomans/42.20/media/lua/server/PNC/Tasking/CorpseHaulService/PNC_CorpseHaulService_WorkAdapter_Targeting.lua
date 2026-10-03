-- Corpse haul target and world readiness adapter.
--
-- This provider owns live/abstract target selection, destination validation,
-- world wait state, and work-scene status observation. Transfer and tick
-- orchestration remain in the work adapter.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Stockpile = PNC.StockpileAccessService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local WorkSequence = PNC.WorkSequence
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local assignmentForWorkOrder = Internal.assignmentForWorkOrder
local operationDiagnostic = Internal.operationDiagnostic

local function workTargetProvider(order, worker, live)
    local assignment = assignmentForWorkOrder(order)
    local corpse
    local data
    local phase
    local targetX
    local targetY
    local targetZ
    if not assignment then
        operationDiagnostic(order, nil, worker, "TARGET",
            "CORPSE_PAYLOAD_INVALID", "FAIL")
        return { ok = false, reason = "CORPSE_PAYLOAD_INVALID" }
    end
    if not live then
        -- Abstract claiming reserves only the durable identity and target
        -- coordinates. It must not inspect or navigate the corpse: its source
        -- chunk may be unloaded, which is a normal state for simulation.
        phase = tostring(order.phase or "SOURCE_APPROACH")
        return {
            ok = true, componentId = "corpse:" .. assignment.haulToken,
            claimKey = "corpse:" .. assignment.haulToken,
            targetKind = "corpse_transfer", target = {
                x = assignment.dropX, y = assignment.dropY,
                z = assignment.dropZ,
            }, phase = phase,
        }
    end
    corpse = Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, assignment.haulToken,
        assignment.deathMarkerId)
    if not corpse and tostring(order.phase or "") == "CARRYING"
        and Internal.resolveCorpseForCarry
    then
        corpse = Internal.resolveCorpseForCarry(order, nil, live)
    end
    if not corpse then
        operationDiagnostic(order, nil, worker, "TARGET", "CORPSE_NOT_FOUND",
            "FAIL")
        return { ok = false, reason = "CORPSE_NOT_FOUND" }
    end
    data = corpse.getModData and corpse:getModData() or nil
    if data and data.PNC_CorpseHaulTaskId
        and tostring(data.PNC_CorpseHaulTaskId) ~= tostring(order.id)
    then
        operationDiagnostic(order, nil, worker, "TARGET",
            "CORPSE_ALREADY_RESERVED", "FAIL")
        return { ok = false, reason = "CORPSE_ALREADY_RESERVED" }
    end
    phase = tostring(order.phase or "SOURCE_APPROACH")
    if phase == "DESTINATION_APPROACH" or phase == "CARRYING"
        or phase == "DROP_PENDING"
    then
        targetX, targetY, targetZ = assignment.dropX, assignment.dropY,
            assignment.dropZ
    else
        targetX, targetY, targetZ = assignment.interactionX,
            assignment.interactionY, assignment.interactionZ
    end
    return {
        ok = true, componentId = "corpse:" .. assignment.haulToken,
        claimKey = "corpse:" .. assignment.haulToken,
        targetKind = "corpse", target = {
            x = targetX, y = targetY, z = targetZ,
            stopDistance = phase == "CARRYING"
                and (tonumber(Service.CORPSE_CARRY_DROP_DISTANCE) or 1.75)
                or nil,
        },
        phase = phase,
    }
end

local function isDropPointAllowed(assignment)
    local x = assignment and assignment.dropX
    local y = assignment and assignment.dropY
    local z = assignment and assignment.dropZ
    if not assignment then return false end
    if assignment.destinationRegion then
        return GridRegion.containsPoint(assignment.destinationRegion, x, y, z)
    end
    if not Stockpile then return false end
    if Stockpile.ContainsFacilityRegionTile then
        return Stockpile.ContainsFacilityRegionTile(assignment.facilityId,
            x, y, z) == true
    end
    local region = Stockpile.GetFacilityRegion
        and Stockpile.GetFacilityRegion(assignment.facilityId) or nil
    return region ~= nil and GridRegion.containsPoint(region, x, y, z) == true
end

local function waitForWorld(order, task, reason)
    local now = Core.Now()
    local sameState = order.status == (Status.WAITING_FOR_WORLD
        or "WAITING_FOR_WORLD")
        and tostring(order.blockedReason or "") == tostring(reason or "")
    operationDiagnostic(order, task, nil, "WORLD_WAIT", reason, "WAIT")
    if task then
        task.worldWaitReason = reason
    end
    order.status = Status.WAITING_FOR_WORLD or "WAITING_FOR_WORLD"
    order.blockedReason = reason
    if not sameState then
        order.updatedAt = now
        if WorkRepository then WorkRepository.MarkDirty() end
    end
    return true
end

local function actionStatus(record, order)
    if not WorkSequence or not WorkSequence.Status then
        return "failed", "WORK_SEQUENCE_UNAVAILABLE"
    end
    local status = WorkSequence.Status(record, order)
    if status == "failed" then
        local state = WorkSequence.GetState and WorkSequence.GetState(record)
        return status, state and state.failed or "WORK_SCENE_FAILED"
    end
    return status
end

Internal.workTargetProvider = workTargetProvider
Internal.isDropPointAllowed = isDropPointAllowed
Internal.waitForWorld = waitForWorld
Internal.actionStatus = actionStatus

return Service
