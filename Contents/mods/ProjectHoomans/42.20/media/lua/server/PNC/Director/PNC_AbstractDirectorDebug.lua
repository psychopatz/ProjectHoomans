-- Sanitized, admin-only transport model and guarded developer controls.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractDirectorDebug = PNC.AbstractDirectorDebug or {}

local Debug = PNC.AbstractDirectorDebug
local Director = PNC.WorldDirector
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Combat = PNC.AbstractCombatProfile
local Traversal = PNC.AbstractTraversal
local Store = PNC.AbstractWorldStore
local Core = PNC.Core

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function groupSummary(group, selected)
    local profile, cacheState
    if selected then profile, cacheState = Combat.Get(group, false) end
    local needs = Groups.GetNeeds(group)
    return {
        id = group.id, factionId = group.factionId,
        homeCommunityId = group.homeCommunityId,
        groupType = group.groupType, memberIds = copy(group.memberIds),
        leaderId = group.leaderId, mission = group.mission, state = group.state,
        location = copy(group.location), targetLocation = copy(group.targetLocation),
        stateStartedAt = group.stateStartedAt, stateEndsAt = group.stateEndsAt,
        missionStartedAt = group.missionStartedAt,
        needs = copy(needs), resources = copy(group.resources),
        combatProfile = copy(profile or group.combatProfile),
        combatProfileDirty = group.combatProfileDirty == true,
        combatProfileReason = group.combatProfileReason,
        combatProfileCacheState = cacheState,
        destinationEvaluations = copy(group.diagnostics
            and group.diagnostics.destinationEvaluations or {}),
        travel = copy(group.diagnostics and group.diagnostics.travel),
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

function Debug.BuildSnapshot(selectedGroupID, selectedLocationID, action)
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
    return {
        metrics = Director.GetMetrics(), groups = groups, locations = locations,
        selectedGroupId = selected and selected.id,
        selectedLocationId = selectedLocation and selectedLocation.id,
        jobs = copy(PNC.Scheduler.GetJobs()),
        recentEncounters = copy(Store.Registry.encounters),
        generatedAt = Store.WorldAgeHours(), action = copy(action),
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
    elseif operation == "toggle_pause" then
        Director.SetPaused(not Director.Paused)
        ok, reason = true, Director.Paused and "paused" or "resumed"
    end
    return Debug.BuildSnapshot(args.groupID, args.locationID, {
        action = operation, ok = ok, reason = reason })
end

return Debug
