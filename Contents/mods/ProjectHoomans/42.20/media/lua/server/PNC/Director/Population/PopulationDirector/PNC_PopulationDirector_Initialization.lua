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
local Scheduler = PNC.Scheduler
local Log = PNC.PopulationLog
local Starter = PNC.StarterPopulation
local releaseLegacyPresenceOverrides = Internal.releaseLegacyPresenceOverrides
local context = Internal.context
local refresh = Internal.refresh
local reconcile = Internal.reconcile
local processQueues = Internal.processQueues
local ensureStarterPopulation = Internal.ensureStarterPopulation
local bootstrap = Internal.bootstrap

function Director.Initialize(force)
    if Director.Initialized and force ~= true then return true, "initialized" end
    Store.EnsureLoaded()
    releaseLegacyPresenceOverrides()
    local metadataMigrated = PNC.PopulationIdentity
        and PNC.PopulationIdentity.MigrateLegacyMetadata
        and PNC.PopulationIdentity.MigrateLegacyMetadata() or 0
    if metadataMigrated > 0 then
        Log.Info("LEGACY_POPULATION_METADATA_MIGRATED", {
            records = metadataMigrated })
    end
    Queue.Clear()
    Director.RateHistory = { GROUP = {}, SETTLEMENT = {} }
    local recentGenerations = {}
    local now = Store.WorldAgeHours()
    for _, provenance in pairs(Store.Registry.population.provenance or {}) do
        if not recentGenerations[provenance.generationId] then
            recentGenerations[provenance.generationId] = true
            local createdAt = tonumber(provenance.createdAt) or 0
            if string.find(provenance.generationId, "^POP_GROUP_")
                and createdAt > now - 1 then
                Director.RateHistory.GROUP[#Director.RateHistory.GROUP + 1] = createdAt
            elseif string.find(provenance.generationId, "^POP_SETTLEMENT_")
                and createdAt > now - 24 then
                Director.RateHistory.SETTLEMENT[
                    #Director.RateHistory.SETTLEMENT + 1] = createdAt
            end
        end
    end
    Sectors.RebuildIndexes()
    PNC.SettlementCandidates.Rebuild()
    refresh(Store.WorldAgeHours())
    Starter.Initialize(now)
    Director.StartupGraceUntil = now + Config.STARTUP_GRACE_HOURS
    Director.DryRunPending = { GROUP = true, SETTLEMENT = true }
    Director.BootstrapPhase = "WAITING_DRY"
    ensureStarterPopulation(now, true)
    Scheduler.RegisterJob("PopulationBootstrapReconciliation",
        Config.BOOTSTRAP_RECONCILE_DELAY_HOURS, bootstrap,
        { budget = Config.RECONCILE_SECTOR_BUDGET,
            startAt = Director.StartupGraceUntil })
    Scheduler.RegisterJob("PopulationSectorRefresh",
        Config.ACTIVE_SECTOR_REFRESH_HOURS, refresh,
        { budget = 1, startAt = now + Config.ACTIVE_SECTOR_REFRESH_HOURS })
    Scheduler.RegisterJob("PopulationGroupReconciliation",
        Config.GROUP_RECONCILE_HOURS,
        function(at, budget) return reconcile("GROUP", at, budget) end,
        { budget = Config.RECONCILE_SECTOR_BUDGET,
            startAt = now + Config.GROUP_RECONCILE_HOURS })
    Scheduler.RegisterJob("PopulationSettlementReconciliation",
        Config.SETTLEMENT_RECONCILE_HOURS,
        function(at, budget) return reconcile("SETTLEMENT", at, budget) end,
        { budget = Config.RECONCILE_SECTOR_BUDGET,
            startAt = now + Config.SETTLEMENT_RECONCILE_HOURS })
    Scheduler.RegisterJob("PopulationGenerationQueue",
        Config.GENERATION_QUEUE_HOURS, processQueues,
        { budget = 1, startAt = Director.StartupGraceUntil
            + Config.BOOTSTRAP_RECONCILE_DELAY_HOURS })
    Scheduler.RegisterJob("PopulationStarterSettlement",
        Config.STARTER_RETRY_HOURS,
        function(at)
            if Director.Paused or PNC.WorldDirector and PNC.WorldDirector.Paused
                or not Starter.IsPending() then return 0 end
            local queued = Starter.Run(at)
            return queued and 1 or 0
        end,
        { budget = 1, startAt = Director.StartupGraceUntil
            + Config.BOOTSTRAP_RECONCILE_DELAY_HOURS
            + Config.STARTER_RETRY_HOURS })
    Scheduler.RegisterJob("PopulationIndexRepair", Config.INDEX_REPAIR_HOURS,
        function(_, budget) return Sectors.Repair(budget) end,
        { budget = Config.INDEX_REPAIR_BUDGET,
            startAt = now + Config.INDEX_REPAIR_HOURS })
    Scheduler.RegisterJob("PopulationCommunityGroupFormation",
        Config.COMMUNITY_GROUP_RECONCILE_HOURS,
        function(at, budget)
            if Director.Paused or PNC.WorldDirector and PNC.WorldDirector.Paused then
                return 0
            end
            return PNC.CommunityGroupFormation.Reconcile(at, budget)
        end,
        { budget = 1, startAt = now + Config.COMMUNITY_GROUP_RECONCILE_HOURS })
    if not Director.ListenersRegistered then
        Store.RegisterListener("GROUP_DESTROYED", function(payload)
            Director.OnGroupDestroyed(payload)
        end)
        Director.ListenersRegistered = true
    end
    Director.Initialized = true
    local resolved = context(now).resolved
    local populationSeed, worldSeed = Sectors.WorldSeed()
    Log.Info("INITIALIZED", { players = #Sectors.PlayerPositions,
        startupGraceUntil = Director.StartupGraceUntil,
        populationOption = resolved.populationOption,
        groupOption = resolved.roamingGroupOption,
        settlementOption = resolved.settlementOption,
        minimumDistance = resolved.minPlayerGenerationDistance,
        populationSeed = populationSeed, worldSeed = worldSeed,
        starterPending = Starter.IsPending() })
    return true, "initialized"
end
