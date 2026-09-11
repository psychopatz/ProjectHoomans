local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local Core = PNC.Core
local Const = PNC.Const
local Diagnostics = PNC.PerformanceScalingDiagnostics
local LiveBodyControl = PNC.LiveBodyControl

local function isWaterScene(sceneId)
    return string.find(
        tostring(sceneId or ""),
        "facility.water.",
        1,
        true
    ) == 1
end

local function activeTraversalOwner(record, zombie, now)
    local runtime = record and record.runtime or nil
    local lane = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    local nativeState
    local nativeAction
    local modData
    local requested
    local leaseUntil
    local leaseActive
    if lane and lane.traversalAction then
        return true, lane.traversalAction.kind or "traversal"
    end
    if lane and lane.vanillaFenceAction then
        return true, "fence_climb_vanilla"
    end
    if navigation and navigation.nativeTraversalState ~= nil then
        return true, "native_" .. tostring(navigation.nativeTraversalState)
    end
    -- MP native passage state is deliberately kept in the client controller,
    -- not in runtime.localNavigation. Check it before a blocking scene resets
    -- the shared movement lane out from underneath the passage owner.
    nativeState = PNC.ClientPresenceSync
        and PNC.ClientPresenceSync.NativePathStateByBody
        and PNC.ClientPresenceSync.NativePathStateByBody[zombie]
        or nil
    nativeAction = nativeState and nativeState.passageAction or nil
    if nativeAction then
        return true, nativeAction.kind or "native_passage"
    end
    modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    requested = modData and tostring(
        modData.PNC_BumpRequestedType or ""
    ) or ""
    leaseActive = modData
        and (modData.PNC_BumpActionLease == true
            or modData.PNC_BumpReleasePending == true)
    leaseUntil = modData and tonumber(modData.PNC_BumpActionLeaseUntil)
    if leaseActive and leaseUntil and now > leaseUntil
        and modData.PNC_BumpReleasePending ~= true
    then
        leaseActive = false
    end
    if leaseActive
        and LiveBodyControl
        and LiveBodyControl.IsTraversalBumpType
        and LiveBodyControl.IsTraversalBumpType(requested)
    then
        return true, requested
    end
    return false, nil
end

local function logWaterSceneEvent(record, zombie, eventName, sceneId,
    stepId, bump, reason, traversalKind)
    local actionState
    if not isWaterScene(sceneId) or not Core or not Core.LogInfo then
        return
    end
    actionState = zombie and zombie.getActionStateName
        and zombie:getActionStateName() or ""
    Core.LogInfo(
        "[PNC][ANIM] " .. tostring(eventName)
            .. " npc=" .. tostring(record and record.id or "nil")
            .. " scene=" .. tostring(sceneId or "")
            .. " step=" .. tostring(stepId or "")
            .. " bump=" .. tostring(bump or "")
            .. " action=" .. tostring(actionState)
            .. " traversal=" .. tostring(traversalKind or "none")
            .. " reason=" .. tostring(reason or "")
    )
end

local function isSeatingScene(runtime, scene)
    local activity = runtime and runtime.facilityActivity or nil
    return scene and (
        scene.id == "facility.living.sitFurniture"
        or activity and activity.seating == true
    )
end

local function auditScene(
    record,
    runtime,
    scene,
    eventName,
    reason,
    release,
    zombie
)
    if not Diagnostics or Diagnostics.SeatingAuditEnabled ~= true
        or not Diagnostics.LogSeatingAudit
        or not isSeatingScene(runtime, scene)
    then
        return
    end
    Diagnostics.LogSeatingAudit(eventName, {
        "npc=" .. tostring(record and record.id or ""),
        "scene=" .. tostring(scene and scene.id or ""),
        "revision=" .. tostring(scene and scene.revision or ""),
        "step=" .. tostring(scene and scene.stepId or ""),
        "reason=" .. tostring(reason or ""),
        "release=" .. tostring(release == true),
        "pathPhase=" .. tostring(runtime and runtime.pathing
            and runtime.pathing.phase or ""),
        "nativeActive=" .. tostring(runtime and runtime.localNavigation
            and runtime.localNavigation.nativeActive == true),
        "bodyAction=" .. tostring(zombie and zombie.getActionStateName
            and zombie:getActionStateName() or ""),
    })
end

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
    logWaterSceneEvent(
        record,
        zombie,
        "scene_stop",
        scene.id,
        scene.stepId,
        scene.bump,
        reason or "stopped"
    )
    if Diagnostics and Diagnostics.SeatingAuditEnabled == true then
        auditScene(
            record,
            runtime,
            scene,
            "scene_stop",
            reason or "stopped",
            release,
            zombie
        )
    end
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

local function quiesceBlockingMovement(record, zombie, runtime, sceneId)
    local pathService = PNC.PathService
    local reason = "animation_scene:" .. tostring(sceneId)
    local reset

    if pathService and pathService.Commands
        and pathService.Commands.Reset
    then
        reset = pathService.Commands.Reset
        reset(record, zombie, reason)
    elseif pathService and pathService.Reset then
        pathService.Reset(zombie, record, reason)
    else
        -- Keep the scene safe even when the path module has not been loaded
        -- yet. The normal runtime takes the reset boundary above.
        runtime.pathing = nil
        runtime.localNavigation = nil
        runtime.moveIntent = nil
    end

    -- Follow state can outlive the movement lane. Do not let a sampled owner
    -- movement flag from before the interaction immediately cancel the newly
    -- acquired blocking scene on the next behavior tick.
    if runtime.followState then
        runtime.followState.ownerMoving = false
    end

    if PNC.BehaviorMoveIntent
        and PNC.BehaviorMoveIntent.Hold
    then
        PNC.BehaviorMoveIntent.Hold(record, reason)
    else
        runtime.moveIntent = {
            kind = "hold",
            reason = reason,
            updatedAt = Core.Now(),
        }
    end
end

function Scenes.Request(record, zombie, sceneId, options)
    local definition = Scenes.Get(sceneId)
    local runtime
    local scene
    local now
    local started
    local result
    local traversalActive
    local traversalKind
    options = type(options) == "table" and options or {}
    if not record or not definition then
        return false, definition and "record_missing" or "scene_missing"
    end
    if record.presenceState ~= Const.PRESENCE_LIVE or not zombie then
        return false, "live_body_required"
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    now = tonumber(options.now) or Core.Now()
    traversalActive, traversalKind = activeTraversalOwner(
        record,
        zombie,
        now
    )
    if traversalActive and options.allowDuringTraversal ~= true then
        -- A drink is a blocking scene. Starting it here used to clear the
        -- shared path lane and then overwrite the traversal BumpType while
        -- the client passage controller still owned its window/fence action.
        -- Keep the request pending; the facility behavior will retry after
        -- the bounded passage completes.
        if isWaterScene(sceneId) then
            local lastDeferredAt = tonumber(
                runtime.lastWaterSceneDeferredAt
            ) or 0
            if now - lastDeferredAt >= 1000 then
                runtime.lastWaterSceneDeferredAt = now
                logWaterSceneEvent(
                    record,
                    zombie,
                    "scene_deferred",
                    sceneId,
                    nil,
                    "Drink",
                    "traversal_active",
                    traversalKind
                )
            end
        end
        return false, "traversal_active"
    end
    if Diagnostics and Diagnostics.SeatingAuditEnabled == true
        and (sceneId == "facility.living.sitFurniture"
            or runtime.facilityActivity
                and runtime.facilityActivity.seating == true)
    then
        Diagnostics.LogSeatingAudit("scene_request", {
            "npc=" .. tostring(record.id or ""),
            "scene=" .. tostring(sceneId or ""),
            "reason=" .. tostring(options.reason or ""),
            "current=" .. tostring(runtime.animationScene
                and runtime.animationScene.id or ""),
            "pathPhase=" .. tostring(runtime.pathing
                and runtime.pathing.phase or ""),
            "nativeActive=" .. tostring(runtime.localNavigation
                and runtime.localNavigation.nativeActive == true),
        })
    end
    if not canReplaceCurrent(runtime, definition, options) then
        return false, "lower_priority"
    end
    if runtime.animationScene then
        Internal.ClearScene(record, zombie, "scene_replaced", false)
    end
    if definition.blocking then
        quiesceBlockingMovement(record, zombie, runtime, definition.id)
    end
    scene = buildScene(runtime, definition, options, now)
    runtime.animationScene = scene
    started, result = Internal.ActivateStep(
        record,
        zombie,
        scene,
        definition,
        now
    )
    if not started then
        runtime.animationScene = nil
        if Diagnostics and Diagnostics.SeatingAuditEnabled == true then
            Diagnostics.LogSeatingAudit("scene_start_failed", {
                "npc=" .. tostring(record.id or ""),
                "scene=" .. tostring(sceneId or ""),
                "reason=" .. tostring(result or "unknown"),
            })
        end
        return false, result
    end
    logWaterSceneEvent(
        record,
        zombie,
        "scene_started",
        scene.id,
        scene.stepId,
        scene.bump,
        options.reason
    )
    Internal.MarkSceneSync(record, "animation_scene_start")
    if Diagnostics and Diagnostics.SeatingAuditEnabled == true then
        auditScene(
            record,
            runtime,
            scene,
            "scene_started",
            options.reason,
            false,
            zombie
        )
    end
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
