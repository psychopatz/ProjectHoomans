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
local Factions = PNC.Factions

function H.Copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function mobileSummary(group)
    local faction = group.factionId and Factions and Factions.Get
        and Factions.Get(group.factionId) or nil
    local mobile = faction and Factions.IsMobileGroup
        and Factions.IsMobileGroup(faction)
        and faction.mobile or nil
    if not mobile then return nil end
    local live = Groups.HasLiveMembers
        and Groups.HasLiveMembers(group) == true
    local activity = mobile.activity or "street_roaming"
    local destination = mobile.travel
        and mobile.travel.destination
        or mobile.ambient and mobile.ambient.target
        or mobile.strategicTarget
        or group.targetLocation
    local debugState
    if activity == "traveling_to_settlement" then
        debugState = group.state == "TRAVELING"
            and "en_route" or "arrival_pending"
    elseif mobile.ambient
        and mobile.ambient.objective == "road"
    then
        debugState = "road_roaming"
    else
        debugState = "street_roaming"
    end
    return {
        active = true,
        factionID = faction.id,
        archetypeID = faction.archetypeID,
        controlMode = mobile.controlMode,
        pathMode = mobile.pathMode,
        activity = activity,
        debugState = debugState,
        presence = live and "live"
            or group.simulation and group.simulation.lod or "abstract",
        groupID = group.id,
        site = H.Copy(mobile.site),
        ambient = H.Copy(mobile.ambient),
        strategicTarget = H.Copy(mobile.strategicTarget),
        travel = H.Copy(mobile.travel),
        destination = H.Copy(destination),
        lastDepartureAt = mobile.lastDepartureAt,
        lastMovedAt = mobile.lastMovedAt,
        nextMoveAt = mobile.nextMoveAt,
        relocationCount = mobile.relocationCount,
        groupState = group.state,
        groupStateStartedAt = group.stateStartedAt,
        groupStateEndsAt = group.stateEndsAt,
    }
end

function H.GroupSummary(group, selected)
    local profile, cacheState
    if selected then profile, cacheState = Combat.Get(group, false) end
    local needs = Groups.GetNeeds(group)
    local resourceNeeds = ResourceNeeds.Get(group)
    local behavior = Behavior.GetContext(group, profile or group.combatProfile)
    return {
        id = group.id, factionId = group.factionId,
        homeCommunityId = group.homeCommunityId,
        groupType = group.groupType, memberIds = H.Copy(group.memberIds),
        leaderId = group.leaderId, mission = group.mission, state = group.state,
        location = H.Copy(group.location), targetLocation = H.Copy(group.targetLocation),
        stateStartedAt = group.stateStartedAt, stateEndsAt = group.stateEndsAt,
        missionStartedAt = group.missionStartedAt,
        action = H.Copy(group.action), previousMission = H.Copy(group.previousMission),
        needs = H.Copy(needs), resourceNeeds = H.Copy(resourceNeeds),
        resources = H.Copy(group.resources), morale = group.morale,
        behaviorProfile = H.Copy(behavior and behavior.stable),
        desperation = behavior and behavior.desperation or 0,
        activeEncounterId = group.activeEncounterId,
        recentEncounterId = group.recentEncounterId,
        combatProfile = H.Copy(profile or group.combatProfile),
        combatProfileDirty = group.combatProfileDirty == true,
        combatProfileReason = group.combatProfileReason,
        combatProfileSignature = group.combatProfileSignature,
        combatProfileCacheState = cacheState,
        destinationEvaluations = H.Copy(group.diagnostics
            and group.diagnostics.destinationEvaluations or {}),
        travel = H.Copy(group.diagnostics and group.diagnostics.travel),
        mobile = mobileSummary(group),
        lastScavenge = H.Copy(group.diagnostics and group.diagnostics.lastScavenge),
        revision = group.revision,
    }
end

function H.LocationSummary(location)
    local occupants = {}
    for groupID in pairs(location.occupants.groups or {}) do
        occupants[#occupants + 1] = groupID
    end
    table.sort(occupants)
    return { id = location.id, type = location.type,
        x = location.x, y = location.y, z = location.z,
        tags = H.Copy(location.tags), resourcePotential = H.Copy(location.resourcePotential),
        scavengedLevel = location.scavengedLevel, danger = location.danger,
        occupantGroupIds = occupants, revision = location.revision }
end
