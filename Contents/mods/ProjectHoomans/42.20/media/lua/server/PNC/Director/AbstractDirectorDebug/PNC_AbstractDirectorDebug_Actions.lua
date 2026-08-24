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
