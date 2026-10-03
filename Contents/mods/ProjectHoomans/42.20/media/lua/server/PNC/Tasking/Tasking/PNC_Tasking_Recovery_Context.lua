-- Shared task watchdog context and movement recovery provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
local H = Tasking.Internal or {}
Tasking.Internal = H

local WATCHDOG_PHASES = {
    -- WorkService's clock currently represents collection/output progress,
    -- not locomotion. Keep travel owned by PathService until Work exposes a
    -- truthful movement-progress probe.
    WORKING = true,
}

local function counters()
    Tasking.Diagnostics = Tasking.Diagnostics or {}
    Tasking.Diagnostics.counters = Tasking.Diagnostics.counters or {}
    return Tasking.Diagnostics.counters
end

local function emit(eventType, lease, payload)
    if Tasking.Events and type(Tasking.Events.Emit) == "function" then
        Tasking.Events.Emit(eventType, {
            npcId = lease and lease.npcId,
            source = "Tasking.Recovery",
            entityId = lease and lease.leaseId,
            payload = payload or {},
        })
    end
end

local function isNonInterruptible(lease)
    local definitions = PNC.TaskRequestDefinitions
    return definitions and definitions.NON_INTERRUPTIBLE_PHASE
        and definitions.NON_INTERRUPTIBLE_PHASE[lease.phase] == true
end

local function isWatchable(lease, snapshot)
    if not lease
        or Tasking.WATCHDOG_DOMAINS[tostring(lease.sourceDomain or "")] ~= true
        or isNonInterruptible(lease)
    then
        return false
    end
    if snapshot and snapshot.watchable ~= nil then
        return snapshot.watchable == true
    end
    return WATCHDOG_PHASES[tostring(lease.phase or "")] == true
end

local function stateFor(lease, at, reportedProgressAt)
    local state = lease.recovery
    if type(state) ~= "table" then
        state = { attempts = 0, nextAttemptAt = 0 }
        lease.recovery = state
    end
    local progressAt = tonumber(reportedProgressAt)
        or tonumber(lease.lastProgressAt)
        or tonumber(lease.startedAt) or at
    if state.observedProgressAt ~= progressAt then
        state.observedProgressAt = progressAt
        state.attempts = 0
        state.nextAttemptAt = 0
        state.quarantined = nil
    end
    return state, progressAt
end

-- Puppet Opera pauses the task executor without completing or cancelling the
-- durable task. Keep the watchdog clock paused as well. The provider's
-- progress field intentionally remains untouched so a real task update still
-- wins as soon as the provider resumes.
local function progressBaseline(lease, snapshot)
    local progressAt = tonumber(snapshot and snapshot.lastProgressAt)
        or tonumber(lease and lease.lastProgressAt)
    local resumedAt = tonumber(lease and lease.puppetOperaResumeAt)
    if resumedAt then
        if progressAt and progressAt >= resumedAt then
            lease.puppetOperaResumeAt = nil
        else
            progressAt = resumedAt
        end
    end
    return progressAt
end

local function refreshProviderState(lease)
    local provider = lease and Tasking.Providers
        and Tasking.Providers[lease.sourceDomain]
    local ok
    local snapshot
    if not provider or type(provider.GetRecoveryState) ~= "function" then
        return nil
    end
    ok, snapshot = H.SafeCall(
        "task_recovery_provider_state",
        provider.GetRecoveryState,
        {
            npcId = lease and lease.npcId,
            leaseId = lease and lease.leaseId,
            domain = lease and lease.sourceDomain,
        },
        lease
    )
    if not ok then return nil end
    if type(snapshot) ~= "table" then
        H.RecordFailure(
            "task_recovery_provider_state",
            {
                npcId = lease and lease.npcId,
                leaseId = lease and lease.leaseId,
                domain = lease and lease.sourceDomain,
            },
            "INVALID_RECOVERY_STATE"
        )
        return nil
    end
    if snapshot.lastProgressAt ~= nil then
        lease.lastProgressAt = snapshot.lastProgressAt
    end
    if snapshot.phase then lease.phase = snapshot.phase end
    return snapshot
end

-- Movement is owned by PathService. Providers may ask for this observation,
-- but must not create a second path watchdog or mutate the movement lane from
-- their recovery probe.
function H.ApplyMovementRecovery(snapshot, lease, record)
    if type(snapshot) ~= "table"
        or tostring(snapshot.phase or "") ~= "TRAVEL"
    then return snapshot end

    local pathService = PNC.PathService
    local zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record and record.id or lease and lease.npcId)
        or nil
    local movement = pathService
        and pathService.GetMovementRecoveryState
        and pathService.GetMovementRecoveryState(record, zombie)
        or nil
    if movement then
        if tonumber(movement.lastProgressAt)
            and tonumber(movement.lastProgressAt) > 0
        then
            snapshot.lastProgressAt = movement.lastProgressAt
        end
        snapshot.movement = movement
        if movement.active == true then
            snapshot.watchable = movement.watchable == true
            snapshot.forceRecovery = movement.forceRecovery == true
            snapshot.recoveryReason = movement.forceRecovery == true
                and "path_traversal_timeout" or nil
        else
            snapshot.watchable = true
            snapshot.timeoutMs = 15000
            snapshot.recoveryReason = "path_lane_inactive"
        end
    else
        -- A travel phase with no lane is a bounded coordination failure. Give
        -- the behavior pump a short window to create the lane, then release
        -- the lease so the task can be reevaluated cleanly.
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "path_lane_missing"
    end
    return snapshot
end

function H.GetRecoveryState(lease, at)
    at = tonumber(at) or PNC.Core.Now()
    local state = lease and lease.recovery
    if type(state) ~= "table" then return nil end
    if state.quarantined == true then return "QUARANTINED" end
    if tonumber(at) < (tonumber(state.nextAttemptAt) or 0) then
        return "RECOVERY_BACKOFF"
    end
    return nil
end

H.RecoveryCounters = counters
H.RecoveryEmit = emit
H.RecoveryIsNonInterruptible = isNonInterruptible
H.RecoveryIsWatchable = isWatchable
H.RecoveryStateFor = stateFor
H.RecoveryProgressBaseline = progressBaseline
H.RecoveryRefreshProviderState = refreshProviderState
