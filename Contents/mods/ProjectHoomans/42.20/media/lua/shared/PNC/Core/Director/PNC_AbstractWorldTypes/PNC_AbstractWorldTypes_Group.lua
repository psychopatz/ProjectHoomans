local Types = PNC.AbstractWorldTypes
local Internal = Types.Internal
local Config = PNC.DirectorConfig

local function normalizeActivity(source, location)
    local state = Config.STATES[source.state] and source.state or "IDLE"
    local target = Types.NormalizeLocationRef(source.targetLocation)
    local action = Types.NormalizeAction(source.action)
    if state == "TRAVELING" and not target then state = "IDLE" end
    if action and action.locationId ~= location.id then action = nil end
    if action and state ~= "ACTIVE" and state ~= "TRAVELING" then
        state = "PERFORMING_ACTION"
    elseif (state == "PERFORMING_ACTION" or state == "ENGAGED")
        and not action
    then
        state = "ARRIVED"
    end
    return state, target, action
end

local function normalizeProfiles(source)
    local behavior = type(source.behaviorProfile) == "table"
        and Types.NormalizeBehaviorProfile(source.behaviorProfile) or nil
    local combat = source.combatProfile
        and Types.NormalizeCombatProfile(source.combatProfile) or nil
    return behavior, combat
end

function Types.NormalizeGroup(value, groupID)
    local source = type(value) == "table" and value or {}
    local id = Internal.SafeID(groupID or source.id, "agroup_")
    local location = Types.NormalizeLocationRef(source.location)
    local groupType
    local state
    local target
    local action
    local behavior
    local combat
    if not id or not location then return nil end
    groupType = Config.GROUP_TYPES[source.groupType]
        and source.groupType or "WANDERER"
    state, target, action = normalizeActivity(source, location)
    behavior, combat = normalizeProfiles(source)
    return {
        schemaVersion = Config.SCHEMA_VERSION,
        id = id,
        factionId = Internal.SafeID(source.factionId),
        homeCommunityId = Internal.SafeID(source.homeCommunityId),
        groupType = groupType,
        memberIds = Internal.IDArray(source.memberIds),
        leaderId = Internal.SafeID(source.leaderId),
        mission = Config.MISSIONS[source.mission]
            and source.mission or "IDLE",
        state = state,
        location = location,
        targetLocation = target,
        stateStartedAt = math.max(
            0,
            Internal.Finite(source.stateStartedAt, 0)
        ),
        stateEndsAt = math.max(0, Internal.Finite(source.stateEndsAt, 0)),
        missionStartedAt = math.max(
            0,
            Internal.Finite(source.missionStartedAt, 0)
        ),
        resources = Internal.Resources(source.resources),
        action = action,
        previousMission = Internal.PreviousMission(source.previousMission),
        behaviorProfile = behavior,
        morale = math.max(
            0,
            math.min(1, Internal.Finite(source.morale, 0.65))
        ),
        recentAvoidedLocations = Internal.ExpiryMap(
            source.recentAvoidedLocations,
            "aloc_"
        ),
        recentHostileGroups = Internal.ExpiryMap(
            source.recentHostileGroups,
            "agroup_"
        ),
        activeEncounterId = Internal.SafeID(
            source.activeEncounterId,
            "encounter_"
        ),
        recentEncounterId = Internal.SafeID(
            source.recentEncounterId,
            "encounter_"
        ),
        knowledge = type(source.knowledge) == "table"
            and Internal.Copy(source.knowledge) or {},
        visited = Internal.StringSet(source.visited),
        simulation = {
            lod = "ABSTRACT",
            nextUpdate = math.max(
                0,
                Internal.Finite(
                    source.simulation and source.simulation.nextUpdate,
                    0
                )
            ),
        },
        combatProfile = combat,
        combatProfileDirty = source.combatProfileDirty ~= false,
        combatProfileReason = type(source.combatProfileReason) == "string"
            and source.combatProfileReason or "migration",
        combatProfileSignature =
            type(source.combatProfileSignature) == "string"
                and source.combatProfileSignature or nil,
        revision = Internal.Integer(
            source.revision, 0, 2147483647, 0
        ),
        diagnostics = type(source.diagnostics) == "table"
            and Internal.Copy(source.diagnostics) or {},
        generation = Internal.Generation(source.generation),
    }
end
