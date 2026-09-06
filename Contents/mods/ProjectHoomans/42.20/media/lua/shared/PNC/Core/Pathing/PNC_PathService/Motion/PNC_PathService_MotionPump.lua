-- Motion provider: hot coordinator. Execution details live in sibling providers.

local PathService = PNC.PathService
local Internal = PathService.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function recordPumpDiagnostics(record, zombie, caller)
    if not Diagnostics then
        return
    end
    Diagnostics.RecordPathPump(record, caller or "scheduler_path_service")
    if record
        and record.presenceState == PNC.Const.PRESENCE_ABSTRACT
    then
        Diagnostics.Increment("LiveAbstract.AbstractPathRequests")
        if zombie then
            Diagnostics.Increment("LiveAbstract.AbstractPhysicalTraversal")
        end
    end
end

local function prepareLane(record, zombie, lane, now)
    if not lane.traversalAction
        and not lane.vanillaFenceAction
        and Internal.repairInvalidBodyPosition
    then
        local repaired = Internal.repairInvalidBodyPosition(
            record, zombie, lane, now
        )
        if repaired
            and lane.navigationProvider ~= "engine_path"
            and Internal.FakeLocomotion
            and Internal.FakeLocomotion.PrepareBody
        then
            Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
        end
    end
    if not lane.traversalAction and not lane.vanillaFenceAction then
        Internal.applyCombatFacing(zombie, lane, now, false)
    end
end

local function holdAttackLease(record, zombie, lane, now)
    -- A traversal bump is the movement owner. Its animation lease is not a
    -- combat lease; allowing this branch to win leaves the action permanently
    -- in "bumped" until its hard timeout.
    if lane
        and (lane.traversalAction ~= nil
            or lane.vanillaFenceAction ~= nil)
    then
        return nil
    end
    if not Internal.hasActiveAttack(record, now, zombie) then
        return nil
    end
    local navigation = record.runtime
        and record.runtime.localNavigation or nil
    local enginePlanner = PNC.EnginePathPlanner
    if navigation
        and navigation.nativeActive == true
        and enginePlanner
        and enginePlanner.Invalidate
    then
        enginePlanner.Invalidate(record, "combat_attack_lease", zombie)
    end
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    lane.ownerMode = "attack_lease"
    return true, "attack_active"
end

local function ownsScriptedPassage(zombie, lane)
    return lane.traversalAction ~= nil
        or lane.vanillaFenceAction ~= nil
        or lane.blockedStepToX ~= nil
        or (
            Internal.LiveBodyControl
            and Internal.LiveBodyControl.IsMultiplayer
            and not Internal.LiveBodyControl.IsMultiplayer()
            and (
                Internal.isDoorCollision
                and Internal.isDoorCollision(zombie)
            )
        )
end

local function singlePlayerNativeOwner(zombie, lane, navigation)
    local liveBodyControl = Internal.LiveBodyControl
    if not lane
        or lane.phase ~= "active"
        or lane.navigationProvider ~= "engine_path"
        or not navigation
        or navigation.provider ~= "engine_path"
        or navigation.nativeActive ~= true
        or not liveBodyControl
        or not liveBodyControl.IsMultiplayer
        or liveBodyControl.IsMultiplayer()
    then
        return false
    end
    -- A collision/traversal lane is deliberately handed back to PathService.
    -- The ordinary native lane is the one that must have a single callback
    -- owner in single-player.
    return not ownsScriptedPassage(zombie, lane)
end

local function hasUnconsumedIntent(runtime, lane)
    local intent = runtime and runtime.moveIntent or nil
    local revision = intent and tonumber(intent.revision) or nil
    if revision == nil or lane.intentRevision == nil then
        -- Older live records do not have an intent revision. Let one normal
        -- pump migrate them before the fast path becomes eligible.
        return true
    end
    return revision ~= tonumber(lane.intentRevision)
end

local function startRequestedLane(record, zombie, lane)
    local started, state = Internal.startRequestedMove(zombie, record, lane)
    if started
        and lane.navigationProvider == "engine_path"
        and PNC.EnginePathPlanner
        and PNC.EnginePathPlanner.GetSteeringTarget
    then
        PNC.EnginePathPlanner.GetSteeringTarget(record, zombie, lane.goal)
    end
    return started, state
end

local function updateActiveLane(record, zombie, lane, now, caller)
    local enginePlanner = PNC.EnginePathPlanner
    local navigation = record.runtime
        and record.runtime.localNavigation or nil
    if ownsScriptedPassage(zombie, lane) then
        return Internal.updateActiveMove(zombie, record, lane)
    end
    if lane.navigationProvider == "engine_path"
        and enginePlanner
        and enginePlanner.GetSteeringTarget
        and (not navigation or navigation.nativeActive ~= true)
    then
        enginePlanner.GetSteeringTarget(record, zombie, lane.goal)
    end
    navigation = record.runtime and record.runtime.localNavigation or nil
    if enginePlanner
        and enginePlanner.Pump
        and navigation
        and navigation.provider == "engine_path"
        and navigation.nativeActive == true
    then
        local handled, state = Internal.updateNativeMove(
            record,
            zombie,
            lane,
            navigation,
            enginePlanner,
            enginePlanner.Pump,
            now,
            caller or "path_service"
        )
        if handled then
            return handled, state
        end
    end
    if lane.navigationProvider == "engine_path" then
        lane.ownerMode = "engine_path_waiting"
        if now >= (tonumber(lane.visualMovingUntil) or 0) then
            Internal.applyHoldAnimation(zombie, record, lane)
        end
        return true, "native_waiting"
    end
    return Internal.updateActiveMove(zombie, record, lane)
end

function PathService.Pump(record, zombie, caller)
    local runtime = record and record.runtime or nil
    if not zombie or not runtime then
        recordPumpDiagnostics(record, zombie, caller)
        return false, "no_live_body"
    end
    local lane = Internal.ensureMoveLane(record)
    local now = Internal.Core.Now()
    local handled
    local state
    local navigation = record.runtime and record.runtime.localNavigation or nil
    local intentState
    -- In single-player the native Behavior2 route advances from
    -- OnZombieUpdate. Once the current behavior intent has been consumed,
    -- the scheduler has no movement work to perform for this lane. Holds and
    -- new targets still pass through immediately because they increment the
    -- intent revision.
    if singlePlayerNativeOwner(zombie, lane, navigation)
        and not hasUnconsumedIntent(runtime, lane)
    then
        return true, "native_waiting_for_zombie_update"
    end
    recordPumpDiagnostics(record, zombie, caller)
    handled, state = holdAttackLease(record, zombie, lane, now)
    if handled then
        return handled, state
    end
    -- Intent consumption remains on the scheduler boundary. It is cheap Lua
    -- state work, and skipping it would make a new follow target or hold
    -- request wait behind a native route forever.
    intentState = Internal.consumeMoveIntent(record, lane, zombie)
    if lane.phase == "cancel_pending" then
        Internal.finalizeCancel(zombie, record, lane)
        intentState = Internal.consumeMoveIntent(record, lane, zombie)
    end
    lane.intentRevision = runtime.moveIntent
        and (tonumber(runtime.moveIntent.revision) or 0)
        or 0
    if lane.phase == "requested" then
        prepareLane(record, zombie, lane, now)
        return startRequestedLane(record, zombie, lane)
    end
    -- In single-player, OnZombieUpdate owns the live Behavior2 route. Do not
    -- run the scheduler's repair, animation, or native-pump work for the same
    -- lane. Scripted passages still pass through below when the body is
    -- actually colliding or a traversal has already been staged.
    if lane.phase == "active"
        and singlePlayerNativeOwner(
            zombie,
            lane,
            record.runtime and record.runtime.localNavigation or navigation
        )
    then
        return true, "native_waiting_for_zombie_update"
    end
    prepareLane(record, zombie, lane, now)
    if lane.phase == "active" then
        return updateActiveLane(record, zombie, lane, now, caller)
    end
    if intentState == "arrived" then
        Internal.applyHoldAnimation(zombie, record, lane)
        return true, "arrived"
    end
    Internal.applyHoldAnimation(zombie, record, lane)
    return false, "idle"
end

-- EnginePathPlanner uses this boundary after staging an obstacle into the
-- scripted lane. It mirrors the ordinary pump preamble but cannot reacquire
-- the native engine, avoiding a re-entrant PathService/Planner pump cycle.
function PathService.AdvanceScriptedPassage(record, zombie, caller)
    recordPumpDiagnostics(record, zombie, caller)
    local runtime = record and record.runtime or nil
    if not zombie or not runtime then
        return false, "no_live_body"
    end
    local lane = Internal.ensureMoveLane(record)
    local now = Internal.Core.Now()
    prepareLane(record, zombie, lane, now)
    local handled, state = holdAttackLease(record, zombie, lane, now)
    if handled then
        return handled, state
    end
    local intentState = Internal.consumeMoveIntent(record, lane, zombie)
    if lane.phase == "cancel_pending" then
        Internal.finalizeCancel(zombie, record, lane)
        intentState = Internal.consumeMoveIntent(record, lane, zombie)
    end
    if lane.phase == "active" then
        return Internal.updateActiveMove(zombie, record, lane)
    end
    if intentState == "arrived" then
        Internal.applyHoldAnimation(zombie, record, lane)
        return true, "arrived"
    end
    Internal.applyHoldAnimation(zombie, record, lane)
    return true, "native_passage_waiting"
end
