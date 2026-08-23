local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal

local PERSISTENT_LEASE_MS = 10000
local MIN_STEP_GAP_MS = 100

function Internal.MarkSceneSync(record, eventName)
    if not record then return end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = eventName or "animation_scene"
end

function Internal.SceneLeaseUntil(scene, now)
    if scene.loop == true and (tonumber(scene.finishAt) or 0) <= 0 then
        return now + PERSISTENT_LEASE_MS
    end
    return tonumber(scene.finishAt) or (now + PERSISTENT_LEASE_MS)
end

function Internal.ClearLocalSceneKey(zombie)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    if modData then
        modData.PNC_ClientAnimationSceneKey = nil
    end
end

function Internal.NextRandom(limit)
    limit = math.max(1, math.floor(tonumber(limit) or 1))
    if ZombRand then
        return ZombRand(limit)
    end
    return math.random(0, limit - 1)
end

function Internal.BuildStepOrder(definition, previousStepIndex)
    local order = {}
    local i
    local swapIndex
    for i = 1, #definition.steps do
        order[i] = i
    end
    if definition.sequenceMode == "shuffle" then
        for i = #order, 2, -1 do
            swapIndex = Internal.NextRandom(i) + 1
            order[i], order[swapIndex] = order[swapIndex], order[i]
        end
        if #order > 1
            and previousStepIndex ~= nil
            and order[1] == previousStepIndex
        then
            order[1], order[2] = order[2], order[1]
        end
    end
    return order
end

function Internal.StepGap(definition)
    local gap = math.max(0, tonumber(definition.stepGapMs) or 0)
    local jitter = math.max(
        0,
        tonumber(definition.stepGapJitterMs) or 0
    )
    if gap > 0 or jitter > 0 then
        gap = math.max(MIN_STEP_GAP_MS, gap)
    end
    return gap + Internal.NextRandom(jitter + 1)
end

function Internal.MarkStepKey(zombie, scene)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    if modData then
        modData.PNC_ClientAnimationSceneKey =
            tostring(scene.id)
                .. ":" .. tostring(scene.revision)
                .. ":" .. tostring(scene.playbackRevision)
    end
end

function Internal.ActivateStep(record, zombie, scene, definition, now)
    local stepIndex = scene.order[scene.stepPosition]
    local step = stepIndex and definition.steps[stepIndex] or nil
    local durationMs
    if not step then return false, "scene_step_missing" end
    durationMs = step.durationMs
    if scene.durationOverride ~= nil and #definition.steps == 1 then
        durationMs = scene.durationOverride
    end
    scene.stepIndex = stepIndex
    scene.stepId = step.id
    scene.bump = step.bump
    scene.loop = step.loop == true
    scene.stepStartedAt = now
    scene.finishAt = durationMs > 0 and now + durationMs or 0
    scene.nextStepAt = nil
    scene.playbackRevision =
        (tonumber(scene.playbackRevision) or 0) + 1
    if PNC.Animation and PNC.Animation.PlayBump then
        PNC.Animation.PlayBump(zombie, record, step.bump, {
            sceneId = definition.id,
            sceneRevision = scene.revision,
            playbackRevision = scene.playbackRevision,
            leaseUntil = Internal.SceneLeaseUntil(scene, now),
        })
    end
    Internal.MarkStepKey(zombie, scene)
    Internal.MarkSceneSync(record, "animation_scene_step")
    return true, step
end

local function advanceSequence(scene, definition, completedStepIndex)
    scene.stepPosition = (tonumber(scene.stepPosition) or 1) + 1
    if scene.stepPosition <= #scene.order then
        return true
    end
    if scene.repeatMode ~= "loop" then
        return false
    end
    scene.order = Internal.BuildStepOrder(definition, completedStepIndex)
    scene.stepPosition = 1
    scene.sequenceIteration =
        (tonumber(scene.sequenceIteration) or 1) + 1
    return true
end

function Internal.ScheduleNextStep(
    record,
    zombie,
    scene,
    definition,
    now
)
    local completedStepIndex = scene.stepIndex
    if scene.bump and PNC.Animation and PNC.Animation.FinishBump then
        PNC.Animation.FinishBump(zombie, true)
    end
    scene.bump = nil
    scene.loop = false
    scene.finishAt = 0
    Internal.ClearLocalSceneKey(zombie)
    if not advanceSequence(scene, definition, completedStepIndex) then
        Internal.ClearScene(record, zombie, "completed", false)
        return false
    end
    scene.nextStepAt = now + Internal.StepGap(definition)
    Internal.MarkSceneSync(record, "animation_scene_step_gap")
    return true
end
