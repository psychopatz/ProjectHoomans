if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC.ScavengeExecutor
local Internal = Executor.Internal
local Service = PNC.ScavengeService
local workerFor = Internal.WorkerFor
local setWorkerPhase = Internal.SetWorkerPhase
local combatBlockReason = Internal.CombatBlockReason
local finishSearchAction = Internal.FinishSearchAction
local transferWorkerEntry = Internal.TransferWorkerEntry
local arriveWorker = Internal.ArriveWorker
local failWorkerSource = Internal.FailWorkerSource
local beginLootScene = Internal.BeginLootScene
local queuedEntries = Internal.QueuedEntries
local claimQueuedEntry = Internal.ClaimQueuedEntry
local noAssignedQueue = Internal.NoAssignedQueue
local queuedTeamCapacity = Internal.QueuedTeamCapacity
local pauseTeamForCapacity = Internal.PauseTeamForCapacity
local claimSearchSource = Internal.ClaimSearchSource
local finishWorker = Internal.FinishWorker

local function tickWorker(session, lease, record, body)
    local worker = workerFor(session, lease.npcId)
    local combatReason = combatBlockReason(record)
    if combatReason then
        if worker.actionUntil then
            worker.actionUntil = nil
            worker.actionScene = nil
            if PNC.AnimationScenes and PNC.AnimationScenes.Interrupt then
                PNC.AnimationScenes.Interrupt(record, body, "combat")
            end
        end
        worker.waitReason = combatReason
        setWorkerPhase(session, worker, "INTERRUPTED_COMBAT", "WAITING")
        return true
    elseif worker.phase == "INTERRUPTED_COMBAT" then
        worker.phase = "READY"
        worker.waitReason = nil
    end
    if worker.actionUntil then
        if PNC.Core.Now() < worker.actionUntil then return true end
        if worker.currentKind == "search" then
            finishSearchAction(session, worker)
        else
            transferWorkerEntry(session, worker, record, body)
        end
        worker.phase = "READY"
        return true
    end
    if worker.currentSource then
        local arrived, reason = arriveWorker(session, worker, record, body)
        if arrived == nil then return true end
        if arrived ~= true then
            failWorkerSource(session, worker, reason)
            worker.phase = "READY"
            return true
        end
        beginLootScene(session, worker, record, body)
        return true
    end
    local queued = queuedEntries(session)
    if #queued > 0 then
        if claimQueuedEntry(session, worker, record) then return true end
        setWorkerPhase(session, worker, "WAITING_FOR_CAPACITY", "WAITING")
        if noAssignedQueue(session) and not queuedTeamCapacity(session) then
            pauseTeamForCapacity(session)
        end
        return true
    end
    if claimSearchSource(session, worker) then
        session.state = "DISCOVERING"
        worker.phase = "READY"
        return true
    end
    finishWorker(session, worker, lease)
    return true
end

Internal.TickWorker = tickWorker

return Executor
