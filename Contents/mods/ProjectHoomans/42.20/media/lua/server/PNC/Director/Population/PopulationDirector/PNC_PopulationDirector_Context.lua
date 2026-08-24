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
local Log = PNC.PopulationLog

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

Internal.releaseLegacyPresenceOverrides = releaseLegacyPresenceOverrides
Internal.rateAllowed = rateAllowed
Internal.context = context
Internal.refresh = refresh
