-- Sanitized, admin-only transport model and guarded developer controls.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractDirectorDebug = PNC.AbstractDirectorDebug or {}

local Debug = PNC.AbstractDirectorDebug
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

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function groupSummary(group, selected)
    local profile, cacheState
    if selected then profile, cacheState = Combat.Get(group, false) end
    local needs = Groups.GetNeeds(group)
    local resourceNeeds = ResourceNeeds.Get(group)
    local behavior = Behavior.GetContext(group, profile or group.combatProfile)
    return {
        id = group.id, factionId = group.factionId,
        homeCommunityId = group.homeCommunityId,
        groupType = group.groupType, memberIds = copy(group.memberIds),
        leaderId = group.leaderId, mission = group.mission, state = group.state,
        location = copy(group.location), targetLocation = copy(group.targetLocation),
        stateStartedAt = group.stateStartedAt, stateEndsAt = group.stateEndsAt,
        missionStartedAt = group.missionStartedAt,
        action = copy(group.action), previousMission = copy(group.previousMission),
        needs = copy(needs), resourceNeeds = copy(resourceNeeds),
        resources = copy(group.resources), morale = group.morale,
        behaviorProfile = copy(behavior and behavior.stable),
        desperation = behavior and behavior.desperation or 0,
        activeEncounterId = group.activeEncounterId,
        recentEncounterId = group.recentEncounterId,
        combatProfile = copy(profile or group.combatProfile),
        combatProfileDirty = group.combatProfileDirty == true,
        combatProfileReason = group.combatProfileReason,
        combatProfileSignature = group.combatProfileSignature,
        combatProfileCacheState = cacheState,
        destinationEvaluations = copy(group.diagnostics
            and group.diagnostics.destinationEvaluations or {}),
        travel = copy(group.diagnostics and group.diagnostics.travel),
        lastScavenge = copy(group.diagnostics and group.diagnostics.lastScavenge),
        revision = group.revision,
    }
end

local function locationSummary(location)
    local occupants = {}
    for groupID in pairs(location.occupants.groups or {}) do
        occupants[#occupants + 1] = groupID
    end
    table.sort(occupants)
    return { id = location.id, type = location.type,
        x = location.x, y = location.y, z = location.z,
        tags = copy(location.tags), resourcePotential = copy(location.resourcePotential),
        scavengedLevel = location.scavengedLevel, danger = location.danger,
        occupantGroupIds = occupants, revision = location.revision }
end

function Debug.BuildSnapshot(selectedGroupID, selectedLocationID, action,
    requestedSectorID)
    Director.Initialize()
    local groups, locations = {}, {}
    local selected = Groups.Get(selectedGroupID) or Groups.List()[1]
    for _, group in ipairs(Groups.List()) do
        groups[#groups + 1] = groupSummary(group, selected and group.id == selected.id)
    end
    local selectedLocation = Locations.Get(selectedLocationID)
        or selected and Locations.Get(selected.location.id) or Locations.List()[1]
    for _, location in ipairs(Locations.List()) do
        locations[#locations + 1] = locationSummary(location)
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
        jobs = copy(PNC.Scheduler.GetJobs()),
        recentEncounters = copy(Store.Registry.encounters),
        generatedAt = Store.WorldAgeHours(), action = copy(action),
        population = {
            metrics = PNC.PopulationDirector
                and PNC.PopulationDirector.GetMetrics() or {},
            resolved = copy(PNC.PopulationDirector
                and PNC.PopulationDirector.LastResolved
                or PNC.PopulationSandbox and PNC.PopulationSandbox.Resolve() or {}),
            sectors = copy(populationSectors),
            selectedSectorId = selectedSectorID,
            starter = copy(PNC.StarterPopulation
                and PNC.StarterPopulation.GetDebugSnapshot
                and PNC.StarterPopulation.GetDebugSnapshot() or {}),
            queue = copy(PNC.GenerationQueue
                and PNC.GenerationQueue.Snapshot
                and PNC.GenerationQueue.Snapshot(Store.WorldAgeHours()) or {}),
            reservations = copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.ReservationSnapshot
                and PNC.SettlementCandidates.ReservationSnapshot(
                    Store.WorldAgeHours()) or {}),
            selectedDiscovery = copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.LastMetaDiscovery
                and PNC.SettlementCandidates.LastMetaDiscovery[
                    selectedSectorID] or {}),
            store = { revision = Store.Registry.revision,
                dirty = Store.Dirty == true,
                lastMutationReason = Store.LastMutationReason },
            history = copy(PNC.PopulationSectors
                and PNC.PopulationSectors.History or {}),
            log = copy(PNC.PopulationLog
                and PNC.PopulationLog.GetEntries
                and PNC.PopulationLog.GetEntries() or {}),
            candidateMetrics = copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.Metrics or {}),
            candidateEvaluations = copy(PNC.SettlementCandidates
                and PNC.SettlementCandidates.LastEvaluations
                and PNC.SettlementCandidates.LastEvaluations[selectedSectorID]
                or {}),
        },
    }
end

function Debug.PerformAction(args)
    args = type(args) == "table" and args or {}
    local operation = tostring(args.directorAction or "")
    local ok, reason = false, "unknown_action"
    if operation == "force_update" then
        ok, reason = Director.ForceUpdate(args.groupID)
    elseif operation == "force_arrival" then
        ok, reason = Traversal.ForceArrival(args.groupID)
    elseif operation == "rebuild_profile" then
        local profile
        profile, reason = Combat.Get(args.groupID, true)
        ok = profile ~= nil
    elseif operation == "rebuild_behavior" then
        local profile
        profile, reason = Behavior.Get(args.groupID, true)
        ok = profile ~= nil
    elseif operation == "force_start_scavenge" then
        local action
        action, reason = Actions.Start(args.groupID, "SCAVENGE",
            Store.WorldAgeHours())
        ok = action ~= nil
    elseif operation == "force_complete_action" then
        local result
        result, reason = Actions.Complete(args.groupID,
            Store.WorldAgeHours(), true)
        ok = result ~= nil
    elseif operation == "force_encounter" then
        local group = Groups.Get(args.groupID)
        local reports = group and Encounters.DetectAt(group.location.id,
            group, Store.WorldAgeHours()) or {}
        EncounterResolver.ProcessBatch(Store.WorldAgeHours(),
            PNC.DirectorConfig.EncounterQueue.WORK_BUDGET)
        ok, reason = #reports > 0, #reports > 0 and "evaluated" or "no_collision"
    elseif operation == "toggle_pause" then
        Director.SetPaused(not Director.Paused)
        ok, reason = true, Director.Paused and "paused" or "resumed"
    elseif operation == "force_population_reconcile" then
        local count = PNC.PopulationDirector.RequestReconciliation(
            "GROUP", args.populationSectorID, Store.WorldAgeHours())
        count = count + PNC.PopulationDirector.RequestReconciliation(
            "SETTLEMENT", args.populationSectorID, Store.WorldAgeHours())
        ok, reason = true, "reconciled_" .. tostring(count)
    elseif operation == "queue_population_group" then
        ok, reason = PNC.GenerationQueue.Enqueue("GROUP", {
            sectorId = args.populationSectorID, priority = 10,
            source = "DEBUG" }, Store.WorldAgeHours())
    elseif operation == "queue_population_settlement" then
        ok, reason = PNC.GenerationQueue.Enqueue("SETTLEMENT", {
            sectorId = args.populationSectorID, priority = 10,
            source = "DEBUG" }, Store.WorldAgeHours())
    elseif operation == "clear_group_cooldown" then
        ok, reason = PNC.PopulationDirector.ClearCooldown(
            args.populationSectorID, "GROUP")
    elseif operation == "clear_settlement_cooldown" then
        ok, reason = PNC.PopulationDirector.ClearCooldown(
            args.populationSectorID, "SETTLEMENT")
    elseif operation == "rebuild_population_index" then
        ok, reason = PNC.PopulationSectors.RebuildIndexes(), "index_rebuilt"
    elseif operation == "toggle_population_pause" then
        local paused = PNC.PopulationDirector.SetPaused(
            not PNC.PopulationDirector.Paused)
        ok, reason = true, paused and "population_paused" or "population_resumed"
    elseif operation == "retry_starter_population" then
        ok, reason = PNC.StarterPopulation.Run(Store.WorldAgeHours(), true)
    elseif operation == "discover_population_sites" then
        local worldSeed = PNC.PopulationSectors.WorldSeed()
        local found
        found, reason = PNC.SettlementCandidates.DiscoverMeta(
            args.populationSectorID,
            PNC.PopulationSectors.Seed(tostring(worldSeed) .. ":DEBUG:"
                .. tostring(args.populationSectorID)), "DEBUG_DISCOVERY")
        ok = found > 0
        reason = type(reason) == "table" and reason.reason or reason
    elseif operation == "process_population_queue" then
        local processed = PNC.PopulationDirector.ProcessQueues(
            Store.WorldAgeHours())
        ok, reason = true, "processed_" .. tostring(processed)
    elseif operation == "clear_population_log" then
        PNC.PopulationLog.Clear()
        ok, reason = true, "population_log_cleared"
    end
    return Debug.BuildSnapshot(args.groupID, args.locationID, {
        action = operation, ok = ok, reason = reason },
        args.populationSectorID)
end

return Debug
