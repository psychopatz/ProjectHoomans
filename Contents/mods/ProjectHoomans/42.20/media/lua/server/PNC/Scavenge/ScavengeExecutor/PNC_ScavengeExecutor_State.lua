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
local completeLease = Internal.CompleteLease
local workerFor = Internal.WorkerFor
local setWorkerPhase = Internal.SetWorkerPhase
local queuedEntries = Internal.QueuedEntries
local teamCanClaim = Internal.TeamCanClaim
local clearWorkerAction = Internal.ClearWorkerAction

local function noAssignedQueue(session)
    for _, candidate in ipairs(queuedEntries(session)) do
        if candidate.entry.assignedNpcId then return false end
    end
    return true
end

local function queuedTeamCapacity(session)
    for _, candidate in ipairs(queuedEntries(session)) do
        if candidate.entry.assignedNpcId
            or teamCanClaim(session, candidate.entry)
        then return true end
    end
    return false
end

local function pauseTeamForCapacity(session)
    if session.state == "PAUSED_CAPACITY" then return end
    if Service.Internal.FlushRecordBroadcasts then
        Service.Internal.FlushRecordBroadcasts(session,
            "scavenge_capacity_pause")
    end
    Service.Internal.ReleaseReservations(session, "capacity_pause")
    for _, entry in ipairs(session.manifest or {}) do
        if entry.status == "QUEUED" then
            entry.status = "AVAILABLE"
            entry.assignedNpcId = nil
            entry.failureReason = "no_team_capacity"
        end
    end
    session.queue = nil
    session.queueCount = 0
    session.state = "PAUSED_CAPACITY"
    session.phase = "PAUSED_CAPACITY"
    session.runActive = false
    Service.Internal.Activity(session, "PAUSED_CAPACITY", nil,
        "team_capacity_reached")
    Service.Internal.Touch(session, "CollectionPaused", {
        reason = "team_capacity_reached",
    }, "immediate")
    for _, npcId in ipairs(session.npcIds or { session.npcId }) do
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_CAPACITY_PAUSE")
        Service.Internal.RestorePreviousOrder(session, npcId)
    end
end

local function allWorkersIdle(session)
    for _, npcId in ipairs(session.npcIds or { session.npcId }) do
        local worker = workerFor(session, npcId)
        if worker.phase ~= "IDLE" then return false end
    end
    return true
end

local function settleIdleSession(session)
    if not allWorkersIdle(session) then return end
    if Service.Internal.FlushRecordBroadcasts then
        Service.Internal.FlushRecordBroadcasts(session,
            "scavenge_search_complete")
    end
    session.searchComplete = session.nextCandidateIndex > session.candidateCount
    session.state = "WAITING_FOR_SELECTION"
    session.phase = "WAITING_FOR_SELECTION"
    session.runActive = false
    Service.Internal.Activity(session, "SEARCH_COMPLETE", nil,
        session.truncated and "results_truncated" or nil)
    Service.Internal.Touch(session, "SearchCompleted", {
        count = #session.manifest,
        truncated = session.truncated == true,
    }, "immediate")
end

local function finishWorker(session, worker, lease)
    if Service.Internal.FlushRecordBroadcasts then
        Service.Internal.FlushRecordBroadcasts(session,
            "scavenge_worker_complete", worker.npcId)
    end
    clearWorkerAction(worker)
    worker.phase = "IDLE"
    Service.Internal.RestorePreviousOrder(session, worker.npcId)
    completeLease(lease, "SCAVENGE_WORKER_IDLE")
    settleIdleSession(session)
end

Internal.NoAssignedQueue = noAssignedQueue
Internal.QueuedTeamCapacity = queuedTeamCapacity
Internal.PauseTeamForCapacity = pauseTeamForCapacity
Internal.AllWorkersIdle = allWorkersIdle
Internal.SettleIdleSession = settleIdleSession
Internal.FinishWorker = finishWorker

return Executor
