if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationDirector = PNC.PopulationDirector or {}
PNC.PopulationDirector.Internal =
    PNC.PopulationDirector.Internal or {}

local Director = PNC.PopulationDirector
local Internal = Director.Internal
local Config = PNC.DirectorConfig.Population
local Store = PNC.AbstractWorldStore
local Sectors = PNC.PopulationSectors
local Queue = PNC.GenerationQueue
local Log = PNC.PopulationLog
local Starter = PNC.StarterPopulation
local rateAllowed = Internal.rateAllowed
local context = Internal.context
local refresh = Internal.refresh

local function processRequest(kind, now, remainingNPCs)
    local request = Queue.Pop(kind, now)
    if not request then return 0, remainingNPCs end
    if not rateAllowed(kind, now) then
        Queue.Retry(request, now)
        Sectors.SetSuppression(request.sectorId, kind, "CREATION_RATE_LIMIT")
        Log.Info("GENERATION_DEFERRED", { kind = kind,
            sectorId = request.sectorId, reason = "CREATION_RATE_LIMIT" })
        return 1, remainingNPCs
    end
    local ctx = context(now)
    local generator = kind == "SETTLEMENT"
        and PNC.SettlementGenerator or PNC.GroupGenerator
    local plan, reason, evaluated = generator.BuildPlan(request, ctx)
    if not plan then
        Sectors.SetSuppression(request.sectorId, kind, reason)
        Sectors.AddHistory(kind .. "_GENERATION_FAILED", {
            sectorId = request.sectorId, reason = reason }, now)
        Director.Metrics.queueFailures = Director.Metrics.queueFailures + 1
        local transient = reason == "NO_ELIGIBLE_SITE"
            or reason == "no_valid_location"
        local retried = transient and Queue.Retry(request, now) or false
        Log.Warn("GENERATION_PLAN_FAILED", { kind = kind,
            sectorId = request.sectorId, reason = reason,
            candidates = type(evaluated) == "table" and #evaluated or 0,
            attempt = request.attempts, retried = retried == true })
        return 1, remainingNPCs
    end
    local needed = kind == "SETTLEMENT" and plan.initialPopulation
        or plan.memberCount
    if needed > remainingNPCs then
        if kind == "SETTLEMENT" then
            PNC.SettlementCandidates.Release(plan.locationId, plan.generationId)
        end
        Queue.Retry(request, now)
        Sectors.SetSuppression(request.sectorId, kind, "NPC_CREATION_RATE_LIMIT")
        Log.Info("GENERATION_DEFERRED", { kind = kind,
            sectorId = request.sectorId, generationId = plan.generationId,
            reason = "NPC_CREATION_RATE_LIMIT", needed = needed,
            remaining = remainingNPCs })
        return 1, remainingNPCs
    end
    local result = generator.Commit(plan, ctx)
    if result.ok then
        Director.Metrics.queueSuccesses = Director.Metrics.queueSuccesses + 1
        local created = tonumber(result.createdNPCs) or 0
        Director.Metrics.npcRecordsCreated = Director.Metrics.npcRecordsCreated + created
        Director.RateHistory[kind][#Director.RateHistory[kind] + 1] = now
        if kind == "SETTLEMENT" and result.community
            and Starter and Starter.IsPending and Starter.IsPending()
        then
            Starter.MarkCommitted(result.community, now)
        end
        Log.Info(kind .. "_GENERATION_COMMITTED", { sectorId = request.sectorId,
            generationId = plan.generationId, seed = plan.seed,
            archetype = plan.archetype or plan.factionArchetypeId,
            entityId = result.group and result.group.id
                or result.community and result.community.id,
            createdNPCs = created, liveNPCs = result.liveNPCs or 0,
            abstractNPCs = result.abstractNPCs or 0,
            presenceMode = "auto" })
        return 1, remainingNPCs - created
    end
    Sectors.SetSuppression(request.sectorId, kind, result.reason)
    Sectors.AddHistory(kind .. "_GENERATION_FAILED", {
        sectorId = request.sectorId, generationId = plan.generationId,
        reason = result.reason, seed = plan.seed }, now)
    Director.Metrics.queueFailures = Director.Metrics.queueFailures + 1
    Store.Emit(kind .. "_GENERATION_FAILED", { sectorId = request.sectorId,
        generationId = plan.generationId, reason = result.reason })
    Log.Warn("GENERATION_COMMIT_FAILED", { kind = kind,
        sectorId = request.sectorId, generationId = plan.generationId,
        seed = plan.seed, reason = result.reason })
    return 1, remainingNPCs
end

local function processQueues(now, allowDuringGrace, npcBudget)
    if Director.Paused or PNC.WorldDirector and PNC.WorldDirector.Paused
        or now < Director.StartupGraceUntil and allowDuringGrace ~= true
    then return 0 end
    local startedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local remaining = math.max(1, math.floor(tonumber(npcBudget)
        or Config.HARD_MAX_NPC_RECORDS_PER_PUMP))
    local processed = 0
    local starterPending = Starter and Starter.IsPending
        and Starter.IsPending() or false
    if starterPending and remaining > 0 then
        for _ = 1, Config.HARD_MAX_SETTLEMENT_CREATIONS_PER_PUMP do
            local count
            count, remaining = processRequest("SETTLEMENT", now, remaining)
            processed = processed + count
            if remaining <= 0 then break end
        end
    end
    for _ = 1, Config.HARD_MAX_GROUP_CREATIONS_PER_PUMP do
        local count
        count, remaining = processRequest("GROUP", now, remaining)
        processed = processed + count
        if remaining <= 0 then break end
    end
    if not starterPending and remaining > 0 then
        for _ = 1, Config.HARD_MAX_SETTLEMENT_CREATIONS_PER_PUMP do
            local count
            count, remaining = processRequest("SETTLEMENT", now, remaining)
            processed = processed + count
            if remaining <= 0 then break end
        end
    end
    Director.Metrics.queueRuns = Director.Metrics.queueRuns + 1
    local elapsed = math.max(0, (PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or startedAt) - startedAt)
    Director.Metrics.processingRuns = Director.Metrics.processingRuns + 1
    Director.Metrics.totalProcessingMS = Director.Metrics.totalProcessingMS + elapsed
    Director.Metrics.maxProcessingMS = math.max(
        Director.Metrics.maxProcessingMS, elapsed)
    return processed
end

local function ensureStarterPopulation(now, forceProbe)
    if not Starter or not Starter.IsPending or not Starter.IsPending() then
        return 0, "starter_ready"
    end
    local runtimeNow = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if forceProbe ~= true
        and runtimeNow < (tonumber(Director.NextStarterRuntimeProbeAt) or 0)
    then
        return 0, "probe_throttled"
    end
    Director.NextStarterRuntimeProbeAt = runtimeNow
        + Config.STARTER_RUNTIME_RETRY_MS
    refresh(now)
    if #Sectors.PlayerPositions == 0 then return 0, "waiting_for_player" end
    local queued, reason = Starter.Run(now)
    if not queued then return 0, reason end
    return processQueues(now, true, Config.STARTER_NPC_RECORD_BUDGET), reason
end

Internal.processRequest = processRequest
Internal.processQueues = processQueues
Internal.ensureStarterPopulation = ensureStarterPopulation
