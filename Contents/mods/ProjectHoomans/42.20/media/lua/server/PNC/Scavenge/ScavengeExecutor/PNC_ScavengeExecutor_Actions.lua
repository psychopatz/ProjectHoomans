if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Executor = PNC.ScavengeExecutor
local Internal = Executor.Internal
local Service = PNC.ScavengeService
local Common = PNC.BehaviorCommon
local approachKey = Internal.ApproachKey
local approachLocation = Internal.ApproachLocation
local withinInteractionRadius = Internal.WithinInteractionRadius
local laneBlocked = Internal.LaneBlocked
local resetPath = Internal.ResetPath
local setWorkerPhase = Internal.SetWorkerPhase
local teamCanClaim = Internal.TeamCanClaim
local clearWorkerAction = Internal.ClearWorkerAction

local function failWorkerSource(session, worker, reason)
    local source = worker.currentSource
    if worker.currentKind == "loot" and worker.currentEntry then
        local entry = worker.currentEntry
        entry.failedWorkers = entry.failedWorkers or {}
        entry.failedWorkers[worker.npcId] = true
        entry.assignedNpcId = nil
        if not teamCanClaim(session, entry) then
            entry.status = "AVAILABLE"
            if entry.reservationToken then
                WorldLoot.ReleaseReservation(entry.reservationToken,
                    "no_team_capacity")
                entry.reservationToken = nil
            end
        end
    elseif source then
        session.processedCount = session.processedCount + 1
        session.unreachableCount = session.unreachableCount + 1
        session.searchClaims[source.sourceToken] = nil
        Service.Internal.Increment("UnreachableSources")
    end
    Service.Internal.Activity(session, "SOURCE_SKIPPED", {
        entryId = source and source.sourceToken,
        sourceType = source and source.sourceType,
        sourceLabel = source and (source.sourceLabel or source.label),
    }, {
        npcId = worker.npcId,
        reason = reason,
        sourceLabel = source and (source.sourceLabel or source.label),
    })
    worker.lastFailure = tostring(reason or "source_failed")
    worker.lastFailureAt = PNC.Core.Now()
    clearWorkerAction(worker)
    Service.Internal.Touch(session, "SourceSkipped", {
        sourceToken = source and source.sourceToken,
        npcId = worker.npcId, reason = reason,
    }, true)
end

local function retryWorkerApproach(session, worker, record, body,
    source, approach, reason)
    local excluded = worker.failedApproaches[source.sourceToken] or {}
    worker.failedApproaches[source.sourceToken] = excluded
    excluded[approachKey(approach)] = true
    local cacheKey = tostring(source.sourceToken) .. "\31"
        .. tostring(record.id or "npc")
    session.approachBySource[cacheKey] = nil
    worker.approachFailures = (tonumber(worker.approachFailures) or 0) + 1
    if tostring(reason or ""):find("native_", 1, true) == 1 then
        -- Native zombie pathing can stop updating outside the player's active
        -- simulation bubble.  Keep the normal route first, then use the
        -- collision-aware local mover as a bounded recovery for this source.
        worker.useDirectRecovery = true
    end
    resetPath(record, body, "scavenge_retry_interaction_tile")
    if worker.approachFailures < 4 then return nil, "approach_retry" end
    return false, reason or "path_blocked"
end

local function arriveWorker(session, worker, record, body)
    local source = worker.currentSource
    if not source or not WorldLoot.IsSourceValid(source.sourceToken) then
        return false, "source_invalid"
    end
    local location, reason = WorldLoot.GetSourceLocation(source.sourceToken)
    if not location then return false, reason or "source_location_unavailable" end
    if withinInteractionRadius(record, body, location, source.sourceType) then
        resetPath(record, body, "scavenge_interaction_radius")
        worker.approachFailures = nil
        worker.useDirectRecovery = nil
        return true
    end
    worker.failedApproaches = worker.failedApproaches or {}
    local excluded = worker.failedApproaches[source.sourceToken]
    local approach
    approach, reason = approachLocation(
        session, source, location, record, excluded)
    if not approach then return false, reason end
    local blocked, blockReason = laneBlocked(record)
    if blocked then
        return retryWorkerApproach(session, worker, record, body,
            source, approach, blockReason)
    end
    setWorkerPhase(session, worker,
        worker.currentKind == "loot" and "TRAVELING_TO_LOOT_SOURCE"
            or "TRAVELING_TO_SEARCH_SOURCE", "TRAVEL")
    local stopDistance = source.sourceType == "container" and 0.8 or 0.65
    local ok, movement = Common.MoveRecord(record, body,
        approach.x, approach.y, approach.z, "walk", stopDistance,
        worker.currentKind == "loot" and "scavenge_loot"
            or "scavenge_search", worker.useDirectRecovery and {
                navigationPolicy = "direct",
            } or nil)
    worker.lastMovement = tostring(movement or (ok and "requested" or "failed"))
    worker.lastMovementAt = PNC.Core.Now()
    if not ok then
        local failure = tostring(movement or "path_request_failed")
        if failure == "native_progress_timeout"
            or failure == "native_path_unreachable"
            or failure == "native_no_goal_progress"
        then
            return retryWorkerApproach(session, worker, record, body,
                source, approach, failure)
        end
        return false, failure
    end
    if movement == "arrived" then
        resetPath(record, body, "scavenge_arrived")
        worker.approachFailures = nil
        worker.useDirectRecovery = nil
        return true
    end
    return nil, movement
end

Internal.FailWorkerSource = failWorkerSource
Internal.RetryWorkerApproach = retryWorkerApproach
Internal.ArriveWorker = arriveWorker

return Executor
