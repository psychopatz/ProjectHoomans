if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Traversal = PNC.AbstractTraversal
local H = Traversal.Internal
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Encounters = PNC.AbstractEncounters
local Actions = PNC.AbstractActions
local ResourceNeeds = PNC.AbstractResourceNeeds
local Config = PNC.DirectorConfig

function Traversal.CalculateTravelHours(group, target)
    local dx, dy = target.x - group.location.x, target.y - group.location.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local needs = Groups.GetNeeds(group) or {}
    local fatigue = math.max(0, math.min(1,
        tonumber(needs.fatigue) or 0
    ))
    local fatigueModifier = 1 - fatigue * 0.35
    local speed = Config.TRAVEL_SPEED_TILES_PER_HOUR * fatigueModifier
    return math.max(Config.MIN_TRAVEL_HOURS,
        math.min(Config.MAX_TRAVEL_HOURS, distance / math.max(1, speed))), distance
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
    Locations.Depart(group, at)
    group.targetLocation = Locations.Ref(target)
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.travel = { from = group.location.id, to = target.id,
        distance = distance, travelHours = hours }
    Groups.SetState(group, "TRAVELING", at, at + hours)
    Store.Emit("GROUP_DESTINATION_SELECTED", { groupId = group.id,
        fromLocationId = group.location.id, targetLocationId = target.id,
        arrivalAt = at + hours })
    return true, "travel_started"
end

function Traversal.Arrive(groupOrID, at)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not group.targetLocation then return false, "no_target" end
    local target = Locations.Get(group.targetLocation.id)
    if not target then
        group.targetLocation = nil
        Groups.SetState(group, "IDLE", at, at)
        return false, "target_missing"
    end
    group.location = Locations.Ref(target)
    group.targetLocation = nil
    group.visited[target.id] = true
    Groups.SetState(group, "ARRIVED", at, at)
    Groups.SynchronizeMembersAtLocation(group)
    local faction = group.factionId and PNC.Factions
        and PNC.Factions.Get(group.factionId) or nil
    if faction and PNC.Factions.IsMobileGroup(faction)
        and target.sourceSite and PNC.Factions.UpdateMobileGroup
    then
        PNC.Factions.UpdateMobileGroup(faction.id, {
            site = target.sourceSite, lastMovedAt = at,
            nextMoveAt = at + (tonumber(faction.mobile.relocationHours) or 1),
            relocationCount = (tonumber(faction.mobile.relocationCount) or 0) + 1,
        }, "abstract_group_arrival")
    end
    Locations.Arrive(group, at, 0)
    local reports = Encounters.DetectAt(target, group, at)
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
        if at >= (tonumber(group.stateEndsAt) or 0) then
            return Traversal.Arrive(group, at)
        end
        return false, "in_transit"
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
