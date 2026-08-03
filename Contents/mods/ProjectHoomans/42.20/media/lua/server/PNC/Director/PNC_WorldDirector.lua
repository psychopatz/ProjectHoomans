-- Server-authoritative orchestration only; domain work remains in focused modules.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.WorldDirector = PNC.WorldDirector or {}

local Director = PNC.WorldDirector
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Traversal = PNC.AbstractTraversal
local Actions = PNC.AbstractActions
local EncounterResolver = PNC.AbstractEncounterResolver
local CombatResolver = PNC.AbstractCombatResolver
local Scheduler = PNC.Scheduler
local Config = PNC.DirectorConfig

Director.Initialized = Director.Initialized or false
Director.Paused = Director.Paused or false

local function syncCommunities()
    local registered = 0
    if not PNC.Communities or not PNC.Communities.ListSites then return 0 end
    for _, site in ipairs(PNC.Communities.ListSites()) do
        if site.occupantCommunityID then
            local location, reason = Locations.RegisterSite(site, {
                type = "SETTLEMENT",
                tags = { SETTLEMENT = true, FRIENDLY = true,
                    SAFE = true, FOOD = true, WATER = true },
                resourcePotential = { food = 45, water = 55,
                    medical = 20, materials = 25 },
            })
            if location and reason == "registered" then registered = registered + 1 end
        end
    end
    return registered
end

local function syncMobileGroups()
    local imported = 0
    if not PNC.Factions or not PNC.Factions.List then return 0 end
    for _, faction in ipairs(PNC.Factions.List()) do
        if PNC.Factions.IsMobileGroup(faction) then
            local group, reason = Groups.ImportMobileFaction(faction)
            if group and reason == "created" then imported = imported + 1 end
        end
    end
    return imported
end

local function reconcile(_, budget)
    syncCommunities()
    local groups = Groups.List()
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.DIRECTOR_JOB_BUDGET))
    local checked = 0
    for _, group in ipairs(groups) do
        if checked >= budget then break end
        Groups.ReconcileMembers(group)
        checked = checked + 1
    end
    syncMobileGroups()
    return checked
end

function Director.Initialize(force)
    if Director.Initialized and force ~= true then return true, "initialized" end
    Store.EnsureLoaded()
    if PNC.Factions and PNC.Factions.EnsureLoaded then PNC.Factions.EnsureLoaded() end
    if PNC.Communities and PNC.Communities.EnsureLoaded then
        PNC.Communities.EnsureLoaded()
    end
    Locations.RebuildIndex()
    syncCommunities()
    syncMobileGroups()
    local now = Store.WorldAgeHours()
    for _, group in ipairs(Groups.List()) do
        group.activeEncounterId = nil
        PNC.AbstractBehaviorProfile.Get(group, false)
        Groups.RefreshLOD(group, now)
    end
    Locations.ReconcileOccupancy()
    if PNC.PopulationDirector and PNC.PopulationDirector.Initialize then
        PNC.PopulationDirector.Initialize(force)
    end
    for _, report in ipairs(Store.Registry.encounters) do
        if report.outcome == "QUEUED" then EncounterResolver.Enqueue(report) end
    end
    Scheduler.RegisterJob("AbstractTraversal", Config.TRAVERSAL_INTERVAL_HOURS,
        function(at, budget)
            if Director.Paused then return 0 end
            return Traversal.AdvanceTravelBatch(at, budget)
        end,
        { budget = Config.DIRECTOR_JOB_BUDGET,
            startAt = now + Config.TRAVERSAL_INTERVAL_HOURS })
    Scheduler.RegisterJob("AbstractGroupDecision", Config.DECISION_INTERVAL_HOURS,
        function(at, budget)
            if Director.Paused then return 0 end
            return Traversal.DecideBatch(at, budget)
        end,
        { budget = Config.DIRECTOR_JOB_BUDGET,
            startAt = now + Config.DECISION_INTERVAL_HOURS })
    Scheduler.RegisterJob("AbstractActions", Config.ACTION_INTERVAL_HOURS,
        function(at, budget)
            if Director.Paused then return 0 end
            return Actions.AdvanceBatch(at, budget)
        end,
        { budget = Config.DIRECTOR_JOB_BUDGET,
            startAt = now + Config.ACTION_INTERVAL_HOURS })
    Scheduler.RegisterJob("AbstractEncounterQueue", Config.ENCOUNTER_INTERVAL_HOURS,
        function(at, budget)
            if Director.Paused then return 0 end
            return EncounterResolver.ProcessBatch(at, budget)
        end,
        { budget = Config.EncounterQueue.WORK_BUDGET,
            startAt = now + Config.ENCOUNTER_INTERVAL_HOURS })
    Scheduler.RegisterJob("AbstractReconciliation", Config.RECONCILE_INTERVAL_HOURS,
        function(at, budget)
            if Director.Paused then return 0 end
            return reconcile(at, budget)
        end,
        { budget = Config.DIRECTOR_JOB_BUDGET,
            startAt = now + Config.RECONCILE_INTERVAL_HOURS })
    Director.Initialized = true
    return true, "initialized"
end

function Director.Pump()
    if not Director.Initialized then Director.Initialize() end
    if PNC.PopulationDirector and PNC.PopulationDirector.Pump then
        PNC.PopulationDirector.Pump(Store.WorldAgeHours())
    end
    return Scheduler.PumpJobs(Store.WorldAgeHours())
end

function Director.ForceUpdate(groupID)
    Director.Initialize()
    local at = Store.WorldAgeHours()
    if groupID then
        local group = Groups.Get(groupID)
        if not group then return false, "group_not_found" end
        Traversal.Advance(group, at)
        if group.action and at >= (tonumber(group.action.endsAt) or 0) then
            Actions.Complete(group, at, false)
        end
        EncounterResolver.ProcessBatch(at, 1)
        return true, "group_updated"
    end
    reconcile(at, Config.DIRECTOR_JOB_BUDGET)
    Traversal.AdvanceTravelBatch(at, Config.DIRECTOR_JOB_BUDGET)
    Traversal.DecideBatch(at, Config.DIRECTOR_JOB_BUDGET)
    Actions.AdvanceBatch(at, Config.DIRECTOR_JOB_BUDGET)
    EncounterResolver.ProcessBatch(at, Config.EncounterQueue.WORK_BUDGET)
    return true, "director_updated"
end

function Director.SetPaused(paused)
    Director.Paused = paused == true
    if PNC.PopulationDirector and PNC.PopulationDirector.SetPaused then
        PNC.PopulationDirector.SetPaused(Director.Paused)
    end
    return Director.Paused
end

function Director.GetMetrics()
    Director.Initialize()
    local groups = Groups.List()
    local locations = Locations.List()
    local traveling, materialized, activeActions, engaged = 0, 0, 0, 0
    for _, group in ipairs(groups) do
        if group.state == "TRAVELING" then traveling = traveling + 1 end
        if group.state == "ACTIVE" then materialized = materialized + 1 end
        if group.action then activeActions = activeActions + 1 end
        if group.activeEncounterId then engaged = engaged + 1 end
    end
    local population = PNC.PopulationDirector
        and PNC.PopulationDirector.GetMetrics
        and PNC.PopulationDirector.GetMetrics() or nil
    return {
        groups = #groups, locations = #locations,
        traveling = traveling, materialized = materialized,
        encounters = #Store.Registry.encounters,
        activeActions = activeActions, engaged = engaged,
        actionsStarted = Actions.Metrics.started,
        actionsCompleted = Actions.Metrics.completed,
        encountersQueued = #EncounterResolver.Queue,
        encountersResolved = EncounterResolver.Metrics.resolved,
        abstractCombats = CombatResolver.Metrics.combats,
        abstractRetreats = CombatResolver.Metrics.retreats,
        casualties = CombatResolver.Metrics.casualties,
        profileInvalidations = Groups.Metrics.profileInvalidations,
        averageEncounterProcessingMS = EncounterResolver.Metrics.processingRuns > 0
            and EncounterResolver.Metrics.totalProcessingMS
                / EncounterResolver.Metrics.processingRuns or 0,
        scheduledJobs = #Scheduler.GetJobs(), paused = Director.Paused,
        registryRevision = Store.Registry.revision,
        dirty = Store.Dirty == true,
        population = population,
    }
end

Director.SyncMobileGroups = syncMobileGroups
Director.SyncCommunities = syncCommunities

return Director
