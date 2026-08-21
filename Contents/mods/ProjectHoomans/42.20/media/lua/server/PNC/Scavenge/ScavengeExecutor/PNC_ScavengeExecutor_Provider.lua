if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Executor = PNC.ScavengeExecutor
local Internal = Executor.Internal
local Service = PNC.ScavengeService
local Const = PNC.Const
local sessionForNPC = Internal.SessionForNPC
local liveRecord = Internal.LiveRecord
local resetPath = Internal.ResetPath
local completeLease = Internal.CompleteLease
local workerFor = Internal.WorkerFor
local clearWorkerAction = Internal.ClearWorkerAction
local combatBlockReason = Internal.CombatBlockReason
local tickWorker = Internal.TickWorker

function Executor.GetCandidates(npcId)
    local session = sessionForNPC(npcId)
    local worker = session and workerFor(session, npcId) or nil
    if not session or session.runActive ~= true or not worker then return {} end
    return {{
        taskId = "scavenge_task:" .. session.id .. ":" .. tostring(npcId),
        npcId = tostring(npcId),
        kind = "SCAVENGE",
        sourceDomain = "scavenge",
        sourceRef = session.id,
        -- This is an explicit player order. Only critical needs and hard
        -- emergencies may preempt it; ordinary needs/work must not leave a
        -- search session alive while its worker silently does something else.
        precedence = "FORCED_ORDER",
        urgency = 0.75,
        capability = "SCAVENGE",
        interruptPolicy = "NORMAL",
        revision = session.revision,
        createdAt = session.createdAt,
    }}
end

function Executor.Validate(intent)
    local session = Service.GetSession(intent and intent.sourceRef)
    return session ~= nil and session.runActive == true
        and session.workers
        and session.workers[tostring(intent.npcId)] ~= nil
end

function Executor.Assign(intent)
    local session = Service.GetSession(intent and intent.sourceRef)
    if not session then return nil, "session_not_found" end
    return { executionMode = "LIVE", resourceKey = session.id,
        resourceKind = "WORLD_LOOT_SESSION" }
end

function Executor.Start(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    local record = session and PNC.Registry.Get(lease.npcId) or nil
    if not session or not record then return false, "session_or_npc_unavailable" end
    local body = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local worker = workerFor(session, lease.npcId)
    worker.leaseId = lease.leaseId
    worker.phase = "READY"
    resetPath(record, body, "scavenge_start")
    PNC.OrderSystem.SetOrder(record, {
        kind = Const.ORDER_SCAVENGE, sessionId = session.id,
    })
    PNC.Tasking.Commands.SetPhase(lease.npcId, "ASSIGNED")
    return true
end

function Executor.CanContinue(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    return session ~= nil and session.runActive == true
        and session.workers
        and session.workers[tostring(lease.npcId)] ~= nil
end

function Executor.Tick(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    if not session then
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            "SCAVENGE_SESSION_MISSING")
        return false
    end
    local record, body, reason = liveRecord(lease.npcId)
    if not record then
        session.state, session.phase = "FAILED", "FAILED"
        session.lastFailure = reason
        Service.Internal.ReleaseReservations(session, reason)
        WorldLoot.ReleaseSession(session.worldLootSessionId)
        session.worldLootReleased = true
        Service.Internal.Touch(session, "ScavengeFailed", { reason = reason }, true)
        completeLease(lease, "SCAVENGE_NPC_NOT_LIVE")
        return false
    end
    return tickWorker(session, lease, record, body)
end

function Executor.Cancel(lease, reason)
    local session = Service.GetSession(lease and lease.sourceRef)
    if not session then return true end
    local worker = workerFor(session, lease.npcId)
    if worker.currentEntry and worker.currentEntry.status == "QUEUED" then
        worker.currentEntry.assignedNpcId = nil
    end
    clearWorkerAction(worker)
    worker.leaseId = nil
    worker.phase = "IDLE"
    Service.Internal.RestorePreviousOrder(session, worker.npcId)
    return true
end

function Executor.Complete(lease)
    local session = Service.GetSession(lease and lease.sourceRef)
    if session then
        local worker = workerFor(session, lease.npcId)
        worker.leaseId = nil
        worker.phase = "IDLE"
        Service.Internal.RestorePreviousOrder(session, worker.npcId)
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(Const.ORDER_SCAVENGE,
        function(_, spec)
            return { kind = Const.ORDER_SCAVENGE,
                sessionId = tostring(spec.sessionId or "") }
        end)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(Const.ORDER_SCAVENGE, "Scavenge")
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register("Scavenge", function(record, body, _, now)
        local companion = PNC.BehaviorCompanion
        local internal = companion and companion.Internal or nil
        local runtime = record and record.runtime or nil
        if not internal or not record or not body then return true end
        if combatBlockReason(record)
            and internal.TryRespondToImmediateThreat
            and internal.TryRespondToImmediateThreat(record, body)
        then return true end
        now = tonumber(now) or PNC.Core.Now()
        if internal.ShouldScanFollowThreat
            and internal.ShouldScanFollowThreat(record, now, true)
            and internal.TryRespondToThreat
            and internal.TryRespondToThreat(record, body, {
                x = record.x, y = record.y,
                radius = tonumber(Const.FOLLOW_COMBAT_LEASH_DISTANCE) or 5.5,
            })
        then return true end
        return true
    end)
end
PNC.Tasking.Commands.RegisterProvider("scavenge", Executor)

return Executor
