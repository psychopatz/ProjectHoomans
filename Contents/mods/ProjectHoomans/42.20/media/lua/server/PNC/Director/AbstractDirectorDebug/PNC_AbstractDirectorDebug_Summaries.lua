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

function H.Copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
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
