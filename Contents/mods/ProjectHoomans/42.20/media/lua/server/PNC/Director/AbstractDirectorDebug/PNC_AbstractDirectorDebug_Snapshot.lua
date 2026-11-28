if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Debug = PNC.AbstractDirectorDebug
local H = Debug.Internal
local Director = PNC.WorldDirector
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Combat = PNC.AbstractCombatProfile
local Traversal = PNC.AbstractTraversal
local Store = PNC.HoomansWorldView
local Actions = PNC.AbstractActions
local Behavior = PNC.AbstractBehaviorProfile
local ResourceNeeds = PNC.AbstractResourceNeeds
local Encounters = PNC.AbstractEncounters
local EncounterResolver = PNC.AbstractEncounterResolver
local Core = PNC.Core

function Debug.BuildSnapshot(selectedGroupID, selectedLocationID, action,
    requestedSectorID)
    Director.Initialize()
    local groups, mobileGroups, locations = {}, {}, {}
    local mobileCounts = {
        road_roaming = 0,
        street_roaming = 0,
        en_route = 0,
        arrival_pending = 0,
    }
    local selected = Groups.Get(selectedGroupID) or Groups.List()[1]
    for _, group in ipairs(Groups.List()) do
        local summary = H.GroupSummary(
            group, selected and group.id == selected.id)
        groups[#groups + 1] = summary
        if summary.mobile then
            mobileGroups[#mobileGroups + 1] = summary
            local state = summary.mobile.debugState
            mobileCounts[state] = (mobileCounts[state] or 0) + 1
        end
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
    local corridorSnap = nil
    local sw = PsychopatzCore and PsychopatzCore.SurvivorWorld or nil
    local cg = sw and sw.CorridorGraph or nil
    if cg and type(cg.GetDebugSnapshot) == "function" then
        local raw = cg.GetDebugSnapshot()
        if type(raw) == "table" then
            local settlementCount, poiCount, wildCount = 0, 0, 0
            for _, n in ipairs(raw.nodes or {}) do
                if n.kind == "settlement" then settlementCount = settlementCount + 1
                elseif n.kind == "poi" then poiCount = poiCount + 1
                elseif n.kind == "wilderness" then wildCount = wildCount + 1 end
            end
            corridorSnap = {
                worldSeed = cg.GetWorldSeed and cg.GetWorldSeed() or raw.worldSeed,
                sectorCount = raw.sectorCount or 0,
                nodeCount = #(raw.nodes or {}),
                settlementNodeCount = settlementCount,
                poiNodeCount = poiCount,
                wildNodeCount = wildCount,
                edgeCount = #(raw.edges or {}),
                trafficHeatCount = cg.State and tonumber(cg.State.trafficHeatCount) or 0,
            }
        end
    end
    local scavengeSnap = sw and sw.ScavengeLedger
        and type(sw.ScavengeLedger.GetStats) == "function"
        and sw.ScavengeLedger.GetStats(Store.WorldAgeHours()) or nil
    local materializerSnap = sw and sw.EventMaterializer
        and type(sw.EventMaterializer.GetStats) == "function"
        and sw.EventMaterializer.GetStats() or nil
    local npcSharesSnap = PNC.Sandbox
        and type(PNC.Sandbox.WorldNPCShareWeights) == "function"
        and PNC.Sandbox.WorldNPCShareWeights() or nil
    local hazardSnap = PNC.AbstractHazardResolver
        and type(PNC.AbstractHazardResolver.GetDebugSnapshot) == "function"
        and H.Copy(PNC.AbstractHazardResolver.GetDebugSnapshot()) or nil
    local aftermathSnap = PNC.AbstractAftermathService
        and type(PNC.AbstractAftermathService.GetDebugSnapshot) == "function"
        and H.Copy(PNC.AbstractAftermathService.GetDebugSnapshot()) or nil
    return {
        metrics = Director.GetMetrics(), groups = groups,
        mobileGroups = mobileGroups, mobileCounts = mobileCounts,
        locations = locations,
        selectedGroupId = selected and selected.id,
        selectedLocationId = selectedLocation and selectedLocation.id,
        jobs = H.Copy(PNC.Scheduler.GetJobs()),
        recentEncounters = H.Copy(Store.Registry.encounters),
        corridorGraph = corridorSnap,
        scavengeLedger = scavengeSnap,
        eventMaterializer = materializerSnap,
        npcShares = npcSharesSnap,
        hazardResolver = hazardSnap,
        aftermath = aftermathSnap,
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
