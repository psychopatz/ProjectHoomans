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
local reconcile = Internal.reconcile
local processQueues = Internal.processQueues
local ensureStarterPopulation = Internal.ensureStarterPopulation

function Director.RequestReconciliation(kind, sectorID, now)
    now = tonumber(now) or Store.WorldAgeHours()
    if sectorID then Sectors.MarkRelevant(sectorID, true) end
    return reconcile(kind == "SETTLEMENT" and "SETTLEMENT" or "GROUP",
        now, Config.RECONCILE_SECTOR_BUDGET)
end

function Director.ProcessQueues(now) return processQueues(now or Store.WorldAgeHours()) end

function Director.Pump(now)
    if not Director.Initialized then Director.Initialize() end
    return ensureStarterPopulation(tonumber(now) or Store.WorldAgeHours(), false)
end

function Director.ProcessStarterPopulation(now)
    return ensureStarterPopulation(tonumber(now) or Store.WorldAgeHours(), true)
end

function Director.SetPaused(paused)
    Director.Paused = paused == true
    Log.Info("PAUSE_CHANGED", { paused = Director.Paused })
    return Director.Paused
end

function Director.ClearCooldown(sectorID, kind)
    local state = Sectors.Ensure(sectorID)
    if not state then return false, "invalid_sector" end
    if kind == "SETTLEMENT" then state.settlementGenerationCooldownUntil = 0
    else state.groupGenerationCooldownUntil = 0 end
    Store.Touch("population_cooldown_cleared")
    Log.Info("COOLDOWN_CLEARED", { kind = kind or "GROUP",
        sectorId = sectorID })
    return true, "cooldown_cleared"
end

function Director.GetMetrics()
    local desiredGroups, currentGroups, desiredSettlements, currentSettlements = 0, 0, 0, 0
    local active = 0
    for _, sector in ipairs(Sectors.ListRelevant()) do
        desiredGroups = desiredGroups + (sector.desiredGroups or 0)
        desiredSettlements = desiredSettlements + (sector.desiredSettlements or 0)
        currentGroups = currentGroups + sector.groupCount
        currentSettlements = currentSettlements + sector.settlementCount
        if sector.active then active = active + 1 end
    end
    return {
        enabled = (Director.LastResolved or PNC.PopulationSandbox.Resolve()).enabled,
        paused = Director.Paused, players = #Sectors.PlayerPositions,
        activeSectors = active, desiredGroups = desiredGroups,
        currentGroups = currentGroups,
        groupDeficit = math.max(0, desiredGroups - currentGroups),
        desiredSettlements = desiredSettlements,
        currentSettlements = currentSettlements,
        settlementDeficit = math.max(0, desiredSettlements - currentSettlements),
        pendingGroups = Queue.Count("GROUP"),
        pendingSettlements = Queue.Count("SETTLEMENT"),
        bootstrapPhase = Director.BootstrapPhase,
        starter = Starter and Starter.GetDebugSnapshot
            and Starter.GetDebugSnapshot() or nil,
        startupGraceUntil = Director.StartupGraceUntil,
        indexMismatches = Sectors.Metrics.mismatches,
        queueHighWaterGroups = Queue.HighWater.GROUP,
        queueHighWaterSettlements = Queue.HighWater.SETTLEMENT,
        groupAttempts = PNC.GroupGenerator.Metrics.attempts,
        groupSuccesses = PNC.GroupGenerator.Metrics.successes,
        groupFailures = PNC.GroupGenerator.Metrics.failures,
        settlementAttempts = PNC.SettlementGenerator.Metrics.attempts,
        settlementSuccesses = PNC.SettlementGenerator.Metrics.successes,
        settlementFailures = PNC.SettlementGenerator.Metrics.failures,
        candidateEvaluations = PNC.SettlementCandidates.Metrics.evaluated,
        npcRecordsCreated = Director.Metrics.npcRecordsCreated,
        averageProcessingMS = Director.Metrics.processingRuns > 0
            and Director.Metrics.totalProcessingMS / Director.Metrics.processingRuns or 0,
        maxProcessingMS = Director.Metrics.maxProcessingMS,
    }
end
