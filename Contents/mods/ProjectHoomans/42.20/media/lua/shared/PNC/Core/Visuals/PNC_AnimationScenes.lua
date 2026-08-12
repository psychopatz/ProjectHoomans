--[[
    PNC animation scenes

    Registry and authority arbiter for optional animation sequences. Behaviors
    request stable scene IDs; the scene owns bump playback and replication
    until it completes or an allowed interruption occurs.

    A definition may provide one legacy `bump`, or `steps` containing
    { id, bump, durationMs, loop }. `sequenceMode = "shuffle"` randomizes one
    pass. `repeatMode = "once"` completes after one pass; `"loop"` queues
    another pass. Each primitive gets a new playbackRevision so replicas
    replay it without changing the scene ID.
]]

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}

local Scenes = PNC.AnimationScenes
local Core = PNC.Core
local Const = PNC.Const

Scenes.Definitions = Scenes.Definitions or {}
Scenes.Pools = Scenes.Pools or {}

local DEFAULT_IDLE_MIN_MS = 8000
local DEFAULT_IDLE_JITTER_MS = 12000
local PERSISTENT_LEASE_MS = 10000
local MIN_STEP_GAP_MS = 100

local function copyInterrupts(source)
    source = type(source) == "table" and source or {}
    return {
        movement = source.movement ~= false,
        combat = source.combat ~= false,
        externalBump = source.externalBump ~= false,
        abstract = source.abstract ~= false,
    }
end

local function normalizeSteps(definition)
    local source = type(definition.steps) == "table"
        and definition.steps or nil
    local steps = {}
    local raw
    local bump
    local i
    if not source or #source <= 0 then
        source = {
            {
                id = definition.stepId,
                bump = definition.bump,
                durationMs = definition.durationMs,
                loop = definition.loop,
            },
        }
    end
    for i = 1, #source do
        raw = type(source[i]) == "table"
            and source[i] or { bump = source[i] }
        bump = tostring(raw.bump or "")
        if bump == "" then
            return nil, "missing_step_bump"
        end
        steps[#steps + 1] = {
            id = tostring(
                raw.id or raw.key or ("step_" .. tostring(i))
            ),
            bump = bump,
            durationMs = math.max(
                0,
                tonumber(raw.durationMs)
                    or tonumber(definition.durationMs)
                    or 0
            ),
            loop = raw.loop == true,
        }
    end
    return steps
end

local function poolEntry(poolName, sceneId)
    local pool = Scenes.Pools[poolName]
    local i
    for i = 1, #(pool or {}) do
        if pool[i].id == sceneId then
            return pool[i]
        end
    end
    return nil
end

local function removeFromPools(sceneId)
    local pool
    local i
    local poolName
    for poolName, pool in pairs(Scenes.Pools) do
        for i = #pool, 1, -1 do
            if pool[i].id == sceneId then
                table.remove(pool, i)
            end
        end
        if #pool <= 0 then
            Scenes.Pools[poolName] = nil
        end
    end
end

local function markSceneSync(record, eventName)
    if not record then return end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent =
        eventName or "animation_scene"
end

local function sceneLeaseUntil(scene, now)
    if scene.loop == true
        and (tonumber(scene.finishAt) or 0) <= 0
    then
        return now + PERSISTENT_LEASE_MS
    end
    return tonumber(scene.finishAt) or (
        now + PERSISTENT_LEASE_MS
    )
end

local function clearLocalSceneKey(zombie)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    if modData then
        modData.PNC_ClientAnimationSceneKey = nil
    end
end

local function clearScene(record, zombie, reason, release)
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
    clearLocalSceneKey(zombie)
    if release == true
        and zombie
        and PNC.Animation
        and PNC.Animation.FinishBump
    then
        PNC.Animation.FinishBump(zombie, true)
    end
    markSceneSync(record, "animation_scene_stop")
    if definition and type(definition.onStop) == "function" then
        local ok, errorValue = pcall(
            definition.onStop, record, zombie, scene,
            reason or "stopped")
        if not ok and Core and Core.LogWarn then
            Core.LogWarn("PNC animation scene stop callback failed: "
                .. tostring(errorValue))
        end
    end
    return true
end

local function nextRandom(limit)
    limit = math.max(1, math.floor(tonumber(limit) or 1))
    if ZombRand then
        return ZombRand(limit)
    end
    return math.random(0, limit - 1)
end

local function buildStepOrder(definition, previousStepIndex)
    local order = {}
    local i
    local swapIndex
    for i = 1, #definition.steps do
        order[i] = i
    end
    if definition.sequenceMode == "shuffle" then
        for i = #order, 2, -1 do
            swapIndex = nextRandom(i) + 1
            order[i], order[swapIndex] =
                order[swapIndex], order[i]
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

local function stepGap(definition)
    local gap = math.max(
        0,
        tonumber(definition.stepGapMs) or 0
    )
    local jitter = math.max(
        0,
        tonumber(definition.stepGapJitterMs) or 0
    )
    if gap > 0 or jitter > 0 then
        gap = math.max(MIN_STEP_GAP_MS, gap)
    end
    return gap + nextRandom(jitter + 1)
end

local function markStepKey(zombie, scene)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    if modData then
        modData.PNC_ClientAnimationSceneKey =
            tostring(scene.id)
                .. ":" .. tostring(scene.revision)
                .. ":" .. tostring(scene.playbackRevision)
    end
end

local function activateStep(record, zombie, scene, definition, now)
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
        PNC.Animation.PlayBump(
            zombie,
            record,
            step.bump,
            {
                sceneId = definition.id,
                sceneRevision = scene.revision,
                playbackRevision = scene.playbackRevision,
                leaseUntil = sceneLeaseUntil(
                    scene,
                    now
                ),
            }
        )
    end
    markStepKey(zombie, scene)
    markSceneSync(record, "animation_scene_step")
    return true, step
end

local function scheduleNextStep(
    record,
    zombie,
    scene,
    definition,
    now
)
    local completedStepIndex = scene.stepIndex
    if scene.bump
        and PNC.Animation
        and PNC.Animation.FinishBump
    then
        PNC.Animation.FinishBump(zombie, true)
    end
    scene.bump = nil
    scene.loop = false
    scene.finishAt = 0
    clearLocalSceneKey(zombie)
    scene.stepPosition = (tonumber(scene.stepPosition) or 1) + 1
    if scene.stepPosition > #scene.order then
        if scene.repeatMode ~= "loop" then
            clearScene(record, zombie, "completed", false)
            return false
        end
        scene.order = buildStepOrder(
            definition,
            completedStepIndex
        )
        scene.stepPosition = 1
        scene.sequenceIteration =
            (tonumber(scene.sequenceIteration) or 1) + 1
    end
    scene.nextStepAt = now + stepGap(definition)
    markSceneSync(record, "animation_scene_step_gap")
    return true
end

local function scheduleNextIdle(record, now, shortRetry)
    local runtime = record.runtime or {}
    local minimum = shortRetry == true and 1000
        or tonumber(Const.ANIMATION_IDLE_SCENE_MIN_MS)
        or DEFAULT_IDLE_MIN_MS
    local jitter = shortRetry == true and 1500
        or tonumber(Const.ANIMATION_IDLE_SCENE_JITTER_MS)
        or DEFAULT_IDLE_JITTER_MS
    record.runtime = runtime
    runtime.nextIdleAnimationSceneAt = now
        + minimum
        + nextRandom(jitter + 1)
end

local function isIdleEligible(record, zombie, now)
    local runtime = record and record.runtime or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    local followState = runtime and runtime.followState or nil
    local treatment = runtime and runtime.selfTreatment or nil
    if not record or not zombie
        or record.alive == false
        or record.presenceState ~= Const.PRESENCE_LIVE
        or record.health
            and tostring(record.health.state or "normal") ~= "normal"
        or runtime and runtime.target ~= nil
        or runtime and runtime.attackAction ~= nil
        or runtime
            and now < (tonumber(runtime.inCombatUntil) or 0)
        or record.health
            and now < (
                tonumber(record.health.recentDamageUntil) or 0
            )
        or followState and followState.ownerMoving == true
        or treatment and treatment.phase == "bandaging"
    then
        return false
    end
    if path and (
        path.phase == "requested"
        or path.phase == "active"
        or now < (tonumber(path.visualMovingUntil) or 0)
        or now < (tonumber(path.specialMoveUntil) or 0)
    ) then
        return false
    end
    if navigation and (
        navigation.nativeActive == true
        or navigation.nativeTraversalState ~= nil
    ) then
        return false
    end
    return true
end

local function choosePoolScene(poolName, excludedSceneId)
    local pool = Scenes.Pools[poolName]
    local total = 0
    local roll
    local i
    for i = 1, #(pool or {}) do
        if pool[i].id ~= excludedSceneId or #pool <= 1 then
            total = total + math.max(
                0,
                tonumber(pool[i].weight) or 0
            )
        end
    end
    if total <= 0 then return nil end
    roll = nextRandom(total)
    for i = 1, #pool do
        if pool[i].id ~= excludedSceneId or #pool <= 1 then
            roll = roll - math.max(
                0,
                tonumber(pool[i].weight) or 0
            )
            if roll < 0 then
                return pool[i].id
            end
        end
    end
    return pool[#pool] and pool[#pool].id or nil
end

function Scenes.Register(sceneId, definition)
    local normalized
    local poolName
    local entry
    local steps
    local stepError
    local repeatMode
    sceneId = tostring(sceneId or "")
    if sceneId == "" or type(definition) ~= "table" then
        return false, "invalid_scene"
    end
    steps, stepError = normalizeSteps(definition)
    if not steps then return false, stepError end
    repeatMode = tostring(
        definition.repeatMode
            or definition.playbackMode
            or ""
    )
    if repeatMode ~= "loop" and repeatMode ~= "once" then
        repeatMode = (
            definition.sequenceLoop == true
                or (
                    definition.loop == true
                    and #steps == 1
                )
        ) and "loop" or "once"
    end
    if repeatMode == "loop"
        and #steps == 1
        and steps[1].durationMs <= 0
    then
        -- A persistent single-primitive scene needs its selector lease
        -- maintained. `repeatMode = "loop"` is sufficient; callers do not
        -- also need to know the lower-level bump-loop flag.
        steps[1].loop = true
    end
    normalized = {
        id = sceneId,
        bump = steps[1].bump,
        steps = steps,
        durationMs = math.max(
            0,
            tonumber(definition.durationMs) or 0
        ),
        priority = tonumber(definition.priority) or 10,
        loop = steps[1].loop == true,
        blocking = definition.blocking == true,
        pool = definition.pool
            and tostring(definition.pool) or nil,
        category = tostring(
            definition.category
                or string.match(sceneId, "^([^%.]+)")
                or "other"
        ),
        label = tostring(definition.label or sceneId),
        description = tostring(definition.description or ""),
        weight = math.max(
            0,
            tonumber(definition.weight) or 1
        ),
        sequenceMode = definition.sequenceMode == "shuffle"
            and "shuffle" or "ordered",
        repeatMode = repeatMode,
        sequenceLoop = repeatMode == "loop",
        stepGapMs = math.max(
            0,
            tonumber(definition.stepGapMs) or 0
        ),
        stepGapJitterMs = math.max(
            0,
            tonumber(definition.stepGapJitterMs) or 0
        ),
        interrupts = copyInterrupts(definition.interrupts),
        onTick = type(definition.onTick) == "function"
            and definition.onTick or nil,
        onStop = type(definition.onStop) == "function"
            and definition.onStop or nil,
    }
    removeFromPools(sceneId)
    Scenes.Definitions[sceneId] = normalized
    poolName = normalized.pool
    if poolName and poolName ~= "" and normalized.weight > 0 then
        Scenes.Pools[poolName] =
            Scenes.Pools[poolName] or {}
        entry = poolEntry(poolName, sceneId)
        if entry then
            entry.weight = normalized.weight
        else
            Scenes.Pools[poolName][
                #Scenes.Pools[poolName] + 1
            ] = {
                id = sceneId,
                weight = normalized.weight,
            }
        end
    end
    return true, normalized
end

function Scenes.Unregister(sceneId)
    sceneId = tostring(sceneId or "")
    if not Scenes.Definitions[sceneId] then
        return false
    end
    Scenes.Definitions[sceneId] = nil
    removeFromPools(sceneId)
    return true
end

function Scenes.Get(sceneId)
    return Scenes.Definitions[tostring(sceneId or "")]
end

function Scenes.List()
    local entries = {}
    local sceneId
    local definition
    for sceneId, definition in pairs(Scenes.Definitions) do
        entries[#entries + 1] = definition
    end
    table.sort(entries, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return entries
end

function Scenes.ListPools()
    local names = {}
    local poolName
    for poolName in pairs(Scenes.Pools) do
        names[#names + 1] = poolName
    end
    table.sort(names)
    return names
end

function Scenes.ChoosePoolScene(poolName, excludedSceneId)
    return choosePoolScene(
        tostring(poolName or ""),
        excludedSceneId and tostring(excludedSceneId) or nil
    )
end

function Scenes.Request(record, zombie, sceneId, options)
    local definition = Scenes.Get(sceneId)
    local runtime
    local current
    local now
    local revision
    local scene
    local started
    local result
    local requestedRepeatMode
    options = type(options) == "table" and options or {}
    if not record or not definition then
        return false, definition and "record_missing"
            or "scene_missing"
    end
    if record.presenceState ~= Const.PRESENCE_LIVE
        or not zombie
    then
        return false, "live_body_required"
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    current = runtime.animationScene
    if current then
        local currentDefinition = Scenes.Get(current.id)
        if currentDefinition
            and currentDefinition.priority > definition.priority
            and options.force ~= true
        then
            return false, "lower_priority"
        end
        clearScene(record, zombie, "scene_replaced", false)
    end
    now = tonumber(options.now) or Core.Now()
    requestedRepeatMode = tostring(
        options.repeatMode or definition.repeatMode
    )
    if requestedRepeatMode ~= "loop"
        and requestedRepeatMode ~= "once"
    then
        requestedRepeatMode = definition.repeatMode
    end
    revision = (tonumber(runtime.animationSceneRevision) or 0)
        + 1
    runtime.animationSceneRevision = revision
    scene = {
        id = definition.id,
        revision = revision,
        playbackRevision = 0,
        startedAt = now,
        finishAt = 0,
        loop = false,
        blocking = definition.blocking,
        priority = definition.priority,
        reason = options.reason,
        order = buildStepOrder(definition),
        stepPosition = 1,
        sequenceIteration = 1,
        sequenceLength = #definition.steps,
        repeatMode = requestedRepeatMode,
        durationOverride = options.durationMs
            and math.max(0, tonumber(options.durationMs) or 0)
            or nil,
    }
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
    started, result = activateStep(
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
    markSceneSync(record, "animation_scene_start")
    return true, scene
end

function Scenes.Stop(record, zombie, reason)
    return clearScene(
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
    sceneId = choosePoolScene(
        poolName,
        options.excludeSceneId
            and tostring(options.excludeSceneId) or nil
    )
    if not sceneId then
        return false, "pool_empty"
    end
    return Scenes.Request(
        record,
        zombie,
        sceneId,
        options
    )
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
    return clearScene(
        record,
        zombie,
        "interrupted:" .. interruptKey,
        true
    )
end

function Scenes.InterruptForSafety(record, zombie, now)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    local followState = runtime and runtime.followState or nil
    local health = record and record.health or nil
    now = tonumber(now) or Core.Now()
    if not scene then return false end
    if runtime.target ~= nil
        or runtime.attackAction ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
        or now < (tonumber(health and health.recentDamageUntil) or 0)
    then
        return Scenes.Interrupt(record, zombie, "combat")
    end
    if path and (
            path.phase == "requested"
            or path.phase == "active"
            or now < (tonumber(path.visualMovingUntil) or 0)
            or now < (tonumber(path.specialMoveUntil) or 0)
        )
        or navigation and (
            navigation.nativeActive == true
            or navigation.nativeTraversalState ~= nil
        )
        or followState and followState.ownerMoving == true
    then
        return Scenes.Interrupt(record, zombie, "movement")
    end
    return false
end

function Scenes.OnExternalBump(record, zombie, bumpType)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    local definition = scene and Scenes.Get(scene.id) or nil
    if not scene or not definition then return false end
    if tostring(scene.bump or "") == tostring(bumpType or "")
        or "PNC_" .. tostring(scene.bump or "")
            == tostring(bumpType or "")
    then
        return false
    end
    if definition.interrupts.externalBump == false then
        return false
    end
    -- The incoming bump immediately replaces the selector, so do not emit a
    -- completion latch for the old scene between the two selectors.
    return clearScene(
        record,
        zombie,
        "interrupted:externalBump",
        false
    )
end

function Scenes.TryIdle(record, zombie, now)
    local runtime
    local sceneId
    if not record
        or record.presenceState ~= Const.PRESENCE_LIVE
        or not zombie
        or not Scenes.Pools.idle
        or #Scenes.Pools.idle <= 0
    then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    if runtime.animationScene then return false end
    if runtime.nextIdleAnimationSceneAt == nil then
        -- The first ambient scene should be observable without waiting up to
        -- twenty seconds. Later retries keep the normal sparse cadence.
        scheduleNextIdle(record, now, true)
        return false
    end
    if now < (
        tonumber(runtime.nextIdleAnimationSceneAt) or 0
    ) then
        return false
    end
    if not isIdleEligible(record, zombie, now) then
        scheduleNextIdle(record, now, true)
        return false
    end
    sceneId = choosePoolScene("idle")
    scheduleNextIdle(record, now, false)
    if not sceneId then return false end
    return Scenes.Request(
        record,
        zombie,
        sceneId,
        {
            now = now,
            reason = "idle_injection",
        }
    )
end

function Scenes.Tick(record, zombie, now)
    local scene
    local definition
    local debugCycleActive = false
    now = tonumber(now) or Core.Now()
    Scenes.InterruptForSafety(record, zombie, now)
    if PNC.AnimationSceneDebug
        and PNC.AnimationSceneDebug.Tick
    then
        debugCycleActive =
            PNC.AnimationSceneDebug.Tick(
                record,
                zombie,
                now
            ) == true
    end
    scene = record and record.runtime
        and record.runtime.animationScene or nil
    if not scene and not debugCycleActive then
        Scenes.TryIdle(record, zombie, now)
        scene = record and record.runtime
            and record.runtime.animationScene or nil
    end
    if not scene then return false end
    definition = Scenes.Get(scene.id)
    if not definition then
        clearScene(record, zombie, "definition_missing", true)
        return false
    end
    if record.presenceState ~= Const.PRESENCE_LIVE
        or not zombie
    then
        if definition.interrupts.abstract ~= false then
            clearScene(record, zombie, "abstracted", false)
        end
        return false
    end
    if type(definition.onTick) == "function" then
        local ok, keepRunning = pcall(
            definition.onTick, record, zombie, scene, now)
        if not ok then
            if Core and Core.LogWarn then
                Core.LogWarn("PNC animation scene tick callback failed: "
                    .. tostring(keepRunning))
            end
            clearScene(record, zombie, "tick_callback_failed", true)
            return false
        end
        if keepRunning == false then
            clearScene(record, zombie, "callback_complete", true)
            return false
        end
    end
    if scene.bump == nil then
        if now >= (tonumber(scene.nextStepAt) or 0) then
            local started = activateStep(
                record,
                zombie,
                scene,
                definition,
                now
            )
            if not started then
                clearScene(
                    record,
                    zombie,
                    "step_start_failed",
                    false
                )
                return false
            end
        end
    elseif (tonumber(scene.finishAt) or 0) > 0
        and now >= tonumber(scene.finishAt)
    then
        if not scheduleNextStep(
            record,
            zombie,
            scene,
            definition,
            now
        ) then
            return false
        end
    end
    if scene.bump and scene.loop
        and PNC.Animation
        and PNC.Animation.MaintainBump
    then
        PNC.Animation.MaintainBump(
            zombie,
            record,
            scene.bump,
            sceneLeaseUntil(scene, now),
            {
                sceneId = definition.id,
                sceneRevision = scene.revision,
                playbackRevision = scene.playbackRevision,
            }
        )
    end
    if definition.blocking then
        record.activeBehavior =
            "AnimationScene:" .. definition.id
        if PNC.BehaviorMoveIntent
            and PNC.BehaviorMoveIntent.Hold
        then
            PNC.BehaviorMoveIntent.Hold(
                record,
                "animation_scene:" .. definition.id
            )
        end
        return true
    end
    return false
end

function Scenes.StartSurrender(record, zombie, options)
    return Scenes.Request(
        record,
        zombie,
        "social.surrender",
        options
    )
end

function Scenes.StopSurrender(record, zombie, reason)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    if not scene or scene.id ~= "social.surrender" then
        return false
    end
    return Scenes.Stop(
        record,
        zombie,
        reason or "surrender_released"
    )
end

return Scenes
