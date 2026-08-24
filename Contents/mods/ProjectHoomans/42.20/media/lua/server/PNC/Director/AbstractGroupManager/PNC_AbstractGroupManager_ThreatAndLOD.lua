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

function H.RememberExpiry(map, key, expiry, now)
    map[key] = expiry
    local count = 0
    for existing, existingExpiry in pairs(map) do
        if existingExpiry <= now then map[existing] = nil
        else count = count + 1 end
    end
    while count > Config.RECENT_THREAT_HISTORY_LIMIT do
        local oldestKey, oldestExpiry
        for existing, existingExpiry in pairs(map) do
            if not oldestExpiry or existingExpiry < oldestExpiry then
                oldestKey, oldestExpiry = existing, existingExpiry
            end
        end
        if not oldestKey then break end
        map[oldestKey] = nil
        count = count - 1
    end
end

function Groups.RememberThreat(groupOrID, locationID, hostileGroupID, expiry, now)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    if not group then return false end
    now = tonumber(now) or Store.WorldAgeHours()
    expiry = math.max(now, tonumber(expiry) or now)
    group.recentAvoidedLocations = group.recentAvoidedLocations or {}
    group.recentHostileGroups = group.recentHostileGroups or {}
    if locationID then H.RememberExpiry(group.recentAvoidedLocations,
        tostring(locationID), expiry, now) end
    if hostileGroupID then H.RememberExpiry(group.recentHostileGroups,
        tostring(hostileGroupID), expiry, now) end
    return true
end

function Groups.HasLiveMembers(groupOrID)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    if not group then return false end
    for _, npcID in ipairs(group.memberIds or {}) do
        local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
        local body = record and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(npcID) or nil
        if body or record and record.presenceState == Const.PRESENCE_LIVE then
            return true
        end
    end
    return false
end

function Groups.RefreshLOD(groupOrID, at)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    local live = Groups.HasLiveMembers(group)
    local lod = group.simulation and group.simulation.lod or "ABSTRACT"
    if live and lod ~= "ACTIVE" then
        Locations.Depart(group, at)
        group.simulation.lod = "ACTIVE"
        group.targetLocation = nil
        if group.action then
            Store.Emit("ABSTRACT_ACTION_INTERRUPTED", { groupId = group.id,
                actionType = group.action.type, reason = "materialized" })
            group.action = nil
        end
        Groups.SetState(group, "ACTIVE", at, at)
        Store.Emit("GROUP_MATERIALIZED", { groupId = group.id })
    elseif not live and lod == "ACTIVE" then
        group.simulation.lod = "ABSTRACT"
        Groups.SetState(group, "ARRIVED", at, at)
        Locations.Arrive(group, at, 0)
        Store.Emit("GROUP_ABSTRACTED", { groupId = group.id })
    end
    return live and "ACTIVE" or "ABSTRACT", "refreshed"
end

