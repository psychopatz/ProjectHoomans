-- Reusable live work interaction sequencing.
--
-- The sequence owns only movement-safe presentation phases. The operation
-- service remains responsible for validating and committing world state.

PNC = PNC or {}
PNC.WorkSequence = PNC.WorkSequence or {}

local Sequence = PNC.WorkSequence
local Definitions = Sequence.Definitions or {}
Sequence.Definitions = Definitions

local function actionFor(order)
    local definition = order and Definitions[order.operation] or nil
    local actions = definition and definition.actions or nil
    return actions and actions[tostring(order.phase or "")] or nil
end

local function runtimeFor(record)
    record.runtime = record.runtime or {}
    return record.runtime
end

function Sequence.Register(operation, definition)
    operation = tostring(operation or "")
    if operation == "" or type(definition) ~= "table"
        or type(definition.actions) ~= "table"
    then
        return false
    end
    Definitions[operation] = definition
    return true
end

function Sequence.GetState(record)
    return record and record.runtime and record.runtime.workSequence or nil
end

function Sequence.Reset(record)
    if record and record.runtime then
        record.runtime.workSequence = nil
    end
end

function Sequence.Status(record, order)
    local action = actionFor(order)
    local state = Sequence.GetState(record)
    if not action then return "none" end
    if not state or state.phase ~= tostring(order.phase or "")
        or state.sceneId ~= tostring(action.sceneId or "")
    then
        return "pending"
    end
    if state.failed then return "failed" end
    if state.completed == true then return "completed" end
    return state.startedAt and state.startedAt > 0 and "running" or "pending"
end

function Sequence.Tick(record, zombie, order)
    local action = actionFor(order)
    local runtime
    local state
    local scene
    local last
    local now
    local ok
    local result
    if not action or not record then return false end

    runtime = runtimeFor(record)
    now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    state = runtime.workSequence
    if not state or state.phase ~= tostring(order.phase or "")
        or state.sceneId ~= tostring(action.sceneId or "")
    then
        state = {
            phase = tostring(order.phase or ""),
            sceneId = tostring(action.sceneId or ""),
            startedAt = 0,
            completed = false,
        }
        runtime.workSequence = state
    end

    record.activeJob = PNC.WorkDefinitions
        and PNC.WorkDefinitions.JOB_BY_OPERATION[order.operation]
        or "ProductionWork"
    record.activeBehavior = "WorkSequence:" .. state.phase
    if PNC.BehaviorCommon then
        if PNC.BehaviorCommon.ClearCombatTarget then
            PNC.BehaviorCommon.ClearCombatTarget(
                record, "work_sequence", zombie)
        end
        if PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(
                record, zombie, "work_sequence:" .. state.phase)
        end
    end
    if zombie and zombie.faceLocationF and order.x and order.y then
        zombie:faceLocationF(order.x, order.y - 1)
    end

    if state.failed or state.completed then return true end
    scene = runtime.animationScene
    if scene and scene.id == state.sceneId then return true end
    last = runtime.lastAnimationScene
    if state.startedAt > 0 and last
        and last.id == state.sceneId
        and tonumber(last.revision) == tonumber(state.sceneRevision)
        and last.reason == "completed"
    then
        state.completed = true
        runtime.forceSyncEvent = "work_sequence_complete"
        return true
    end
    if not zombie or not PNC.AnimationScenes
        or not PNC.AnimationScenes.Request
    then
        state.failed = "LIVE_BODY_REQUIRED"
        state.startedAt = now
        return true
    end

    ok, result = PNC.AnimationScenes.Request(record, zombie, state.sceneId, {
        reason = action.reason or "work_sequence",
        repeatMode = "once",
        durationMs = tonumber(action.durationMs),
        now = now,
    })
    if not ok then
        state.failed = tostring(result or "WORK_SCENE_REQUEST_FAILED")
        state.startedAt = now
        return true
    end
    state.startedAt = now
    state.sceneRevision = result and result.revision or nil
    return true
end

return Sequence
