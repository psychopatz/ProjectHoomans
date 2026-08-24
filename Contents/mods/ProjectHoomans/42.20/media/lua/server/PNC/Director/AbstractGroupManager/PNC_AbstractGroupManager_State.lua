if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractGroups = PNC.AbstractGroups or {}
PNC.AbstractGroupManagerInternal =
    PNC.AbstractGroupManagerInternal or {}

local Groups = PNC.AbstractGroups
local H = PNC.AbstractGroupManagerInternal
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Locations = PNC.AbstractLocations
local Core = PNC.Core
local Const = PNC.Const

function Groups.SetMission(groupOrID, mission, at, force)
    if not H.Authority() then return false, "not_authority" end
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    mission = tostring(mission or "")
    at = tonumber(at) or Store.WorldAgeHours()
    if not group or not Config.MISSIONS[mission] then return false, "invalid_mission" end
    if force ~= true and mission ~= group.mission
        and at - (tonumber(group.missionStartedAt) or 0)
            < Config.MIN_MISSION_DURATION_HOURS
    then return false, "mission_committed" end
    if mission == group.mission then return true, "unchanged" end
    group.mission, group.missionStartedAt = mission, at
    H.Touch(group, "group_mission_changed")
    return true, "changed"
end

function Groups.SetState(groupOrID, state, at, endsAt)
    if not H.Authority() then return false, "not_authority" end
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    state = tostring(state or "")
    if not group or not Config.STATES[state] then return false, "invalid_state" end
    group.state = state
    group.stateStartedAt = tonumber(at) or Store.WorldAgeHours()
    group.stateEndsAt = math.max(group.stateStartedAt, tonumber(endsAt)
        or group.stateStartedAt)
    H.Touch(group, "group_state_changed")
    return true, "changed"
end

function Groups.SynchronizeMembersAtLocation(group)
    local location = group and group.location
    if not location then return 0 end
    local updated = 0
    for index, npcID in ipairs(group.memberIds or {}) do
        local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
        local live = record and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(npcID) or nil
        if record and record.alive ~= false and not live
            and record.presenceState ~= Const.PRESENCE_LIVE
        then
            local offsetX = ((index - 1) % 3) - 1
            local offsetY = math.floor((index - 1) / 3)
            record.x, record.y, record.z = location.x + offsetX,
                location.y + offsetY, location.z
            record.anchorX, record.anchorY, record.anchorZ =
                location.x, location.y, location.z
            if type(record.orderSpec) == "table" then
                record.orderSpec.x, record.orderSpec.y, record.orderSpec.z =
                    location.x, location.y, location.z
            end
            if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
                PNC.SpatialIndex.UpdateNPC(record)
            end
            if PNC.Registry.MarkDirty then
                PNC.Registry.MarkDirty(record, "abstract_group_arrival")
            end
            updated = updated + 1
        end
    end
    return updated
end

function Groups.Remove(groupID, reason)
    if not H.Authority() then return false, "not_authority" end
    local group = Groups.Get(groupID)
    if not group then return false, "not_found" end
    Locations.Depart(group, Store.WorldAgeHours())
    Store.Registry.groupsByID[group.id] = nil
    Store.Touch(reason or "group_removed")
    Store.Emit("GROUP_DESTROYED", { groupId = group.id,
        factionId = group.factionId,
        homeCommunityId = group.homeCommunityId,
        sectorId = PNC.PopulationSectors and group.location
            and PNC.PopulationSectors.IDForPosition(
                group.location.x, group.location.y) or nil,
        reason = reason or "group_removed" })
    return true, "removed"
end

return Groups

