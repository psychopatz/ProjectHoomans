-- Population orchestration only: jobs, budgets, queues, metrics, pause state.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.PopulationDirector = PNC.PopulationDirector or {}

local Director = PNC.PopulationDirector
local Config = PNC.DirectorConfig.Population
local Store = PNC.AbstractWorldStore
local Sectors = PNC.PopulationSectors
local Queue = PNC.GenerationQueue
local Scheduler = PNC.Scheduler
local Log = PNC.PopulationLog
local Starter = PNC.StarterPopulation

Director.Initialized = Director.Initialized or false
Director.Paused = Director.Paused or false
Director.StartupGraceUntil = Director.StartupGraceUntil or 0
Director.DryRunPending = Director.DryRunPending or { GROUP = true, SETTLEMENT = true }
Director.BootstrapPhase = Director.BootstrapPhase or "WAITING_DRY"
Director.LastResolved = Director.LastResolved or nil
Director.Metrics = Director.Metrics or { queueRuns = 0, queueFailures = 0,
    queueSuccesses = 0, npcRecordsCreated = 0, processingRuns = 0,
    totalProcessingMS = 0, maxProcessingMS = 0 }
Director.RateHistory = Director.RateHistory or { GROUP = {}, SETTLEMENT = {} }
Director.NextStarterRuntimeProbeAt = Director.NextStarterRuntimeProbeAt or 0

local function releaseLegacyPresenceOverrides()
    local released = 0
    for _, record in pairs(PNC.Registry and PNC.Registry.Data or {}) do
        local source = record.generation and tostring(
            record.generation.source or "") or ""
        if string.sub(source, 1, 16) == "WORLD_POPULATION"
            and record.runtime and record.runtime.forceAbstract == true
        then
            record.runtime.forceAbstract = nil
            record.runtime.forcePresenceCheck = true
            if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
                PNC.SpatialIndex.UpdateNPC(record)
            end
            if PNC.Registry.MarkDirty then
                PNC.Registry.MarkDirty(record,
                    "population_presence_policy_migrated")
            end
            released = released + 1
        end
    end
    if released > 0 then
        Log.Info("LEGACY_PRESENCE_OVERRIDE_RELEASED", { records = released })
    end
    return released
end

local function rateAllowed(kind, now)
    local history = Director.RateHistory[kind]
    local window = kind == "SETTLEMENT" and 24 or 1
    local limit = kind == "SETTLEMENT"
        and Config.HARD_MAX_SETTLEMENT_CREATIONS_PER_DAY
        or Config.HARD_MAX_GROUP_CREATIONS_PER_HOUR
    for index = #history, 1, -1 do
        if history[index] <= now - window then table.remove(history, index) end
    end
    return #history < limit
end

local function context(now)
    local active = 0
    for _, runtime in pairs(Sectors.Runtime) do
        if runtime.active then active = active + 1 end
    end
    local resolved = PNC.PopulationSandbox.Resolve()
    local signature = table.concat({ resolved.populationOption,
        resolved.settlementOption, resolved.roamingGroupOption,
        resolved.regenerationOption, resolved.settlementRegenerationOption,
        resolved.multiplayerOption, resolved.generationDistanceOption }, ":")
    if Director.ResolvedSignature and Director.ResolvedSignature ~= signature then
        Store.Emit("POPULATION_BUDGET_CHANGED", { previous = Director.ResolvedSignature,
            current = signature })
        Log.Info("SANDBOX_SETTINGS_CHANGED", { previous = Director.ResolvedSignature,
            current = signature })
    end
    Director.ResolvedSignature = signature
    Director.LastResolved = resolved
    return { worldAge = now, resolved = Director.LastResolved,
        playerCount = #Sectors.PlayerPositions, activeSectorCount = active }
end

local function refresh(now)
    local previousPlayers = #Sectors.PlayerPositions
    local previousActive = 0
    for _, runtime in pairs(Sectors.Runtime) do
        if runtime.active then previousActive = previousActive + 1 end
    end
    Sectors.RefreshPlayers()
    PNC.SettlementCandidates.Expire(now)
    local discovered = 0
    for _, position in ipairs(Sectors.PlayerPositions) do
        discovered = discovered + PNC.AbstractLocations.DiscoverLoadedNear(
            position.x, position.y, position.z,
            Config.SECTOR_SIZE * 0.75,
            Config.CANDIDATE_EVALUATION_BUDGET)
    end
    if discovered > 0 then
        Log.Info("LOADED_SITES_DISCOVERED", { count = discovered })
    end
    local active = 0
    for _, runtime in pairs(Sectors.Runtime) do
        if runtime.active then active = active + 1 end
    end
    if previousPlayers ~= #Sectors.PlayerPositions or previousActive ~= active then
        Log.Info("PLAYER_FOOTPRINT_CHANGED", { players = #Sectors.PlayerPositions,
            activeSectors = active })
    end
    return #Sectors.PlayerPositions
end

local function reconcile(kind, now, budget, forceDry)
    if Director.Paused or PNC.WorldDirector and PNC.WorldDirector.Paused then return 0 end
    local ctx = context(now)
    if not ctx.resolved.enabled then
        return 0
    end
    local dry
    if forceDry ~= nil then
        dry = forceDry == true
    else
        dry = now < Director.StartupGraceUntil
        if not dry and Director.DryRunPending[kind] then
            dry = true
            Director.DryRunPending[kind] = false
        end
    end
    return PNC.PopulationReconciler.Run(kind, now, budget, ctx, dry)
end

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

local function bootstrap(now, budget)
    refresh(now)
    if Director.BootstrapPhase == "WAITING_DRY" then
        local groupCursor = PNC.PopulationReconciler.Cursors.GROUP
        local settlementCursor = PNC.PopulationReconciler.Cursors.SETTLEMENT
        local processed = reconcile("GROUP", now, budget, true)
            + reconcile("SETTLEMENT", now, budget, true)
        -- The live bootstrap pass must revisit exactly what the dry pass
        -- diagnosed instead of advancing to a disjoint rotating batch.
        PNC.PopulationReconciler.Cursors.GROUP = groupCursor
        PNC.PopulationReconciler.Cursors.SETTLEMENT = settlementCursor
        Director.DryRunPending = { GROUP = false, SETTLEMENT = false }
        Director.BootstrapPhase = "WAITING_GENERATION"
        Log.Info("BOOTSTRAP_DRY_RECONCILIATION", { processed = processed,
            nextInHours = Config.BOOTSTRAP_RECONCILE_DELAY_HOURS })
        return processed
    end
    if Starter and Starter.IsPending and Starter.IsPending() then
        Starter.Run(now)
    end
    local processed = reconcile("GROUP", now, budget, false)
        + reconcile("SETTLEMENT", now, budget, false)
    Director.BootstrapPhase = "COMPLETE"
    Scheduler.SetJobEnabled("PopulationBootstrapReconciliation", false)
    Log.Info("BOOTSTRAP_GENERATION_RECONCILIATION", { processed = processed,
        pendingGroups = Queue.Count("GROUP"),
        pendingSettlements = Queue.Count("SETTLEMENT") })
    return processed
end

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

function Director.OnGroupDestroyed(payload)
    payload = payload or {}
    local _, sectorID = Sectors.UnregisterGroup(payload.groupId)
    sectorID = sectorID or payload.sectorId
    if not sectorID then return false end
    if payload.homeCommunityId then
        Sectors.AddHistory("COMMUNITY_GROUP_DESTROYED", {
            groupId = payload.groupId, communityId = payload.homeCommunityId,
            sectorId = sectorID, reason = payload.reason }, Store.WorldAgeHours())
        return true
    end
    if payload.factionId and PNC.Factions and PNC.Factions.ClearMobileGroup then
        PNC.Factions.ClearMobileGroup(payload.factionId,
            "population_group_destroyed")
    end
    local state = Sectors.Ensure(sectorID)
    local resolved = Director.LastResolved or PNC.PopulationSandbox.Resolve()
    state.groupGenerationCooldownUntil = resolved.groupRegenerationEnabled
        and Store.WorldAgeHours() + Config.GROUP_REGENERATION_COOLDOWN_HOURS
            / math.max(0.25, resolved.groupRegenerationMultiplier)
        or 2147483647
    Store.Touch("population_group_destroyed")
    Sectors.AddHistory("GROUP_DESTROYED", { groupId = payload.groupId,
        sectorId = sectorID, reason = payload.reason }, Store.WorldAgeHours())
    Log.Info("GROUP_DESTROYED", { groupId = payload.groupId,
        sectorId = sectorID, reason = payload.reason,
        cooldownUntil = state.groupGenerationCooldownUntil })
    return true
end

function Director.OnSettlementDestroyed(community, reason, at)
    if not community then return false end
    if reason == "site_reservation_failed" or reason == "group_generation_failed"
        or reason == "population_generation_rollback" then return false end
    at = tonumber(at) or Store.WorldAgeHours()
    local _, sectorID = Sectors.UnregisterCommunity(community.id)
    local home = community.home or community.site and community.site.home
    sectorID = sectorID or home and Sectors.IDForPosition(home.x, home.y)
    if not sectorID then return false end
    local state = Sectors.Ensure(sectorID)
    local resolved = Director.LastResolved or PNC.PopulationSandbox.Resolve()
    state.settlementGenerationCooldownUntil = resolved.settlementRegenerationEnabled
        and at + Config.SETTLEMENT_REGENERATION_COOLDOWN_HOURS
            / math.max(0.25, resolved.settlementRegenerationMultiplier)
        or 2147483647
    for _, group in ipairs(PNC.AbstractGroups.List()) do
        if group.homeCommunityId == community.id then
            PNC.AbstractGroups.Remove(group.id, "home_settlement_destroyed")
        end
    end
    local siteID = community.siteID or community.site and community.site.id
    local location
    for _, candidate in ipairs(PNC.AbstractLocations.List()) do
        if candidate.sourceSite and candidate.sourceSite.id == siteID then
            location = candidate break
        end
    end
    if location then
        local history = { formerSettlement = true, destroyedAt = at,
            regenerationBlockedUntil = at + Config.SITE_REGENERATION_COOLDOWN_HOURS }
        Store.Registry.population.siteHistory[location.id] = history
        location.populationHistory = history
        location.type = "BUILDING"
        if location.tags then location.tags.SETTLEMENT = nil end
    end
    Store.Touch("population_settlement_destroyed")
    Sectors.AddHistory("SETTLEMENT_DESTROYED", { communityId = community.id,
        sectorId = sectorID, locationId = location and location.id,
        reason = reason }, at)
    Store.Emit("SETTLEMENT_DESTROYED", { communityId = community.id,
        sectorId = sectorID, locationId = location and location.id,
        reason = reason })
    Log.Info("SETTLEMENT_DESTROYED", { communityId = community.id,
        sectorId = sectorID, locationId = location and location.id,
        reason = reason,
        cooldownUntil = state.settlementGenerationCooldownUntil })
    return true
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

return Director
