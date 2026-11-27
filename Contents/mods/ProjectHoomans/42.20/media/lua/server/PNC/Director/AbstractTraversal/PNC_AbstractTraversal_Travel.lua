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

-- Opportunistically pause a traveling group in a nearby MetaGrid building
-- during heavy storms or rainy nights so players encounter sheltering travelers.
function Traversal.EvaluateWeatherShelter(group, at, envOverride)
    if type(group) ~= "table" or group.state ~= "TRAVELING"
        or type(group.journey) ~= "table" or group.journey.state ~= "en_route"
    then
        return false, "not_en_route"
    end
    local cond = TravelConditions and TravelConditions.Evaluate
        and TravelConditions.Evaluate(envOverride) or nil
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
        local site = resolver.FindAvailableNear(gx, gy, 0, 50)
        if type(site) == "table" and type(site.home) == "table" then
            shelterPos = site.home
        end
    end
    group.journey.state = "waiting"
    group.journey.waitRemainingHours = 1.5
    if shelterPos then
        group.journey.x = shelterPos.x
        group.journey.y = shelterPos.y
    end
    group.shelteringForWeather = true
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.weatherShelter = {
        at = tonumber(at) or 0,
        reason = cond.reason,
        inBuilding = shelterPos ~= nil,
    }
    return true, cond.reason
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
    group.visited[target.id] = true
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
    local lod = Groups.RefreshLOD(group, at)
    if lod == "ACTIVE" then return false, "active_simulation" end
    if group.state == "TRAVELING" then
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
