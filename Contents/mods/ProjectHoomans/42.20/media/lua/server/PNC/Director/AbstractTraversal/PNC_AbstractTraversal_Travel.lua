if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Traversal = PNC.AbstractTraversal
local H = Traversal.Internal
local Store = PNC.HoomansWorldView
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Encounters = PNC.AbstractEncounters
local Actions = PNC.AbstractActions
local ResourceNeeds = PNC.AbstractResourceNeeds
local Config = PNC.DirectorConfig
local CoreGroupTravel = require
    "PNC/Core/Director/PNC_CoreGroupTraversalBridge"
local TravelConditions = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTravelConditions"
local ScavengeLedger = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldScavengeLedger"
local GroupJourney = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
local RoutePlanner = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldRoutePlanner"
local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local WorldEvents = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"
local SettlementOps = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldSettlementOps"

function Traversal.CalculateTravelHours(group, target)
    local dx, dy = target.x - group.location.x, target.y - group.location.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local needs = Groups.GetNeeds(group) or {}
    local fatigue = math.max(0, math.min(1,
        tonumber(needs.fatigue) or 0
    ))
    local fatigueModifier = 1 - fatigue * 0.35
    local cond = TravelConditions and TravelConditions.Evaluate
        and TravelConditions.Evaluate() or nil
    local envModifier = cond and tonumber(cond.speedMultiplier) or 1.0
    local speed = Config.TRAVEL_SPEED_TILES_PER_HOUR * fatigueModifier * envModifier
    return math.max(Config.MIN_TRAVEL_HOURS,
        math.min(Config.MAX_TRAVEL_HOURS, distance / math.max(1, speed))), distance
end

-- Opportunistically pause a traveling group in a nearby building or wilderness
-- clearing during storms, rainy nights, or clear nights (for non-nocturnal
-- archetypes like Traders, Scavengers, and Refugees).
function Traversal.EvaluateWeatherShelter(group, at, envOverride)
    if type(group) ~= "table" or group.state ~= "TRAVELING"
        or type(group.journey) ~= "table" or group.journey.state ~= "en_route"
    then
        return false, "not_en_route"
    end
    local cond = nil
    if TravelConditions and type(TravelConditions.EvaluateForArchetype) == "function" then
        cond = TravelConditions.EvaluateForArchetype(group.groupType, envOverride)
    elseif TravelConditions and type(TravelConditions.Evaluate) == "function" then
        cond = TravelConditions.Evaluate(envOverride)
    end
    if not cond or cond.shouldSeekShelter ~= true then
        group.shelteringForWeather = nil
        return false, "weather_clear"
    end
    if group.shelteringForWeather == true then
        return false, "already_sheltered"
    end
    local gx = tonumber(group.journey.x) or (group.location and tonumber(group.location.x)) or 0
    local gy = tonumber(group.journey.y) or (group.location and tonumber(group.location.y)) or 0
    local shelterPos = nil
    local resolver = PNC.CommunitySiteResolver
    if resolver and type(resolver.FindAvailableNear) == "function" then
        local site = resolver.FindAvailableNear(gx, gy, 0, 60)
        if type(site) == "table" and type(site.home) == "table" then
            shelterPos = {
                x = site.home.x,
                y = site.home.y,
                z = site.home.z or 0,
                kind = "building",
            }
        end
    end
    if not shelterPos and RoutePlanner and type(RoutePlanner.SelectNextScavengePOI) == "function" then
        local poi = RoutePlanner.SelectNextScavengePOI(gx, gy, {
            minDistance = 0,
            maxDistance = 90,
            sectorRadius = 0,
            worldAgeHours = at,
        })
        if poi then
            shelterPos = {
                x = poi.x,
                y = poi.y,
                z = poi.z or 0,
                kind = poi.kind == "wilderness" and "wilderness_camp" or "building_poi",
            }
        end
    end
    local waitHours = tonumber(cond.recommendedWaitHours) or 1.5
    if GroupJourney and type(GroupJourney.SetShelterWait) == "function" then
        GroupJourney.SetShelterWait(group.journey, waitHours, shelterPos, cond.reason)
    else
        group.journey.state = "waiting"
        group.journey.waitRemainingHours = waitHours
    end
    if cond.shouldCampNight == true then
        local needs = Groups and type(Groups.GetNeeds) == "function" and Groups.GetNeeds(group) or nil
        if type(needs) == "table" then
            needs.fatigue = math.max(0, (tonumber(needs.fatigue) or 0) - 0.55)
        end
        if type(group.resources) == "table" then
            group.resources.food = math.max(0, (tonumber(group.resources.food) or 0) - 4)
            group.resources.water = math.max(0, (tonumber(group.resources.water) or 0) - 4)
        end
        if WorldEvents and type(WorldEvents.Publish) == "function" then
            local cx = shelterPos and shelterPos.x or gx
            local cy = shelterPos and shelterPos.y or gy
            WorldEvents.Publish({
                id = "camp_remains:" .. tostring(group.id) .. ":" .. tostring(math.floor(tonumber(at) or 0)),
                kind = "CAMP_REMAINS",
                ownerMod = "ProjectHoomans",
                x = cx,
                y = cy,
                z = shelterPos and shelterPos.z or 0,
                createdAt = tonumber(at) or 0,
                ttlHours = 12,
                summary = tostring(group.groupType or "Travelers") .. " camped here overnight",
                tags = { camp_remains = true },
            }, tonumber(at) or 0)
        end
    end
    group.shelteringForWeather = true
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.weatherShelter = {
        at = tonumber(at) or 0,
        reason = cond.reason,
        isNightCamp = cond.shouldCampNight == true,
        waitHours = waitHours,
        inBuilding = shelterPos ~= nil and shelterPos.kind ~= "wilderness_camp",
    }
    return true, cond.reason
end

-- En-route house/clearing pit stop: when a group pauses at a tagged pit_stop_poi
-- or pit_stop_wilderness waypoint, it replenishes its own abstracted supplies,
-- records depletion in Core ScavengeLedger (so other groups branch out), and
-- adds carriedSupplies for scavengers returning to their home settlement.
function Traversal.ProcessEnRoutePitStop(group, at)
    if type(group) ~= "table" or group.state ~= "TRAVELING"
        or type(group.journey) ~= "table" or group.journey.state ~= "waiting"
        or group.shelteringForWeather == true
    then
        return false, "not_pit_stop"
    end
    local route = group.journey.route
    local pts = type(route) == "table" and route.points or nil
    local segIdx = math.floor(tonumber(group.journey.segmentIndex) or 1)
    -- Journey.Advance increments segmentIndex before entering "waiting", so
    -- pts[segIdx] is the exact pit-stop waypoint the group is currently paused at.
    local wp = type(pts) == "table" and pts[segIdx] or nil
    if type(wp) ~= "table"
        or (wp.tag ~= "pit_stop_poi" and wp.tag ~= "pit_stop_wilderness")
    then
        return false, "waypoint_not_pit_stop"
    end
    if group._lastPitStopIndex == segIdx then
        return false, "pit_stop_already_processed"
    end
    group._lastPitStopIndex = segIdx
    at = tonumber(at) or Store.WorldAgeHours()

    if ScavengeLedger and type(ScavengeLedger.RecordScavenge) == "function" then
        ScavengeLedger.RecordScavenge(wp.x, wp.y, 0.45, at)
    end
    if CorridorGraph and type(CorridorGraph.RecordTrafficHeat) == "function"
        and (group.groupType == "TRADER" or group.groupType == "SCAVENGER")
    then
        CorridorGraph.RecordTrafficHeat(wp.x, wp.y, 0.50, at)
    end
    if type(group.resources) == "table" then
        group.resources.food = math.min(100, (tonumber(group.resources.food) or 0) + 15)
        group.resources.water = math.min(100, (tonumber(group.resources.water) or 0) + 15)
        group.resources.supplies = math.min(100, (tonumber(group.resources.supplies) or 0) + 8)
    end
    if group.homeCommunityId or group.groupType == "SCAVENGER" then
        group.carriedSupplies = (tonumber(group.carriedSupplies) or 0) + 12
    end
    local gType = string.upper(tostring(group.groupType or ""))
    if (gType == "TRADER" or gType == "CARAVAN")
        and SettlementOps and type(SettlementOps.AddTraderAbstractStock) == "function"
    then
        -- Restock trader's separate abstract trade pool (exempt from physical carry-weight cap).
        SettlementOps.AddTraderAbstractStock(group, 10, "pit_stop_scavenge", at)
    end
    return true, wp.tag
end

function Traversal.Begin(groupOrID, targetOrID, at)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    local target = type(targetOrID) == "table" and targetOrID
        or Locations.Get(targetOrID)
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not target then return false, "invalid_travel" end
    if group.state == "TRAVELING" then return false, "already_traveling" end
    if group.location.id == target.id then return false, "already_there" end
    local hours, distance = Traversal.CalculateTravelHours(group, target)
    local journey, journeyReason =
        CoreGroupTravel.Begin(group, target, hours, at)
    if not journey then
        return false, journeyReason or "group_journey_start_failed"
    end
    Locations.Depart(group, at)
    group.targetLocation = Locations.Ref(target)
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.travel = { from = group.location.id, to = target.id,
        distance = distance, travelHours = hours }
    Groups.SetState(group, "TRAVELING", at, journey.eta or (at + hours))
    Store.Emit("GROUP_DESTINATION_SELECTED", { groupId = group.id,
        fromLocationId = group.location.id, targetLocationId = target.id,
        arrivalAt = journey.eta or (at + hours) })
    return true, "travel_started"
end

-- Strengthened far-migration entrypoint for fleeing looters and displaced squads.
function Traversal.BeginFarMigration(groupOrID, opts, at)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    opts = type(opts) == "table" and opts or {}
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not group.location then return false, "invalid_group" end

    if group.state == "TRAVELING" and group.journey and CoreGroupTravel and CoreGroupTravel.Cancel then
        CoreGroupTravel.Cancel(group, "rerouted_far_migration")
        group.targetLocation = nil
        Groups.SetState(group, "IDLE", at, at)
    end

    group.recentAvoidedLocations = group.recentAvoidedLocations or {}
    if group.location.id then
        group.recentAvoidedLocations[group.location.id] = at + (tonumber(opts.avoidHours) or 24)
    end
    group.mission = "FLEE_MIGRATE"

    local target, pickReason = Traversal.ChooseFarMigrationDestination(
        group,
        opts.threatX or group.location.x,
        opts.threatY or group.location.y,
        opts
    )
    if not target then
        return false, pickReason or "no_far_destination"
    end
    local ok, reason = Traversal.Begin(group, target, at)
    return ok, ok and (pickReason or reason) or reason
end

function Traversal.Arrive(groupOrID, at)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not group.targetLocation then return false, "no_target" end
    local faction = group.factionId and PNC.Factions
        and PNC.Factions.Get(group.factionId) or nil
    local mobile = faction and PNC.Factions.IsMobileGroup
        and PNC.Factions.IsMobileGroup(faction)
        and faction.mobile or nil
    local settlementTraveling = mobile
        and mobile.activity
            == PNC.FactionConstants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
    local settlementTravel = mobile and mobile.travel
        and PNC.Core and PNC.Core.DeepCopy
        and PNC.Core.DeepCopy(mobile.travel) or nil
    local target = Locations.Get(group.targetLocation.id)
    if not target then
        if group.journey then
            CoreGroupTravel.Cancel(group, "target_missing")
        end
        group.targetLocation = nil
        Groups.SetState(group, "IDLE", at, at)
        -- Resilient reroute: if migrating away from threat, pick a replacement
        -- far waypoint once instead of stranding the group IDLE.
        if group.mission == "FLEE_MIGRATE" and group._rerouteAttempted ~= true
            and type(Traversal.BeginFarMigration) == "function"
        then
            group._rerouteAttempted = true
            local rerouted = Traversal.BeginFarMigration(group, {}, at)
            if rerouted then return true, "target_missing_rerouted" end
        end
        group._rerouteAttempted = nil
        if settlementTraveling and PNC.Factions.SetMobileGroup then
            local failedMobile = PNC.Core and PNC.Core.DeepCopy
                and PNC.Core.DeepCopy(faction.mobile) or faction.mobile
            failedMobile.activity =
                PNC.FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING
            failedMobile.travel = nil
            failedMobile.ambient = nil
            PNC.Factions.SetMobileGroup(
                faction.id,
                failedMobile,
                "mobile_settlement_target_missing"
            )
        elseif settlementTraveling and PNC.Factions.UpdateMobileGroup then
            PNC.Factions.UpdateMobileGroup(faction.id, {
                activity = PNC.FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING,
            }, "mobile_settlement_target_missing")
        end
        return false, "target_missing"
    end
    local completedJourney, completeReason =
        CoreGroupTravel.Complete(group, target, at)
    if not completedJourney then
        return false, completeReason or "group_journey_complete_failed"
    end
    group.location = Locations.Ref(target)
    group.targetLocation = nil
    group._lastPitStopIndex = nil
    group.visited[target.id] = true
    if ScavengeLedger and type(ScavengeLedger.RecordScavenge) == "function"
        and (group.mission == "SCAVENGE" or target.type == "BUILDING" or target.type == "SCAVENGE_POI")
    then
        ScavengeLedger.RecordScavenge(target.x, target.y, 0.50, at)
        if group.homeCommunityId or group.groupType == "SCAVENGER" then
            group.carriedSupplies = (tonumber(group.carriedSupplies) or 0) + 18
        end
    end
    if group.homeCommunityId
        and (tonumber(group.carriedSupplies) or 0) > 0
        and (target.type == "SETTLEMENT" or target.communityId == group.homeCommunityId)
        and PNC.CommunitySustainabilityService
        and type(PNC.CommunitySustainabilityService.DepositScavengerSupplies) == "function"
    then
        PNC.CommunitySustainabilityService.DepositScavengerSupplies(group, at)
    elseif (target.type == "SETTLEMENT" or target.communityId)
        and PNC.SettlementInteractionService
        and type(PNC.SettlementInteractionService.OnGroupArriveAtSettlement) == "function"
    then
        PNC.SettlementInteractionService.OnGroupArriveAtSettlement(group, target, at)
    end
    Groups.SetState(group, "ARRIVED", at, at)
    Groups.SynchronizeMembersAtLocation(group)
    if mobile and PNC.Factions.UpdateMobileGroup
    then
        local mobilePatch = {
            lastMovedAt = at,
            nextMoveAt = at + (tonumber(faction.mobile.relocationHours) or 1),
            relocationCount = (tonumber(faction.mobile.relocationCount) or 0) + 1,
        }
        if target.sourceSite then mobilePatch.site = target.sourceSite end
        if settlementTraveling then
            -- Settlement travel is a one-shot activity. Leaving this flag set
            -- after the abstract group arrives makes every later traversal
            -- tick return mobile_settlement_arrival_pending forever.
            mobilePatch.activity =
                PNC.FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING
            mobilePatch.travel = nil
            mobilePatch.ambient = nil
        end
        if settlementTraveling and PNC.Factions.SetMobileGroup
        then
            local settledMobile = PNC.Core and PNC.Core.DeepCopy
                and PNC.Core.DeepCopy(faction.mobile) or faction.mobile
            for key, value in pairs(mobilePatch) do
                settledMobile[key] = value
            end
            settledMobile.travel = nil
            settledMobile.ambient = nil
            PNC.Factions.SetMobileGroup(
                faction.id,
                settledMobile,
                "abstract_group_arrival"
            )
        else
            PNC.Factions.UpdateMobileGroup(
                faction.id, mobilePatch, "abstract_group_arrival")
        end
    end
    Locations.Arrive(group, at, 0)
    local reports = Encounters.DetectAt(target, group, at)
    if settlementTravel
        and PNC.MobileSettlementVisitService
        and PNC.MobileSettlementVisitService.OnSettlementArrival
    then
        PNC.MobileSettlementVisitService.OnSettlementArrival(
            faction,
            target,
            settlementTravel,
            at,
            group,
            reports
        )
    end
    Store.Emit("GROUP_ARRIVED", { groupId = group.id,
        locationId = target.id, encounters = #reports })
    if group.mission == "FLEE" then
        local previous = group.previousMission
        Groups.SetMission(group, previous and previous.type or "SCAVENGE", at, true)
        group.previousMission = nil
        Groups.SetState(group, "ACTION_COMPLETE", at, at)
    elseif Actions then
        Actions.StartForMission(group, at)
    end
    return true, "arrived", reports
end

function Traversal.Advance(group, at)
    at = tonumber(at) or Store.WorldAgeHours()
    local lod = Groups.RefreshLOD(group, at)
    if lod == "ACTIVE" then
        -- Pause the abstract Core journey while members are live/materialized so
        -- the map stops extrapolating them forward (eliminates rubber-banding)
        -- and they don't teleport forward after talking/fighting when abstracted.
        if type(group.journey) == "table" and group.journey.state == "en_route" then
            group.journey.state = "paused"
            group.journey.pausedForLive = true
            group.journey.lastAdvancedAt = at
            local adapter = PNC.CoreSurvivorWorldAdapter
            if adapter and type(adapter.CommitGroup) == "function" then
                pcall(adapter.CommitGroup, group, "pnc_group_journey_paused_live")
            end
        end
        return false, "active_simulation"
    end
    if group.state == "TRAVELING" then
        -- Seamlessly resume abstract travel from where live members left off.
        if type(group.journey) == "table"
            and group.journey.state == "paused"
            and group.journey.pausedForLive == true
        then
            group.journey.state = "en_route"
            group.journey.pausedForLive = nil
            group.journey.lastAdvancedAt = at
        end
        local journey, journeyReason =
            CoreGroupTravel.Advance(group, at)
        if not journey then
            return false, journeyReason or "group_journey_advance_failed"
        end
        if journey.state == "arrived" then
            return Traversal.Arrive(group, at)
        end
        if journey.state == "cancelled"
            or journey.state == "blocked"
        then
            group.targetLocation = nil
            Groups.SetState(group, "IDLE", at, at)
            return false, journey.failureReason
                or "group_journey_terminal"
        end
        return false, "in_transit"
    end
    local faction = group.factionId and PNC.Factions
        and PNC.Factions.Get(group.factionId) or nil
    if faction and faction.mobile
        and faction.mobile.activity
            == PNC.FactionConstants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
    then
        return false, "mobile_settlement_arrival_pending"
    end
    if group.mobileAmbient and group.state ~= "ACTIVE" then
        return false, "mobile_ambient_hold"
    end
    if group.state == "IDLE" or group.state == "ARRIVED"
        or group.state == "WAITING" or group.state == "ACTION_COMPLETE"
    then
        local target = Traversal.ChooseDestination(group)
        if target then return Traversal.Begin(group, target, at) end
        return false, "no_destination"
    end
    return false, "state_not_traversable"
end
