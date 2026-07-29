--[[
    PNC animation scenes

    Registry and authority arbiter for optional animation sequences. Behaviors
    request stable scene IDs; the scene owns bump playback and replication
    until it completes or an allowed interruption occurs.
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

local function copyInterrupts(source)
    source = type(source) == "table" and source or {}
    return {
        movement = source.movement ~= false,
        combat = source.combat ~= false,
        externalBump = source.externalBump ~= false,
        abstract = source.abstract ~= false,
    }
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

local function sceneLeaseUntil(scene, definition, now)
    if definition.loop == true
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
    if not record then return false end
    runtime = record.runtime or {}
    record.runtime = runtime
    scene = runtime.animationScene
    if not scene then return false end
    runtime.lastAnimationScene = {
        id = scene.id,
        revision = scene.revision,
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
    return true
end

local function nextRandom(limit)
    limit = math.max(1, math.floor(tonumber(limit) or 1))
    if ZombRand then
        return ZombRand(limit)
    end
    return math.random(0, limit - 1)
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
    local treatment = runtime and runtime.selfTreatment or nil
    if not record or not zombie
        or record.alive == false
        or record.presenceState ~= Const.PRESENCE_LIVE
        or record.health
            and tostring(record.health.state or "normal") ~= "normal"
        or runtime and runtime.target ~= nil
        or runtime and runtime.attackAction ~= nil
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
    sceneId = tostring(sceneId or "")
    if sceneId == "" or type(definition) ~= "table" then
        return false, "invalid_scene"
    end
    if tostring(definition.bump or "") == "" then
        return false, "missing_bump"
    end
    normalized = {
        id = sceneId,
        bump = tostring(definition.bump),
        durationMs = math.max(
            0,
            tonumber(definition.durationMs) or 0
        ),
        priority = tonumber(definition.priority) or 10,
        loop = definition.loop == true,
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
        interrupts = copyInterrupts(definition.interrupts),
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
    local durationMs
    local revision
    local scene
    local modData
    local sceneKey
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
    durationMs = math.max(
        0,
        tonumber(options.durationMs)
            or definition.durationMs
    )
    revision = (tonumber(runtime.animationSceneRevision) or 0)
        + 1
    runtime.animationSceneRevision = revision
    scene = {
        id = definition.id,
        bump = definition.bump,
        revision = revision,
        startedAt = now,
        finishAt = durationMs > 0 and now + durationMs or 0,
        loop = definition.loop,
        blocking = definition.blocking,
        priority = definition.priority,
        reason = options.reason,
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
    if PNC.Animation and PNC.Animation.PlayBump then
        PNC.Animation.PlayBump(
            zombie,
            record,
            definition.bump,
            {
                sceneId = definition.id,
                sceneRevision = revision,
                leaseUntil = sceneLeaseUntil(
                    scene,
                    definition,
                    now
                ),
            }
        )
    end
    sceneKey = definition.id .. ":" .. tostring(revision)
    modData = zombie.getModData
        and zombie:getModData() or nil
    if modData then
        modData.PNC_ClientAnimationSceneKey = sceneKey
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
        scheduleNextIdle(record, now, false)
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
    if (tonumber(scene.finishAt) or 0) > 0
        and now >= tonumber(scene.finishAt)
    then
        clearScene(record, zombie, "completed", true)
        return false
    end
    if definition.loop
        and PNC.Animation
        and PNC.Animation.MaintainBump
    then
        PNC.Animation.MaintainBump(
            zombie,
            record,
            definition.bump,
            sceneLeaseUntil(scene, definition, now),
            {
                sceneId = definition.id,
                sceneRevision = scene.revision,
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
