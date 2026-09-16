local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local Core = PNC.Core
local Const = PNC.Const

local MOVEMENT_STEP_STATES = {
    PENDING = true,
    RESOLVING = true,
    ASSIGNED = true,
    TRAVEL = true,
    ARRIVED = true,
}

local function tickDebugCycle(record, zombie, now)
    if PNC.AnimationSceneDebug and PNC.AnimationSceneDebug.Tick then
        return PNC.AnimationSceneDebug.Tick(record, zombie, now) == true
    end
    return false
end

local function currentOrIdleScene(record, zombie, now, debugCycleActive)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    if not scene and not debugCycleActive then
        local activity = record and record.runtime
            and record.runtime.facilityActivity or nil
        if activity and activity.sleepWakePending == true then
            return nil
        end
        Scenes.TryIdle(record, zombie, now)
        scene = record and record.runtime
            and record.runtime.animationScene or nil
        if not scene
            and PNC.PathService
            and PNC.PathService.RequestAmbientFacing
        then
            PNC.PathService.RequestAmbientFacing(record, zombie, "idle")
        end
    end
    return scene
end

local function validateLiveScene(record, zombie, scene, definition)
    if record.presenceState == Const.PRESENCE_LIVE and zombie then
        return true
    end
    if definition.interrupts.abstract ~= false then
        Internal.ClearScene(record, zombie, "abstracted", false)
    end
    return false
end

local function runTickCallback(
    definition,
    record,
    zombie,
    scene,
    now
)
    local ok
    local keepRunning
    if type(definition.onTick) ~= "function" then
        return true
    end
    ok, keepRunning = pcall(
        definition.onTick,
        record,
        zombie,
        scene,
        now
    )
    if not ok then
        if Core and Core.LogWarn then
            Core.LogWarn(
                "PNC animation scene tick callback failed: "
                    .. tostring(keepRunning)
            )
        end
        Internal.ClearScene(
            record,
            zombie,
            "tick_callback_failed",
            true
        )
        return false
    end
    if keepRunning == false then
        Internal.ClearScene(record, zombie, "callback_complete", true)
        return false
    end
    return true
end

local function advancePlayback(record, zombie, scene, definition, now)
    local started
    if scene.bump == nil then
        if now < (tonumber(scene.nextStepAt) or 0) then
            return true
        end
        started = Internal.ActivateStep(
            record,
            zombie,
            scene,
            definition,
            now
        )
        if not started then
            Internal.ClearScene(
                record,
                zombie,
                "step_start_failed",
                false
            )
            return false
        end
    elseif (tonumber(scene.finishAt) or 0) > 0
        and now >= tonumber(scene.finishAt)
    then
        return Internal.ScheduleNextStep(
            record,
            zombie,
            scene,
            definition,
            now
        )
    end
    return true
end

local function maintainLoop(record, zombie, scene, definition, now)
    if not scene.bump
        or not scene.loop
        or not PNC.Animation
        or not PNC.Animation.MaintainBump
    then
        return
    end
    PNC.Animation.MaintainBump(
        zombie,
        record,
        scene.bump,
        Internal.SceneLeaseUntil(scene, now),
        {
            sceneId = definition.id,
            sceneRevision = scene.revision,
            playbackRevision = scene.playbackRevision,
            keepManagedUseless = definition.keepManagedUseless == true
                and true or nil,
        }
    )
end

local function semanticMovementOwner(record, definition)
    local service
    local owner
    local plan
    local step
    if not definition or tostring(definition.id or "")
        ~= "social.conversation"
    then
        return false
    end
    service = PNC.Semantics
        and PNC.Semantics.ActionPlanService or nil
    if not service or type(service.GetExecutionOwner) ~= "function" then
        owner = nil
    else
        owner = service.GetExecutionOwner(record)
    end
    if owner and tostring(owner.action or "") == "MOVE_TO" then
        return owner
    end

    -- The authoritative service is server-only.  On a multiplayer client,
    -- use the replicated primitive plan snapshot as a visual handoff hint so
    -- a local conversation scene cannot keep reapplying Hold over movement.
    plan = record and record.semanticActionPlan or nil
    step = plan and plan.state == "RUNNING"
        and plan.steps and plan.steps[tonumber(plan.currentStep) or 0]
        or nil
    if step and tostring(step.action or "") == "MOVE_TO"
        and MOVEMENT_STEP_STATES[step.state]
    then
        return {
            planID = plan.planID,
            stepID = step.id,
            action = step.action,
            stepState = step.state,
        }
    end
    return false
end

local function auditSemanticMovementHandoff(
    record,
    scene,
    owner,
    now,
    event
)
    local diagnostics = PNC.Semantics
        and PNC.Semantics.SemanticDiagnostics or nil
    if not diagnostics
        or type(diagnostics.IsEnabled) ~= "function"
        or diagnostics.IsEnabled() ~= true
        or type(diagnostics.Record) ~= "function"
    then
        return
    end
    diagnostics.Record(event or "semantic.animation.handoff", {
        npcID = record and record.id,
        sceneID = scene and scene.id,
        sceneRevision = scene and scene.revision,
        planID = owner and owner.planID,
        stepID = owner and owner.stepID,
        action = owner and owner.action,
        stepState = owner and owner.stepState,
        at = now,
    }, { requestID = owner and owner.planID })
end

-- A conversation scene is a blocking presentation lease.  It must yield
-- while a semantic movement step owns the actor, otherwise its Hold call (and
-- its looping bump) cancels the path on every behavior tick.  Keep the
-- conversation lease itself alive; only suspend the visual playback lane.
local function suspendForSemanticMovement(record, zombie, scene, owner, now)
    if scene.semanticMovementHandoff ~= true then
        if scene.bump and PNC.Animation
            and type(PNC.Animation.FinishBump) == "function"
        then
            PNC.Animation.FinishBump(zombie, true)
        end
        scene.semanticMovementHandoff = true
        scene.bump = nil
        scene.loop = false
        scene.finishAt = 0
        scene.nextStepAt = now
        Internal.ClearLocalSceneKey(zombie)
        Internal.MarkSceneSync(record, "semantic_movement_handoff")
        auditSemanticMovementHandoff(
            record,
            scene,
            owner,
            now,
            "semantic.animation.movement_handoff"
        )
    end
    record.activeBehavior = "SemanticActionPlan:MOVE_TO"
    return false
end

local function resumeAfterSemanticMovement(scene, now)
    if scene.semanticMovementHandoff ~= true then return end
    scene.semanticMovementHandoff = nil
    scene.bump = nil
    scene.loop = false
    scene.finishAt = 0
    scene.nextStepAt = now
end

local function applyBlocking(record, definition)
    if not definition.blocking then
        return false
    end
    record.activeBehavior = "AnimationScene:" .. definition.id
    if PNC.BehaviorMoveIntent and PNC.BehaviorMoveIntent.Hold then
        PNC.BehaviorMoveIntent.Hold(
            record,
            "animation_scene:" .. definition.id
        )
    end
    return true
end

function Scenes.Tick(record, zombie, now)
    local scene
    local definition
    now = tonumber(now) or Core.Now()
    Scenes.InterruptForSafety(record, zombie, now)
    scene = currentOrIdleScene(
        record,
        zombie,
        now,
        tickDebugCycle(record, zombie, now)
    )
    if not scene then return false end
    definition = Scenes.Get(scene.id)
    if not definition then
        Internal.ClearScene(
            record,
            zombie,
            "definition_missing",
            true
        )
        return false
    end
    if not validateLiveScene(record, zombie, scene, definition) then
        return false
    end
    local movementOwner = semanticMovementOwner(record, definition)
    if movementOwner then
        return suspendForSemanticMovement(
            record,
            zombie,
            scene,
            movementOwner,
            now
        )
    end
    resumeAfterSemanticMovement(scene, now)
    if not runTickCallback(
        definition,
        record,
        zombie,
        scene,
        now
    ) or not advancePlayback(
        record,
        zombie,
        scene,
        definition,
        now
    ) then
        return false
    end
    maintainLoop(record, zombie, scene, definition, now)
    return applyBlocking(record, definition)
end
