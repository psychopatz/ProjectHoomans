-- Animation-scene request and blocking movement provider.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
PNC.AnimationScenes.Internal = PNC.AnimationScenes.Internal or {}

local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local Core = PNC.Core
local Const = PNC.Const
local Diagnostics = PNC.PerformanceScalingDiagnostics
local ActorControl = PNC.ActorControl
local isWaterScene = Internal.IsWaterScene
local activeTraversalOwner = Internal.ActiveTraversalOwner
local logWaterSceneEvent = Internal.LogWaterSceneEvent
local auditScene = Internal.AuditScene

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
    local allowed
    local ownerReason
    options = type(options) == "table" and options or {}
    if not record or not definition then
        return false, definition and "record_missing" or "scene_missing"
    end
    if ActorControl and ActorControl.CanWrite then
        allowed, ownerReason = ActorControl.CanWrite(
            record,
            options.owner,
            "animation_scene_request",
            { reason = options.reason or "animation_scene_request" }
        )
        if allowed == false then
            return false, ownerReason or "puppet_opera_owned"
        end
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
        and ((Diagnostics.IsSeatingSceneId
            and Diagnostics.IsSeatingSceneId(sceneId))
            or sceneId == "facility.living.sitFurniture"
            or sceneId == "facility.living.sit"
            or runtime.facilityActivity
                and runtime.facilityActivity.seating == true
            or runtime.roamingSeat
                and runtime.roamingSeat.seating == true)
    then
        if Diagnostics.LogSeatingState then
            Diagnostics.LogSeatingState(
                "scene_request",
                record,
                zombie,
                { id = sceneId },
                options.reason or "",
                {
                    "current=" .. tostring(runtime.animationScene
                        and runtime.animationScene.id or ""),
                }
            )
        else
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


return Scenes
