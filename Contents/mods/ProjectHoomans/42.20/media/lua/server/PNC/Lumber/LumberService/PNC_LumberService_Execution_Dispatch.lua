-- Lumber execution dispatch and bounded runtime diagnostics.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local now = Internal.Now
local markDirty = Internal.MarkDirty
local updateRuntime = Internal.UpdateRuntime
local guideToZone = Internal.GuideToZone
local ensureTreeClaim = Internal.EnsureTreeClaim
local selectClaimedTarget = Internal.SelectClaimedTarget
local expireClaims = Internal.ExpireClaims
local outputEffectFor = Internal.OutputEffectFor
local flushAbstractOutput = Internal.FlushAbstractOutput
local tickLiveOutput = Internal.TickLiveOutput
local tickLive = Internal.TickLive
local tickAbstract = Internal.TickAbstract
local toolDiagnostic = Internal.ToolDiagnostic
local lumberDiagnostics = Service.LumberDiagnostics

local function tickJob(lease)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not zone or not record or job.active ~= true
        or zone.enabled ~= true
    then return false, false, "job_unavailable" end
    local at = now()
    expireClaims(at)
    local body = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
    lease.executionMode = body and "LIVE" or "ABSTRACT"
    job.executionMode = lease.executionMode
    if job.pendingOutput then
        if tostring(job.pendingOutput.mode or "ABSTRACT") == "LIVE" then
            if not body then
                local effect = outputEffectFor(job.pendingOutput)
                job.state, job.phase = "WAITING", "WAITING_FOR_WORKER"
                if effect then
                    effect.waitReason = "LUMBER_LIVE_WORKER_REQUIRED"
                    effect.lastReason = effect.waitReason
                    effect.updatedAt = at
                    markDirty()
                end
                updateRuntime(record, job, nil)
                return true, false, "live_output_requires_worker"
            end
            return tickLiveOutput(job, record, body, at)
        end
        if not flushAbstractOutput(job, record) then
            job.state, job.phase = "WAITING", "OUTPUT_PENDING"
            updateRuntime(record, job, nil)
            return true, false, "output_pending"
        end
    end
    local tree = job.targetKey and Service.GetTree(job.targetKey) or nil
    if not tree or tree.status == "DEPLETED" or tree.status == "INVALID" then
        tree = nil
        job.targetKey, job.approach = nil, nil
    end
    if not tree then
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey = tree.key
            job.approach = nil
            job.lastHitAt = nil
            job.lastProgressAt = at
            job.revision = (tonumber(job.revision) or 0) + 1
        end
    end
    if tree and not ensureTreeClaim(tree.key, npcId, at) then
        tree = nil
        job.targetKey, job.approach = nil, nil
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey, job.approach = tree.key, nil
            job.lastHitAt, job.lastProgressAt = nil, at
        end
    end
    if not tree then
        local pendingScan = zone.scan.complete ~= true
        if pendingScan then
            guideToZone(job, zone, record, body)
            return true, false, "scanning"
        end
        job.state, job.phase = "COMPLETED", "COMPLETE"
        job.activityItemFullType = nil
        updateRuntime(record, job, nil)
        return true, true, "zone_exhausted"
    end
    if body then return tickLive(job, record, body, tree, at) end
    return tickAbstract(job, record, tree, at)
end

local function waitingFor(phase, reason)
    if phase == "WAITING_FOR_TOOL"
        or string.find(tostring(reason or ""), "lumber_tool", 1, true)
        or reason == "tool_cannot_chop"
    then return "primary_tool" end
    if phase == "WAITING_FOR_FATIGUE" then return "fatigue" end
    if phase == "WAITING_FOR_MATERIALIZATION" then return "live_execution" end
    if phase == "WAITING_FOR_TREE_CHUNK" then return "world" end
    if phase == "WAITING_FOR_TRAVEL" then return "travel" end
    if phase == "WAITING_FOR_STOCKPILE" then return "stockpile" end
    if phase == "OUTPUT_PENDING" then return "output" end
    if phase == "GRAB_PENDING" or phase == "DEPOSIT_PENDING" then
        return "output"
    end
    if phase == "TRAVEL" or phase == "WAITING_FOR_TRAVEL"
        or reason == "traveling"
        or reason == "not_adjacent"
    then return "travel" end
    if phase == "WAITING_FOR_WORKER" or reason == "waiting_for_worker" then
        return "worker"
    end
    return nil
end

local function publishTickDiagnostic(lease, reason, complete)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not record then return end
    record.runtime = record.runtime or {}
    local runtime = record.runtime.lumber
    if not runtime then
        runtime = {}
        record.runtime.lumber = runtime
    end
    local phase = tostring(job.phase or runtime.phase or "")
    local diagnosticReason = reason
    if phase == "WAITING_FOR_STOCKPILE" and job.outputWaitReason then
        diagnosticReason = job.outputWaitReason
    end
    runtime.lastReason = diagnosticReason
    runtime.waitingFor = waitingFor(phase, diagnosticReason)
    runtime.waitingReason = runtime.waitingFor and diagnosticReason or nil
    runtime.retryAt = job.outputRetryAt
    runtime.capacity = job.outputCapacityDetails
    if phase == "BLOCKED" then
        runtime.blockedReason = diagnosticReason or runtime.lastReason
        runtime.blockedAt = runtime.blockedAt or now()
    else
        runtime.blockedReason = nil
        runtime.blockedAt = nil
    end
    if runtime.waitingFor == "primary_tool" then
        local body = PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(npcId) or nil
        runtime.tool = toolDiagnostic(record, body)
    else
        runtime.tool = nil
    end
    if complete then
        runtime.waitingFor = nil
        runtime.waitingReason = nil
        runtime.tool = nil
    end
    if lumberDiagnostics and lumberDiagnostics.RecordTransition then
        local body = PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(npcId) or nil
        local handoff = record.runtime.lumberHandoff or {}
        lumberDiagnostics.RecordTransition(record, job, body, reason, {
            treeKey = runtime.treeKey,
            treeLoaded = handoff.treeLoaded,
            complete = complete,
        })
    end
end

function Service.TickJob(lease)
    local ok, complete, reason = tickJob(lease)
    publishTickDiagnostic(lease, reason, complete)
    return ok, complete, reason
end

return Service
