-- Server-authoritative orchestration only; domain work remains in focused modules.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.WorldDirector = PNC.WorldDirector or {}

local Director = PNC.WorldDirector
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Traversal = PNC.AbstractTraversal
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
    for _, group in ipairs(Groups.List()) do Groups.RefreshLOD(group, now) end
    Locations.ReconcileOccupancy()
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
    return Scheduler.PumpJobs(Store.WorldAgeHours())
end

function Director.ForceUpdate(groupID)
    Director.Initialize()
    local at = Store.WorldAgeHours()
    if groupID then
        local group = Groups.Get(groupID)
        if not group then return false, "group_not_found" end
        Traversal.Advance(group, at)
        return true, "group_updated"
    end
    reconcile(at, Config.DIRECTOR_JOB_BUDGET)
    Traversal.AdvanceTravelBatch(at, Config.DIRECTOR_JOB_BUDGET)
    Traversal.DecideBatch(at, Config.DIRECTOR_JOB_BUDGET)
    return true, "director_updated"
end

function Director.SetPaused(paused)
    Director.Paused = paused == true
    return Director.Paused
end

function Director.GetMetrics()
    Director.Initialize()
    local groups = Groups.List()
    local locations = Locations.List()
    local traveling, materialized = 0, 0
    for _, group in ipairs(groups) do
        if group.state == "TRAVELING" then traveling = traveling + 1 end
        if group.state == "ACTIVE" then materialized = materialized + 1 end
    end
    return {
        groups = #groups, locations = #locations,
        traveling = traveling, materialized = materialized,
        encounters = #Store.Registry.encounters,
        scheduledJobs = #Scheduler.GetJobs(), paused = Director.Paused,
        registryRevision = Store.Registry.revision,
        dirty = Store.Dirty == true,
    }
end

Director.SyncMobileGroups = syncMobileGroups
Director.SyncCommunities = syncCommunities

return Director
