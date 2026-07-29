PNC = PNC or {}
PNC.AnimationSceneDebugModel =
    PNC.AnimationSceneDebugModel or {}

local Model = PNC.AnimationSceneDebugModel

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function sceneSearchText(scene)
    local values = {}
    local step
    local function append(value)
        if value ~= nil and tostring(value) ~= "" then
            values[#values + 1] = tostring(value)
        end
    end
    append(scene.id)
    append(scene.label)
    append(scene.description)
    append(scene.category)
    append(scene.pool)
    append(scene.bump)
    for _, step in ipairs(scene.steps or {}) do
        append(step.id)
        append(step.bump)
    end
    return lower(table.concat(values, " "))
end

function Model.GetGroups()
    local pools = {}
    local categories = {}
    local groups = {
        {
            key = "all",
            label = "All scenes",
            kind = "all",
        },
    }
    local scene
    for _, scene in ipairs(
        PNC.AnimationScenes.List()
    ) do
        if scene.pool and scene.pool ~= "" then
            pools[scene.pool] = true
        end
        categories[scene.category or "other"] = true
    end
    local names = {}
    local name
    for name in pairs(pools) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, poolName in ipairs(names) do
        groups[#groups + 1] = {
            key = "pool:" .. poolName,
            label = "Pool: " .. poolName,
            kind = "pool",
            value = poolName,
        }
    end
    names = {}
    for name in pairs(categories) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, categoryName in ipairs(names) do
        groups[#groups + 1] = {
            key = "category:" .. categoryName,
            label = "Category: " .. categoryName,
            kind = "category",
            value = categoryName,
        }
    end
    return groups
end

function Model.GetScenes(query, group)
    local results = {}
    query = lower(query)
    group = group or { kind = "all" }
    for _, scene in ipairs(
        PNC.AnimationScenes.List()
    ) do
        local groupMatches = group.kind == "all"
            or group.kind == "pool"
                and scene.pool == group.value
            or group.kind == "category"
                and scene.category == group.value
        if groupMatches
            and (
                query == ""
                or string.find(
                    sceneSearchText(scene),
                    query,
                    1,
                    true
                )
            )
        then
            results[#results + 1] = scene
        end
    end
    return results
end

function Model.GetSnapshot(npcId, fallback)
    local state = PNC.Network
        and PNC.Network.ClientState or nil
    local snapshot = state
        and state.snapshots
        and state.snapshots[tostring(npcId or "")]
        or nil
    return snapshot or fallback
end

function Model.GetRuntime(npcId, fallback)
    local snapshot = Model.GetSnapshot(npcId, fallback)
    local visual = snapshot and snapshot.visualState or {}
    local replicatedDebug = visual.sceneDebug or {}
    local runtime = fallback
        and fallback.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local debugState = runtime
        and runtime.animationSceneDebug or nil
    return {
        sceneActive = visual.sceneActive == true
            or scene ~= nil,
        sceneId = visual.sceneId
            or scene and scene.id,
        sceneBump = visual.sceneBump
            or scene and scene.bump,
        sceneRevision = visual.sceneRevision
            or scene and scene.revision
            or 0,
        scenePlaybackRevision = visual.scenePlaybackRevision
            or scene and scene.playbackRevision
            or 0,
        sceneStartedAt = visual.sceneStartedAt
            or scene and scene.startedAt
            or 0,
        sceneStepStartedAt = visual.sceneStepStartedAt
            or scene and scene.stepStartedAt
            or 0,
        sceneFinishAt = visual.sceneFinishAt
            or scene and scene.finishAt
            or 0,
        sceneNextStepAt = visual.sceneNextStepAt
            or scene and scene.nextStepAt
            or 0,
        sceneStepId = visual.sceneStepId
            or scene and scene.stepId,
        sceneStepPosition = visual.sceneStepPosition
            or scene and scene.stepPosition
            or 0,
        sceneStepCount = visual.sceneStepCount
            or scene and scene.sequenceLength
            or 0,
        sceneSequenceIteration = visual.sceneSequenceIteration
            or scene and scene.sequenceIteration
            or 0,
        sceneRepeatMode = visual.sceneRepeatMode
            or scene and scene.repeatMode
            or "once",
        sceneLoop = visual.sceneLoop == true
            or scene and scene.loop == true
            or false,
        sceneBlocking = visual.sceneBlocking == true
            or scene and scene.blocking == true
            or false,
        cycleActive = replicatedDebug.active == true
            or debugState and debugState.active == true
            or false,
        debugMode = replicatedDebug.mode
            or debugState and debugState.mode
            or "inactive",
        cyclePool = replicatedDebug.pool
            or debugState and debugState.pool,
        cycleGapMs = replicatedDebug.gapMs
            or debugState and debugState.gapMs
            or 0,
        cycleNextAt = replicatedDebug.nextAt
            or debugState and debugState.nextAt
            or 0,
        cycleLastSceneId =
            replicatedDebug.lastSceneId
            or debugState and debugState.lastSceneId,
        cycleCompletedCount =
            replicatedDebug.completedCount
            or debugState and debugState.completedCount
            or 0,
        cycleLastError =
            replicatedDebug.lastError
            or debugState and debugState.lastError,
    }
end

-- Read only methods exposed directly by IsoGameCharacter. ActionContext is
-- Java userdata in Build 42.19; probing methods on that nested object can look
-- valid to Kahlua and still fail when invoked.
function Model.GetBodyRuntime(body)
    local trackTime = body
        and body.dbgGetAnimTrackTime
        and tonumber(body:dbgGetAnimTrackTime(0, 0))
        or nil
    local bumpType = body
        and body.getBumpType
        and tostring(body:getBumpType() or "")
        or body
            and body.getVariableString
            and tostring(
                body:getVariableString("BumpType") or ""
            )
        or ""
    return {
        bumpType = bumpType,
        actionState = body
            and body.getCurrentActionContextStateName
            and tostring(
                body:getCurrentActionContextStateName() or ""
            )
            or "",
        previousActionState = body
            and body.getPreviousActionContextStateName
            and tostring(
                body:getPreviousActionContextStateName() or ""
            )
            or "",
        animationState = body
            and body.getAnimationStateName
            and tostring(
                body:getAnimationStateName() or ""
            )
            or "",
        track = body
            and body.dbgGetAnimTrackName
            and tostring(
                body:dbgGetAnimTrackName(0, 0) or ""
            )
            or "",
        trackTime = trackTime,
        trackFrame = trackTime
            and math.max(
                0,
                math.floor(trackTime * 30 + 0.0001)
            )
            or nil,
    }
end

return Model
