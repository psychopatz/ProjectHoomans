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
    elseif operation == "scan_corridor_collisions" then
        local reports = Encounters and Encounters.ScanTravelingCollisions
            and Encounters.ScanTravelingCollisions(Store.WorldAgeHours(), 8) or {}
        ok, reason = true, "scanned_collisions_" .. tostring(#reports)
    elseif operation == "run_hazard_tick" then
        local checked = PNC.AbstractHazardResolver
            and PNC.AbstractHazardResolver.Tick
            and PNC.AbstractHazardResolver.Tick(Store.WorldAgeHours(), 16) or 0
        ok, reason = true, "hazard_checked_" .. tostring(checked)
    elseif operation == "prune_aftermath" then
        local pruned = PNC.AbstractAftermathService
            and PNC.AbstractAftermathService.PruneExpired
            and PNC.AbstractAftermathService.PruneExpired(Store.WorldAgeHours()) or 0
        ok, reason = true, "aftermath_pruned_" .. tostring(pruned)
    elseif operation == "trigger_test_settlement_raid" then
        local list = PNC.Communities and PNC.Communities.List and PNC.Communities.List() or {}
        local targetComm = nil
        for i = 1, #list do
            local c = list[i]
            if type(c) == "table" and c.status ~= "COLLAPSED" and c.owner ~= "player" then
                targetComm = c
                break
            end
        end
        if not targetComm then
            ok, reason = false, "no_ai_settlement_available"
        elseif PNC.SettlementInteractionService
            and type(PNC.SettlementInteractionService.OnGroupArriveAtSettlement) == "function"
        then
            targetComm.lastRaidedAt = nil
            local attacker = Groups.Get(args.groupID) or {
                id = "debug_raider_squad",
                groupType = "LOOTER",
                factionId = "debug_looter_faction",
                memberIds = {},
                resources = { food = 5, water = 5, supplies = 5 },
            }
            local home = type(targetComm.home) == "table" and targetComm.home or { x = 0, y = 0, z = 0 }
            local ran, report = PNC.SettlementInteractionService.OnGroupArriveAtSettlement(
                attacker,
                { type = "SETTLEMENT", communityId = targetComm.id, x = home.x, y = home.y, z = home.z or 0 },
                Store.WorldAgeHours()
            )
            ok = ran == true
            reason = type(report) == "table"
                and ("raid_" .. tostring(report.outcome) .. "_food=" .. tostring(report.stolen and report.stolen.food or 0))
                or tostring(report or "raid_failed")
        else
            ok, reason = false, "settlement_interaction_unavailable"
        end
    elseif operation == "simulate_shortage_and_rescue" then
        local list = PNC.Communities and PNC.Communities.List and PNC.Communities.List() or {}
        local targetComm = nil
        for i = 1, #list do
            local c = list[i]
            if type(c) == "table" and c.status ~= "COLLAPSED" and c.owner ~= "player" then
                targetComm = c
                break
            end
        end
        if not targetComm then
            ok, reason = false, "no_ai_settlement_available"
        else
            targetComm.resources = type(targetComm.resources) == "table" and targetComm.resources or {}
            targetComm.resources.food = 2
            targetComm.resources.water = 3
            targetComm.starvationHours = 24
            targetComm.lastAITradeAt = nil
            local home = type(targetComm.home) == "table" and targetComm.home or { x = 0, y = 0, z = 0 }
            local trader = {
                id = "debug_caravan_rescue",
                groupType = "TRADER",
                factionId = "debug_trader_faction",
                resources = { supplies = 20 },
            }
            local ran, barter = PNC.SettlementInteractionService
                and PNC.SettlementInteractionService.OnGroupArriveAtSettlement
                and PNC.SettlementInteractionService.OnGroupArriveAtSettlement(
                    trader,
                    { type = "SETTLEMENT", communityId = targetComm.id, x = home.x, y = home.y, z = home.z or 0 },
                    Store.WorldAgeHours()
                )
            ok = ran == true
            reason = type(barter) == "table"
                and ("rescued_food+" .. tostring(barter.foodDelivered or 0)
                    .. "_water+" .. tostring(barter.waterDelivered or 0))
                or tostring(barter or "rescue_failed")
        end
    end
    return Debug.BuildSnapshot(args.groupID, args.locationID, {
        action = operation, ok = ok, reason = reason },
        args.populationSectorID)
end
