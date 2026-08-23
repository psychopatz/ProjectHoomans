local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local Const = PNC.Const

local DEFAULT_IDLE_MIN_MS = 8000
local DEFAULT_IDLE_JITTER_MS = 12000

function Internal.ScheduleNextIdle(record, now, shortRetry)
    local runtime = record.runtime or {}
    local minimum = shortRetry == true and 1000
        or tonumber(Const.ANIMATION_IDLE_SCENE_MIN_MS)
        or DEFAULT_IDLE_MIN_MS
    local jitter = shortRetry == true and 1500
        or tonumber(Const.ANIMATION_IDLE_SCENE_JITTER_MS)
        or DEFAULT_IDLE_JITTER_MS
    record.runtime = runtime
    runtime.nextIdleAnimationSceneAt =
        now + minimum + Internal.NextRandom(jitter + 1)
end

function Internal.IsIdleEligible(record, zombie, now)
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
        or runtime and now < (tonumber(runtime.inCombatUntil) or 0)
        or record.health
            and now < (tonumber(record.health.recentDamageUntil) or 0)
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

local function idlePrerequisites(record, zombie)
    return record
        and record.presenceState == Const.PRESENCE_LIVE
        and zombie ~= nil
        and Scenes.Pools.idle ~= nil
        and #Scenes.Pools.idle > 0
        and not (
            record.orderSpec
                and record.orderSpec.kind == "facility_activity"
        )
end

function Scenes.TryIdle(record, zombie, now)
    local runtime
    local sceneId
    if not idlePrerequisites(record, zombie) then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    if runtime.animationScene then return false end
    if runtime.nextIdleAnimationSceneAt == nil then
        Internal.ScheduleNextIdle(record, now, true)
        return false
    end
    if now < (tonumber(runtime.nextIdleAnimationSceneAt) or 0) then
        return false
    end
    if not Internal.IsIdleEligible(record, zombie, now) then
        Internal.ScheduleNextIdle(record, now, true)
        return false
    end
    sceneId = Internal.ChoosePoolScene("idle")
    Internal.ScheduleNextIdle(record, now, false)
    if not sceneId then return false end
    return Scenes.Request(record, zombie, sceneId, {
        now = now,
        reason = "idle_injection",
    })
end
