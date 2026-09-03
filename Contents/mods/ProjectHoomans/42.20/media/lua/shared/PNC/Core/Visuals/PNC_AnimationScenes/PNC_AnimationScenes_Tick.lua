local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local Core = PNC.Core
local Const = PNC.Const

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
        }
    )
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
    if not validateLiveScene(record, zombie, scene, definition)
        or not runTickCallback(
            definition,
            record,
            zombie,
            scene,
            now
        )
        or not advancePlayback(
            record,
            zombie,
            scene,
            definition,
            now
        )
    then
        return false
    end
    maintainLoop(record, zombie, scene, definition, now)
    return applyBlocking(record, definition)
end
