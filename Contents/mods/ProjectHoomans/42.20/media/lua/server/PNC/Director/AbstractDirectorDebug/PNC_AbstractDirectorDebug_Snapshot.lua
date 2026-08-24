if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Debug = PNC.AbstractDirectorDebug
local H = Debug.Internal
local Director = PNC.WorldDirector
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Combat = PNC.AbstractCombatProfile
local Traversal = PNC.AbstractTraversal
local Store = PNC.AbstractWorldStore
local Actions = PNC.AbstractActions
local Behavior = PNC.AbstractBehaviorProfile
local ResourceNeeds = PNC.AbstractResourceNeeds
local Encounters = PNC.AbstractEncounters
local EncounterResolver = PNC.AbstractEncounterResolver
local Core = PNC.Core

function Debug.BuildSnapshot(selectedGroupID, selectedLocationID, action,
    requestedSectorID)
    Director.Initialize()
    local groups, locations = {}, {}
    local selected = Groups.Get(selectedGroupID) or Groups.List()[1]
    for _, group in ipairs(Groups.List()) do
        groups[#groups + 1] = H.GroupSummary(group, selected and group.id == selected.id)
    end
    local selectedLocation = Locations.Get(selectedLocationID)
        or selected and Locations.Get(selected.location.id) or Locations.List()[1]
    for _, location in ipairs(Locations.List()) do
        locations[#locations + 1] = H.LocationSummary(location)
    end
    local populationSectors = PNC.PopulationSectors
        and PNC.PopulationSectors.ListRelevant() or {}
    local selectedSectorID = PNC.PopulationSectors
        and PNC.PopulationSectors.Get(requestedSectorID)
        and requestedSectorID
        or selectedLocation and PNC.PopulationSectors
        and PNC.PopulationSectors.IDForPosition(
            selectedLocation.x, selectedLocation.y)
        or populationSectors[1] and populationSectors[1].id
    for _, sector in ipairs(populationSectors) do
        sector.pendingGroups = PNC.GenerationQueue.CountForSector(
            "GROUP", sector.id)
        sector.pendingSettlements = PNC.GenerationQueue.CountForSector(
            "SETTLEMENT", sector.id)
        sector.candidatePool = PNC.SettlementCandidates.PoolCount(sector.id)
        sector.groupCooldownRemaining = math.max(0,
            (tonumber(sector.groupGenerationCooldownUntil) or 0)
                - Store.WorldAgeHours())
        sector.settlementCooldownRemaining = math.max(0,
            (tonumber(sector.settlementGenerationCooldownUntil) or 0)
                - Store.WorldAgeHours())
    end
    return {
        metrics = Director.GetMetrics(), groups = groups, locations = locations,
        selectedGroupId = selected and selected.id,
        selectedLocationId = selectedLocation and selectedLocation.id,
        jobs = H.Copy(PNC.Scheduler.GetJobs()),
        recentEncounters = H.Copy(Store.Registry.encounters),
        generatedAt = Store.WorldAgeHours(), action = H.Copy(action),
        population = {
            metrics = PNC.PopulationDirector
                and PNC.PopulationDirector.GetMetrics() or {},
            resolved = H.Copy(PNC.PopulationDirector
                and PNC.PopulationDirector.LastResolved
                or PNC.PopulationSandbox and PNC.PopulationSandbox.Resolve() or {}),
            sectors = H.Copy(populationSectors),
            selectedSectorId = selectedSectorID,
            starter = H.Copy(PNC.StarterPopulation
                and PNC.StarterPopulation.GetDebugSnapshot
                and PNC.StarterPopulation.GetDebugSnapshot() or {}),
            queue = H.Copy(PNC.GenerationQueue
                and PNC.GenerationQueue.Snapshot
                and PNC.GenerationQueue.Snapshot(Store.WorldAgeHours()) or {}),
            reservations = H.Copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.ReservationSnapshot
                and PNC.SettlementCandidates.ReservationSnapshot(
                    Store.WorldAgeHours()) or {}),
            selectedDiscovery = H.Copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.LastMetaDiscovery
                and PNC.SettlementCandidates.LastMetaDiscovery[
                    selectedSectorID] or {}),
            store = { revision = Store.Registry.revision,
                dirty = Store.Dirty == true,
                lastMutationReason = Store.LastMutationReason },
            history = H.Copy(PNC.PopulationSectors
                and PNC.PopulationSectors.History or {}),
            log = H.Copy(PNC.PopulationLog
                and PNC.PopulationLog.GetEntries
                and PNC.PopulationLog.GetEntries() or {}),
            candidateMetrics = H.Copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.Metrics or {}),
            candidateEvaluations = H.Copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.LastEvaluations
                and PNC.SettlementCandidates.LastEvaluations[selectedSectorID]
                or {}),
        },
    }
end
