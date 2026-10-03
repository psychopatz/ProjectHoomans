-- Corpse haul active-order reconciliation and recovery.
--
-- This provider owns pending world effects, legacy completion recovery,
-- durable retirement, diagnostics, and bounded active-order scans.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local WorldEffects = PNC.WorldEffectService

local same = Internal.sameCorpseValue
local pointMatches = Internal.corpsePointMatches
local candidatesForOrder = Internal.corpseCandidatesForOrder
local chooseCandidate = Internal.chooseCorpseCandidate
local rebindOrder = Internal.rebindCorpseOrder
local removeDuplicateCorpses = Internal.removeDuplicateCorpses
local clearReservationMarkers = Internal.clearCorpseReservationMarkers

local function terminal(order)
    local status = order and tostring(order.status or "") or ""
    return status == "CANCELLED" or status == "COMPLETED"
        or status == "FAILED"
end

local function reconcileDiagnostic(order, stage, reason, candidate, extra)
    if not Core or not Core.Log or not order then return end
    local payload = order.payload or {}
    local now = Core.Now()
    local key = tostring(stage) .. ":" .. tostring(reason)
    if order.corpseReconcileDiagnosticKey == key
        and now - (tonumber(order.corpseReconcileDiagnosticAt) or 0)
            < (tonumber(Service.CORPSE_HAUL_DIAGNOSTIC_INTERVAL_MS) or 2000)
    then return end
    order.corpseReconcileDiagnosticKey = key
    order.corpseReconcileDiagnosticAt = now
    Core.Log("WARN", "corpse_haul_reconcile stage=" .. tostring(stage)
        .. " order=" .. tostring(order.id or "unknown")
        .. " status=" .. tostring(order.status or "")
        .. " phase=" .. tostring(order.phase or "")
        .. " reason=" .. tostring(reason or "unknown")
        .. " source=" .. tostring(payload.sourceX or "?") .. ","
        .. tostring(payload.sourceY or "?") .. ","
        .. tostring(payload.sourceZ or "?")
        .. " token=" .. tostring(payload.haulToken or "?")
        .. " candidate=" .. tostring(candidate and candidate.x or "?")
        .. "," .. tostring(candidate and candidate.y or "?")
        .. "," .. tostring(candidate and candidate.z or "?")
        .. " candidateToken=" .. tostring(candidate and candidate.token
            or "?")
        .. " candidateTask=" .. tostring(candidate and candidate.taskId
            or "?")
        .. " candidateDeath=" .. tostring(candidate
            and candidate.deathMarkerId or "?")
        .. (extra and " " .. tostring(extra) or ""))
end

local function pendingEffect(order)
    return order and order.status == Status.WORLD_EFFECT_PENDING
        and type(order.worldEffect) == "table"
        and tostring(order.worldEffect.state or "PENDING") ~= "APPLIED"
        and order.worldEffect or nil
end

-- Compatibility seams remain for older callers and tests, but the pending
-- world-effect index and retry loop now belong to WorldEffectService.
function Internal.indexPendingWorldEffect(order)
    return WorldEffects and WorldEffects.IndexOrder
        and WorldEffects.IndexOrder(order) or false
end

function Internal.reconcilePendingWorldEffects(now, pointKey, limit)
    if not WorldEffects or not WorldEffects.Reconcile then return 0 end
    local applied = WorldEffects.Reconcile(now, pointKey, limit)
    return applied or 0
end

local function retireOrder(order, candidates, reason, now)
    clearReservationMarkers(order, candidates)
    if Internal.clearWorkRuntime then
        Internal.clearWorkRuntime(order, reason)
    end
    if Work and Work.Commands and Work.Commands.Cancel then
        local ok, cancelReason = Work.Commands.Cancel(order.id, reason)
        if ok ~= true then
            reconcileDiagnostic(order, "RETIRE", cancelReason
                or "CANCELLATION_FAILED", nil)
            return false
        end
    else
        order.status = Status.CANCELLED or "CANCELLED"
        order.cancellationReason = reason
        order.cancelledAt = now
        order.updatedAt = now
        order.revision = (tonumber(order.revision) or 0) + 1
        if WorkRepository and WorkRepository.MarkDirty then
            WorkRepository.MarkDirty()
        end
    end
    reconcileDiagnostic(order, "RETIRE", reason, nil)
    return true
end

local function candidateMatchesIdentity(candidate, order)
    local payload = order and order.payload or {}
    local marker = payload.deathMarkerId or payload.corpseId
    return candidate
        and (same(candidate.token, payload.haulToken)
            or same(candidate.taskId, order and order.id)
            or same(candidate.deathMarkerId, marker))
end

local function releaseBlockedAssignment(order, reason)
    if not order or not order.workerId then return true end
    local released
    local releaseReason
    if Work and Work.Commands and Work.Commands.ReleaseAssignment then
        released, releaseReason = Work.Commands.ReleaseAssignment(
            order.workerId, reason)
    elseif Work and Work.Commands and Work.Commands.ReleaseWorker then
        released, releaseReason = Work.Commands.ReleaseWorker(order.workerId,
            reason)
    elseif Work and Work.Internal and Work.Internal.releaseClaim then
        released, releaseReason = Work.Internal.releaseClaim(order, reason,
            false, true)
    end
    return released == true, releaseReason
end

-- Repair orders written by the old shared behavior, which could mark a corpse
-- haul BLOCKED at 100% while the corpse was still at its source. This path is
-- intentionally identity- and location-gated; it does not guess what to do
-- with unrelated blocked corpse orders.
local function recoverLegacyCompletion(order, candidates, now)
    if tostring(order and order.status or "") ~= Status.BLOCKED
        or tostring(order and order.blockedReason or "")
            ~= "CORPSE_NOT_AT_DESTINATION"
    then
        return nil
    end
    local payload = order.payload or {}
    local phase = tostring(order.phase or "")
    if phase ~= "SOURCE_APPROACH" and phase ~= "" then return nil end
    local destinationCandidate
    local sourceCandidate
    for _, candidate in ipairs(candidates or {}) do
        if candidateMatchesIdentity(candidate, order) then
            if pointMatches(candidate, payload.dropX, payload.dropY,
                payload.dropZ)
            then
                destinationCandidate = destinationCandidate or candidate
            elseif pointMatches(candidate, payload.sourceX, payload.sourceY,
                payload.sourceZ)
            then
                sourceCandidate = sourceCandidate or candidate
            end
        end
    end
    if destinationCandidate and order.workerId
        and Work and Work.Commands and Work.Commands.AddProgress
    then
        local completed = Work.Commands.AddProgress(order.id, order.workerId,
            order.requiredWork)
        if completed == true and order.status == Status.COMPLETED then
            reconcileDiagnostic(order, "RECOVER", "CORPSE_ALREADY_AT_DESTINATION",
                destinationCandidate)
            return "COMPLETED"
        end
    end
    if not sourceCandidate then return nil end
    local released, releaseReason = releaseBlockedAssignment(order,
        "corpse_haul_legacy_completion_retry")
    if not released then
        reconcileDiagnostic(order, "RECOVER", releaseReason
            or "WORK_ASSIGNMENT_RELEASE_FAILED", sourceCandidate)
        return "WAITING"
    end
    if payload then payload.haulToken = nil end
    order.progress = 0
    order.status = Status.WAITING_FOR_WORKER
    order.blockedReason = "CORPSE_NOT_AT_DESTINATION"
    order.phase, order.livePhase = nil, nil
    order.updatedAt = now
    order.revision = (tonumber(order.revision) or 0) + 1
    -- Rebind immediately so the next task-evaluation pass does not observe a
    -- waiting order with an already-cleared corpse token.
    rebindOrder(order, sourceCandidate, nil, now)
    if WorkRepository and WorkRepository.MarkDirty then
        WorkRepository.MarkDirty()
    end
    reconcileDiagnostic(order, "RECOVER", "CORPSE_HAUL_REQUEUED",
        sourceCandidate)
    if Work and Work.Internal and Work.Internal.markAssignmentDirty then
        Work.Internal.markAssignmentDirty(order,
            "CORPSE_HAUL_LEGACY_COMPLETION_RECOVERED")
    end
    return "RETRYING"
end

local function baseForOrder(order)
    if PNC.BaseService and PNC.BaseService.Get then
        local base = PNC.BaseService.Get(order and order.baseId)
        if base then return base end
    end
    local settlements = PNC.SettlementRepository
    return settlements and settlements.State and settlements.State.bases
        and settlements.State.bases[tostring(order and order.baseId or "")]
        or nil
end

local function reconcileOrder(order, baseCandidates, now)
    local payload = order and order.payload or nil
    local task = Service.Runtime.byTask[tostring(order and order.id or "")]
    local base = baseForOrder(order)
    local candidates
    local candidate
    local score
    local minimumScore
    local sourceSquare
    local missingAt
    local grace
    if not order or terminal(order)
        or tostring(order.status or "") == "CANCELLING"
    then return "SKIP" end
    if pendingEffect(order) then
        Internal.indexPendingWorldEffect(order)
        return "WORLD_EFFECT_PENDING"
    end
    if type(payload) ~= "table" or not tonumber(payload.sourceX)
        or not tonumber(payload.sourceY) or not tonumber(payload.sourceZ)
    then
        reconcileDiagnostic(order, "PAYLOAD", "CORPSE_HAUL_PAYLOAD_INVALID",
            nil)
        retireOrder(order, {}, "corpse_haul_payload_invalid", now)
        return "RETIRED"
    end
    if not base or not Internal.configurationFor(base) then
        reconcileDiagnostic(order, "CONFIG", "CORPSE_HAUL_NOT_CONFIGURED",
            nil)
        return "WAITING"
    end
    candidates = candidatesForOrder(order, baseCandidates)
    local legacyRecovery = recoverLegacyCompletion(order, candidates, now)
    if legacyRecovery then return legacyRecovery end
    candidate, score = chooseCandidate(candidates, order, task)
    minimumScore = (payload.haulToken and tostring(payload.haulToken) ~= ""
        or payload.deathMarkerId
            and tostring(payload.deathMarkerId) ~= "") and 60 or 20
    if candidate and score >= minimumScore then
        local reboundChanged = rebindOrder(order, candidate, task, now)
        local removed = removeDuplicateCorpses(candidates, candidate, order)
        if removed > 0 then
            Service.Runtime.countsByBase[tostring(order.baseId or "")] = nil
        end
        if reboundChanged or removed > 0 then
            reconcileDiagnostic(order, "BOUND", "CORPSE_REBOUND", candidate,
                removed > 0 and ("duplicatesRemoved=" .. tostring(removed))
                    or nil)
        end
        return "BOUND"
    end
    sourceSquare = Internal.squareAt(payload.sourceX, payload.sourceY,
        payload.sourceZ)
    if not sourceSquare then
        local changed = order.workerId ~= nil
            and order.status ~= Status.WAITING_FOR_WORLD
        if changed then
            order.status = Status.WAITING_FOR_WORLD
            order.blockedReason = "SOURCE_CHUNK_LOADING"
            order.updatedAt, order.lastProgressAt = now, now
            order.revision = (tonumber(order.revision) or 0) + 1
            if WorkRepository and WorkRepository.MarkDirty then
                WorkRepository.MarkDirty()
            end
        end
        return "UNLOADED"
    end
    missingAt = tonumber(order.corpseReconcileMissingAt)
    if not missingAt then
        order.corpseReconcileMissingAt = now
        order.corpseReconcileReason = "CORPSE_NOT_FOUND"
        if WorkRepository and WorkRepository.MarkDirty then
            WorkRepository.MarkDirty()
        end
        reconcileDiagnostic(order, "WAIT", "CORPSE_NOT_FOUND", nil)
        return "WAITING"
    end
    grace = tonumber(Service.CORPSE_HAUL_RECONCILE_GRACE_MS) or 10000
    if now - missingAt < grace then
        reconcileDiagnostic(order, "WAIT", "CORPSE_NOT_FOUND", nil)
        return "WAITING"
    end
    if retireOrder(order, candidates, "corpse_haul_stale_reservation", now) then
        return "RETIRED"
    end
    return "WAITING"
end

function Internal.reconcileActiveOrders(now, force, baseFilter)
    now = tonumber(now) or Core.Now()
    if not force and now < (tonumber(Service.Runtime.nextReconcileAt) or 0) then
        return 0, 0
    end
    Service.Runtime.nextReconcileAt = now + (tonumber(
        Service.CORPSE_HAUL_RECONCILE_INTERVAL_MS) or 2000)
    if not WorkRepository or not WorkRepository.Load then return 0, 0 end
    WorkRepository.Load()
    local orders, scannedByBase = {}, {}
    local bound, retired = 0, 0
    for _, order in pairs(WorkRepository.State.byId or {}) do
        if order and order.operation == "CORPSE_HAUL" and not terminal(order)
            and tostring(order.status or "") ~= "CANCELLING"
            and (baseFilter == nil or tostring(order.baseId or "")
                == tostring(baseFilter or ""))
        then
            orders[#orders + 1] = order
        end
    end
    for _, order in ipairs(orders) do
        local baseId = tostring(order.baseId or "")
        local base = baseForOrder(order)
        local payload = order.payload or {}
        local sourceLoaded = payload.sourceX and payload.sourceY
            and payload.sourceZ
            and Internal.squareAt(payload.sourceX, payload.sourceY,
                payload.sourceZ) ~= nil
        local baseCandidates
        if pendingEffect(order) or order.status == Status.WAITING_FOR_WORLD
            or not sourceLoaded
        then
            -- Active world waits only need their identity points checked. A
            -- full source-region walk is unnecessary while the relevant
            -- chunk is absent and becomes expensive with large zones.
            baseCandidates = {}
        else
            if scannedByBase[baseId] == nil then
                scannedByBase[baseId] = base and Internal.scanBaseCorpses(base)
                    or {}
            end
            baseCandidates = scannedByBase[baseId]
        end
        local result = reconcileOrder(order, baseCandidates, now)
        if result == "BOUND" then bound = bound + 1 end
        if result == "RETIRED" then retired = retired + 1 end
    end
    return bound, retired
end


return Service

