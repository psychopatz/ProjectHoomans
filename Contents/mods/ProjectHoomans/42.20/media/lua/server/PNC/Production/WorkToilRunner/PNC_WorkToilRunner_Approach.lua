-- Shared live work-target approach and stall/backoff observation helper.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkToilRunner = PNC.WorkToilRunner or {}

local Runner = PNC.WorkToilRunner
local DEFAULT_STALL_TIMEOUT_MS = 12000
local DEFAULT_RECOVERY_COOLDOWN_MS = 3000
local DEFAULT_MAX_RECOVERIES = 2

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function isArrived(record, body, targetPos, opts)
    if opts and type(opts.isArrived) == "function" then
        return opts.isArrived(record, body, targetPos) == true
    end
    if type(targetPos) ~= "table" then return false end
    local bx = body and type(body.getX) == "function" and body:getX() or record and record.x
    local by = body and type(body.getY) == "function" and body:getY() or record and record.y
    local bz = body and type(body.getZ) == "function" and body:getZ() or record and record.z or 0
    if not bx or not by then return false end
    local tx = tonumber(targetPos.x) or 0
    local ty = tonumber(targetPos.y) or 0
    local tz = tonumber(targetPos.z) or 0
    if math.abs((tonumber(bz) or 0) - tz) >= (tonumber(targetPos.zTolerance) or 0.6) then
        return false
    end
    local arriveDist = tonumber(targetPos.arriveDistance or targetPos.stopDistance) or 1.2
    local dx = math.abs((tonumber(bx) or 0) - tx)
    local dy = math.abs((tonumber(by) or 0) - ty)
    if opts and opts.manhattan == true then
        return (dx + dy) <= arriveDist
    end
    if opts and opts.boxAdjacency == true then
        return dx <= arriveDist and dy <= arriveDist
    end
    return math.sqrt((dx * dx) + (dy * dy)) <= arriveDist
end

local function updateWatchProgress(watch, bx, by, body, record, at)
    if watch.lastX ~= nil and watch.lastY ~= nil and bx and by then
        local dx = (tonumber(bx) or 0) - (tonumber(watch.lastX) or 0)
        local dy = (tonumber(by) or 0) - (tonumber(watch.lastY) or 0)
        if math.sqrt((dx * dx) + (dy * dy)) >= 0.05 then
            watch.lastProgressAt = at
        end
    end
    watch.lastX, watch.lastY = bx, by

    local pathService = PNC.PathService
    local recovery
    if pathService and type(pathService.GetMovementRecoveryState) == "function" then
        recovery = pathService.GetMovementRecoveryState(record, body, at)
        local lastPathProgress = recovery and tonumber(recovery.lastProgressAt)
        if lastPathProgress and lastPathProgress > (tonumber(watch.lastProgressAt) or 0) then
            watch.lastProgressAt = lastPathProgress
        end
    end
    if recovery and recovery.ownerMode == "engine_path"
        and PNC.EnginePathPlanner
        and type(PNC.EnginePathPlanner.ReconcileNativeMovementOwner) == "function"
    then
        PNC.EnginePathPlanner.ReconcileNativeMovementOwner(body)
    end
    return recovery
end

---Observes live travel to targetPos with PathService recovery coordination.
function Runner.ObserveLiveApproach(record, body, targetKey, targetPos, at, opts)
    if type(record) ~= "table" then return "stalled", nil, nil end
    opts = opts or {}
    at = tonumber(at) or nowMs()
    record.runtime = record.runtime or {}
    local slot = tostring(opts.watchSlot or "default")
    record.runtime.workApproachWatch = record.runtime.workApproachWatch or {}

    if isArrived(record, body, targetPos, opts) then
        record.runtime.workApproachWatch[slot] = nil
        if opts.haltOnArrival ~= false and PNC.BehaviorCommon
            and type(PNC.BehaviorCommon.HaltMovement) == "function"
        then
            PNC.BehaviorCommon.HaltMovement(record, body,
                opts.haltReason or "work_arrived")
        end
        return "arrived", nil, nil
    end

    if opts.issueMove ~= false and type(targetPos) == "table" and PNC.BehaviorCommon then
        if type(PNC.BehaviorCommon.ClearCombatTarget) == "function" then
            PNC.BehaviorCommon.ClearCombatTarget(record,
                opts.moveReason or "work_approach", body)
        end
        if type(PNC.BehaviorCommon.MoveRecord) == "function" then
            PNC.BehaviorCommon.MoveRecord(record, body,
                tonumber(targetPos.x) or record.x,
                tonumber(targetPos.y) or record.y,
                tonumber(targetPos.z) or record.z or 0,
                opts.moveStyle or "walk",
                tonumber(targetPos.stopDistance) or 0.35,
                opts.moveReason or "work_approach")
        end
    end

    local bx = body and type(body.getX) == "function" and body:getX() or record.x
    local by = body and type(body.getY) == "function" and body:getY() or record.y
    local key = tostring(targetKey or "") .. "|"
        .. tostring(targetPos and targetPos.x or "") .. "|"
        .. tostring(targetPos and targetPos.y or "") .. "|"
        .. tostring(targetPos and targetPos.z or "")
    local watch = record.runtime.workApproachWatch[slot]
    if type(watch) ~= "table" or watch.key ~= key then
        watch = {
            key = key, startedAt = at, lastProgressAt = at,
            lastX = bx, lastY = by, recoveries = 0, nextRetryAt = 0,
        }
        record.runtime.workApproachWatch[slot] = watch
    end

    local recovery = updateWatchProgress(watch, bx, by, body, record, at)
    record.runtime.workApproachDiagnostic = recovery and {
        phase = recovery.phase,
        ownerMode = recovery.ownerMode,
        nativeStallRecoveryCount = recovery.nativeStallRecoveryCount,
        nativeBackoff = recovery.nativeBackoff,
        nativeFallback = recovery.nativeFallback,
        lastProgressAt = recovery.lastProgressAt,
        lastProgressReason = recovery.lastProgressReason,
    } or nil

    if at < (tonumber(watch.nextRetryAt) or 0) then
        return "backoff", watch, recovery
    end
    local cooldownMs = tonumber(opts.recoveryCooldownMs)
        or DEFAULT_RECOVERY_COOLDOWN_MS
    if recovery and (recovery.nativeBackoff == true
        or recovery.nativeFallback == true or recovery.watchable == false)
    then
        watch.lastProgressAt = at
        watch.nextRetryAt = at + cooldownMs
        return "backoff", watch, recovery
    end
    local timeoutMs = tonumber(opts.stallTimeoutMs) or DEFAULT_STALL_TIMEOUT_MS
    if at - (tonumber(watch.lastProgressAt) or at) < timeoutMs then
        return "moving", watch, recovery
    end

    local maxRecoveries = tonumber(opts.maxRecoveries) or DEFAULT_MAX_RECOVERIES
    local pathService = PNC.PathService
    if (tonumber(watch.recoveries) or 0) < maxRecoveries then
        local resetAccepted = true
        local reason = opts.resetReason or "work_travel_stall"
        if pathService and pathService.Commands
            and type(pathService.Commands.Reset) == "function"
        then
            resetAccepted = pathService.Commands.Reset(record, body, reason) ~= false
        elseif pathService and type(pathService.Reset) == "function" then
            resetAccepted = pathService.Reset(body, record, reason) ~= false
        end
        if resetAccepted then
            watch.recoveries = (tonumber(watch.recoveries) or 0) + 1
            watch.lastProgressAt = at
            watch.nextRetryAt = at + cooldownMs
            return "recovered", watch, recovery
        end
    end
    return "stalled", watch, recovery
end

return Runner
