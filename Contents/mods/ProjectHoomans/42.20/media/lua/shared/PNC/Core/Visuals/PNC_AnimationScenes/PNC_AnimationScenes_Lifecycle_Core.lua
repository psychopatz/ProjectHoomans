-- Animation-scene lifecycle shared helpers and scene clearing.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
PNC.AnimationScenes.Internal = PNC.AnimationScenes.Internal or {}

local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local Core = PNC.Core
local Const = PNC.Const
local Diagnostics = PNC.PerformanceScalingDiagnostics
local LiveBodyControl = PNC.LiveBodyControl
local ActorControl = PNC.ActorControl

local function isWaterScene(sceneId)
    local id = tostring(sceneId or "")
    return string.find(id, "survival.drink.", 1, true) == 1
        or string.find(id, "survival.fill.", 1, true) == 1
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
    local roaming = runtime and runtime.roamingSeat or nil
    return scene and (
        Diagnostics and Diagnostics.IsSeatingSceneId
            and Diagnostics.IsSeatingSceneId(scene.id)
        or scene.id == "facility.living.sitFurniture"
        or scene.id == "facility.living.sit"
        or scene.id == "ambient.roam.sitFurniture"
        or activity and activity.seating == true
        or roaming and roaming.seating == true
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
    if Diagnostics.LogSeatingState then
        Diagnostics.LogSeatingState(
            eventName,
            record,
            zombie,
            scene,
            reason,
            {
                "step=" .. tostring(scene and scene.stepId or ""),
                "release=" .. tostring(release == true),
            }
        )
    else
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

function Internal.ClearScene(record, zombie, reason, release, options)
    local runtime
    local scene
    local definition
    local preserveOwner = type(options) == "table"
        and options.preserveOwner == true
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
        preservedOwner = preserveOwner,
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
    if not preserveOwner then
        notifyStop(definition, record, zombie, scene, reason or "stopped")
    end
    return true
end


Internal.IsWaterScene = isWaterScene
Internal.ActiveTraversalOwner = activeTraversalOwner
Internal.LogWaterSceneEvent = logWaterSceneEvent
Internal.IsSeatingScene = isSeatingScene
Internal.AuditScene = auditScene
Internal.NotifyStop = notifyStop

return Scenes
