--[[
    Authority-owned animation scene test controller.

    The UI only requests actions. This controller drives the canonical record
    and live body, so the same scene is replicated in single-player and
    multiplayer. Pool cycling is registry-driven and therefore automatically
    supports scene packs registered by other mods.
]]

PNC = PNC or {}
PNC.AnimationSceneDebug = PNC.AnimationSceneDebug or {}

local Debug = PNC.AnimationSceneDebug
local Core = PNC.Core
local Const = PNC.Const
local Scenes = PNC.AnimationScenes

local DEFAULT_GAP_MS = 750
local MIN_GAP_MS = 100
local MAX_GAP_MS = 30000

local function markSync(record, eventName)
    if not record then return end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent =
        eventName or "animation_scene_debug"
end

local function normalizeGap(value)
    return math.max(
        MIN_GAP_MS,
        math.min(
            MAX_GAP_MS,
            math.floor(tonumber(value) or DEFAULT_GAP_MS)
        )
    )
end

local function stateFor(record)
    return record and record.runtime
        and record.runtime.animationSceneDebug or nil
end

function Debug.BuildSnapshot(record)
    local state = stateFor(record)
    if not state then
        return {
            active = false,
            mode = "manual",
        }
    end
    return {
        active = state.active == true,
        mode = tostring(state.mode or "manual"),
        pool = state.pool,
        gapMs = tonumber(state.gapMs) or DEFAULT_GAP_MS,
        nextAt = tonumber(state.nextAt) or 0,
        lastSceneId = state.lastSceneId,
        completedCount = tonumber(state.completedCount) or 0,
        lastError = state.lastError,
    }
end

function Debug.Play(record, zombie, sceneId, options)
    local state
    local started
    local result
    if not record then return false, "record_missing" end
    record.runtime = record.runtime or {}
    state = {
        active = false,
        mode = "manual",
        lastSceneId = tostring(sceneId or ""),
        completedCount = 0,
    }
    record.runtime.animationSceneDebug = state
    options = type(options) == "table" and options or {}
    options.force = true
    options.reason = options.reason or "debug_scene_play"
    started, result = Scenes.Request(
        record,
        zombie,
        sceneId,
        options
    )
    if started then
        state.lastSceneId = result.id
    else
        state.lastError = tostring(
            result or "scene_start_failed"
        )
    end
    markSync(record, "animation_scene_debug_play")
    return started, result
end

function Debug.PlayPoolOnce(record, zombie, poolName, options)
    local state
    local started
    local result
    if not record then return false, "record_missing" end
    record.runtime = record.runtime or {}
    local previous = record.runtime.animationScene
        and record.runtime.animationScene.id or nil
    state = {
        active = false,
        mode = "pool_step",
        pool = tostring(poolName or ""),
        completedCount = 0,
    }
    record.runtime.animationSceneDebug = state
    options = type(options) == "table" and options or {}
    options.force = true
    options.reason = options.reason
        or "debug_scene_pool_step"
    options.excludeSceneId =
        options.excludeSceneId or previous
    started, result = Scenes.RequestFromPool(
        record,
        zombie,
        poolName,
        options
    )
    if started then
        state.lastSceneId = result.id
    else
        state.lastError = tostring(
            result or "scene_start_failed"
        )
    end
    markSync(record, "animation_scene_debug_step")
    return started, result
end

function Debug.StartPoolCycle(
    record,
    zombie,
    poolName,
    options
)
    local now
    local state
    poolName = tostring(poolName or "")
    options = type(options) == "table" and options or {}
    if not record then return false, "record_missing" end
    if not Scenes.Pools[poolName] then
        return false, "pool_missing"
    end
    if not zombie then return false, "live_body_required" end
    now = tonumber(options.now) or Core.Now()
    record.runtime = record.runtime or {}
    if record.runtime.animationScene then
        Scenes.Stop(
            record,
            zombie,
            "debug_pool_cycle_started"
        )
    end
    state = {
        active = true,
        mode = "pool_cycle",
        pool = poolName,
        gapMs = normalizeGap(options.gapMs),
        nextAt = now,
        lastSceneId = nil,
        observedRevision = nil,
        completedCount = 0,
        lastError = nil,
    }
    record.runtime.animationSceneDebug = state
    markSync(record, "animation_scene_debug_cycle_start")
    Debug.Tick(record, zombie, now)
    return true, state
end

function Debug.Stop(record, zombie, reason)
    local hadDebug
    local hadScene
    if not record then return false, "record_missing" end
    record.runtime = record.runtime or {}
    hadDebug = record.runtime.animationSceneDebug ~= nil
    record.runtime.animationSceneDebug = nil
    hadScene = record.runtime.animationScene ~= nil
    if hadScene then
        Scenes.Stop(
            record,
            zombie,
            reason or "debug_scene_stop"
        )
    end
    markSync(record, "animation_scene_debug_stop")
    return hadDebug or hadScene, hadDebug
        and "cycle_stopped" or "scene_stopped"
end

function Debug.Tick(record, zombie, now)
    local state = stateFor(record)
    local scene
    local started
    local result
    if not state or state.active ~= true
        or state.mode ~= "pool_cycle"
    then
        return false
    end
    now = tonumber(now) or Core.Now()
    if not zombie
        or record.presenceState ~= Const.PRESENCE_LIVE
    then
        state.lastError = "live_body_required"
        return true
    end
    scene = record.runtime.animationScene
    if scene then
        state.observedRevision = scene.revision
        state.lastSceneId = scene.id
        state.lastError = nil
        return true
    end
    if state.observedRevision ~= nil then
        state.observedRevision = nil
        state.completedCount =
            (tonumber(state.completedCount) or 0) + 1
        state.nextAt = now
            + normalizeGap(state.gapMs)
        markSync(record, "animation_scene_debug_cycle_gap")
        return true
    end
    if now < (tonumber(state.nextAt) or 0) then
        return true
    end
    started, result = Scenes.RequestFromPool(
        record,
        zombie,
        state.pool,
        {
            now = now,
            force = true,
            reason = "debug_scene_pool_cycle",
            excludeSceneId = state.lastSceneId,
        }
    )
    if started then
        state.observedRevision = result.revision
        state.lastSceneId = result.id
        state.lastError = nil
    else
        state.lastError = tostring(result or "scene_start_failed")
        state.nextAt = now + 1000
    end
    markSync(record, "animation_scene_debug_cycle_tick")
    return true
end

return Debug
