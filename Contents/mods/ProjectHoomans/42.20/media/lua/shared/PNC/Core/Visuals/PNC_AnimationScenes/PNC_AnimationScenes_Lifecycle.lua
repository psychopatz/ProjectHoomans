local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local Core = PNC.Core
local Const = PNC.Const

local function notifyStop(definition, record, zombie, scene, reason)
    local ok
    local errorValue
    if not definition or type(definition.onStop) ~= "function" then
        return
    end
    ok, errorValue = pcall(
        definition.onStop,
        record,
        zombie,
        scene,
        reason
    )
    if not ok and Core and Core.LogWarn then
        Core.LogWarn(
            "PNC animation scene stop callback failed: "
                .. tostring(errorValue)
        )
    end
end

function Internal.ClearScene(record, zombie, reason, release)
    local runtime
    local scene
    local definition
    if not record then return false end
    runtime = record.runtime or {}
    record.runtime = runtime
    scene = runtime.animationScene
    if not scene then return false end
    definition = Scenes.Get(scene.id)
    runtime.lastAnimationScene = {
        id = scene.id,
        revision = scene.revision,
        playbackRevision = scene.playbackRevision,
        stepId = scene.stepId,
        stepPosition = scene.stepPosition,
        stoppedAt = Core.Now(),
        reason = reason or "stopped",
    }
    runtime.animationScene = nil
    Internal.ClearLocalSceneKey(zombie)
    if release == true
        and zombie
        and PNC.Animation
        and PNC.Animation.FinishBump
    then
        PNC.Animation.FinishBump(zombie, true)
    end
    Internal.MarkSceneSync(record, "animation_scene_stop")
    notifyStop(definition, record, zombie, scene, reason or "stopped")
    return true
end

local function requestedRepeatMode(options, definition)
    local repeatMode = tostring(
        options.repeatMode or definition.repeatMode
    )
    if repeatMode ~= "loop" and repeatMode ~= "once" then
        return definition.repeatMode
    end
    return repeatMode
end

local function buildScene(runtime, definition, options, now)
    local revision = (tonumber(runtime.animationSceneRevision) or 0) + 1
    runtime.animationSceneRevision = revision
    return {
        id = definition.id,
        revision = revision,
        playbackRevision = 0,
        startedAt = now,
        finishAt = 0,
        loop = false,
        blocking = definition.blocking,
        priority = definition.priority,
        reason = options.reason,
        order = Internal.BuildStepOrder(definition),
        stepPosition = 1,
        sequenceIteration = 1,
        sequenceLength = #definition.steps,
        repeatMode = requestedRepeatMode(options, definition),
        durationOverride = options.durationMs
            and math.max(0, tonumber(options.durationMs) or 0)
            or nil,
    }
end

local function canReplaceCurrent(runtime, definition, options)
    local current = runtime.animationScene
    local currentDefinition
    if not current then return true end
    currentDefinition = Scenes.Get(current.id)
    return not currentDefinition
        or currentDefinition.priority <= definition.priority
        or options.force == true
end

function Scenes.Request(record, zombie, sceneId, options)
    local definition = Scenes.Get(sceneId)
    local runtime
    local scene
    local now
    local started
    local result
    options = type(options) == "table" and options or {}
    if not record or not definition then
        return false, definition and "record_missing" or "scene_missing"
    end
    if record.presenceState ~= Const.PRESENCE_LIVE or not zombie then
        return false, "live_body_required"
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    if not canReplaceCurrent(runtime, definition, options) then
        return false, "lower_priority"
    end
    if runtime.animationScene then
        Internal.ClearScene(record, zombie, "scene_replaced", false)
    end
    now = tonumber(options.now) or Core.Now()
    scene = buildScene(runtime, definition, options, now)
    runtime.animationScene = scene
    if definition.blocking
        and PNC.BehaviorMoveIntent
        and PNC.BehaviorMoveIntent.Hold
    then
        PNC.BehaviorMoveIntent.Hold(
            record,
            "animation_scene:" .. definition.id
        )
    end
    started, result = Internal.ActivateStep(
        record,
        zombie,
        scene,
        definition,
        now
    )
    if not started then
        runtime.animationScene = nil
        return false, result
    end
    Internal.MarkSceneSync(record, "animation_scene_start")
    return true, scene
end

function Scenes.Stop(record, zombie, reason)
    return Internal.ClearScene(
        record,
        zombie,
        reason or "scene_stopped",
        true
    )
end

function Scenes.RequestFromPool(record, zombie, poolName, options)
    local sceneId
    options = type(options) == "table" and options or {}
    poolName = tostring(poolName or "")
    if poolName == "" or not Scenes.Pools[poolName] then
        return false, "pool_missing"
    end
    sceneId = Internal.ChoosePoolScene(
        poolName,
        options.excludeSceneId
            and tostring(options.excludeSceneId) or nil
    )
    if not sceneId then
        return false, "pool_empty"
    end
    return Scenes.Request(record, zombie, sceneId, options)
end

function Scenes.Interrupt(record, zombie, reason)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    local definition = scene and Scenes.Get(scene.id) or nil
    local interruptKey = tostring(reason or "externalBump")
    if not scene or not definition then return false end
    if definition.interrupts[interruptKey] == false then
        return false
    end
    return Internal.ClearScene(
        record,
        zombie,
        "interrupted:" .. interruptKey,
        true
    )
end

function Scenes.OnExternalBump(record, zombie, bumpType)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    local definition = scene and Scenes.Get(scene.id) or nil
    if not scene or not definition then return false end
    if tostring(scene.bump or "") == tostring(bumpType or "")
        or "PNC_" .. tostring(scene.bump or "") == tostring(bumpType or "")
    then
        return false
    end
    if definition.interrupts.externalBump == false then
        return false
    end
    return Internal.ClearScene(
        record,
        zombie,
        "interrupted:externalBump",
        false
    )
end

function Scenes.StartSurrender(record, zombie, options)
    return Scenes.Request(record, zombie, "social.surrender", options)
end

function Scenes.StopSurrender(record, zombie, reason)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    if not scene or scene.id ~= "social.surrender" then
        return false
    end
    return Scenes.Stop(record, zombie, reason or "surrender_released")
end
