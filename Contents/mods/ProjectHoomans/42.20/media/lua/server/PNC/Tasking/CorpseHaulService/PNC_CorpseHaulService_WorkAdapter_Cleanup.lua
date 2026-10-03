-- Corpse haul live-worker and durable runtime cleanup.
--
-- Cleanup is kept as one boundary because route ownership, carried-corpse
-- markers, runtime indexes, and work sequence state must be released together.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local WorkSequence = PNC.WorkSequence
local assignmentForWorkOrder = Internal.assignmentForWorkOrder
local clearCorpseTaskMarker = Internal.clearCorpseTaskMarker

local function resetLiveWorkState(record, zombie, reason)
    local runtime = record and record.runtime or nil
    local sceneStopped = false
    local pathReset = false
    local pathService = PNC.PathService
    local scene = runtime and runtime.animationScene or nil
    local sequence = runtime and runtime.workSequence or nil
    local ownsScene = scene
        and (
            sequence and tostring(sequence.sceneId or "")
                == tostring(scene.id or "")
            or tostring(scene.id or "") == "production.corpse_grab"
            or tostring(scene.id or "") == "production.corpse_drop"
        )

    if not runtime then return sceneStopped, pathReset end

    if ownsScene
        and PNC.AnimationScenes
        and PNC.AnimationScenes.Stop
    then
        sceneStopped = PNC.AnimationScenes.Stop(
            record,
            zombie,
            reason or "corpse_haul_cleanup"
        ) == true
    end

    if pathService and pathService.Commands
        and pathService.Commands.Reset
    then
        pathService.Commands.Reset(
            record,
            zombie,
            reason or "corpse_haul_cleanup"
        )
        pathReset = true
    elseif pathService and pathService.Reset then
        pathService.Reset(zombie, record, reason or "corpse_haul_cleanup")
        pathReset = true
    else
        runtime.localNavigation = nil
        runtime.pathing = nil
        runtime.moveIntent = nil
    end

    runtime.followState = nil
    runtime.target = nil
    runtime.corpseHaulCarrying = nil
    runtime.lastPathX = nil
    runtime.lastPathY = nil
    runtime.corpseHaulCleanupAt = Core.Now()
    runtime.corpseHaulCleanupReason = reason or "corpse_haul_cleanup"
    runtime.corpseHaulCleanupSceneStopped = sceneStopped
    runtime.corpseHaulCleanupPathReset = pathReset
    if zombie and zombie.setVariable then
        zombie:setVariable("PNCCorpseCarrying", false)
    end
    return sceneStopped, pathReset
end

local function clearWorkRuntime(order, reason)
    local taskId = tostring(order and order.id or "")
    local assignment = assignmentForWorkOrder(order)
    local task = Service.Runtime.byTask[taskId]
    local record = order and order.workerId and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    local zombie = record and Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    local status = order and tostring(order.status or "") or ""
    local preserveCarriedCorpse = (task and task.carrying
        or tostring(order.phase or "") == "CARRYING")
        and order.completionStarted ~= true
        and status ~= tostring(Status.CANCELLING or "CANCELLING")
        and status ~= tostring(Status.CANCELLED or "CANCELLED")
        and status ~= tostring(Status.COMPLETED or "COMPLETED")
        and status ~= tostring(Status.FAILED or "FAILED")
    if preserveCarriedCorpse and task and order.payload
        and task.carryX and task.carryY and task.carryZ
    then
        order.payload.carryX, order.payload.carryY, order.payload.carryZ =
            task.carryX, task.carryY, task.carryZ
    end
    resetLiveWorkState(record, zombie, reason)
    local carriedCorpse = Internal.clearCorpseCarry
        and Internal.clearCorpseCarry(order, task, zombie) or nil
    if carriedCorpse then
        local data = carriedCorpse.getModData
            and carriedCorpse:getModData() or nil
        if not preserveCarriedCorpse and data
            and tostring(data.PNC_CorpseHaulTaskId or "")
            == taskId
        then
            data.PNC_CorpseHaulTaskId = nil
            Internal.transmit(carriedCorpse)
        end
        if not preserveCarriedCorpse
            and Internal.clearCorpseHaulToken(carriedCorpse,
                assignment and assignment.haulToken or nil)
        then
            Internal.transmit(carriedCorpse)
        end
    end
    if assignment then
        if not preserveCarriedCorpse then
            clearCorpseTaskMarker(assignment.sourceX, assignment.sourceY,
                assignment.sourceZ, assignment.haulToken,
                assignment.deathMarkerId)
            clearCorpseTaskMarker(assignment.dropX, assignment.dropY,
                assignment.dropZ, assignment.haulToken,
                assignment.deathMarkerId)
        end
        Service.Runtime.byToken[assignment.haulToken] = nil
        Service.Runtime.byDrop[Internal.pointKey(assignment.dropX,
            assignment.dropY, assignment.dropZ)] = nil
    end
    if not preserveCarriedCorpse and order and order.payload then
        order.payload.carryX, order.payload.carryY, order.payload.carryZ = nil,
            nil, nil
    end
    Service.Runtime.byTask[taskId] = nil
    if record and record.runtime
        and tostring(record.runtime.corpseHaulTaskId or "") == taskId
    then
        record.runtime.corpseHaulTaskId = nil
    end
    if record and WorkSequence and WorkSequence.Reset then
        WorkSequence.Reset(record)
    end
end

Internal.resetLiveWorkState = resetLiveWorkState
Internal.clearWorkRuntime = clearWorkRuntime

return Service
