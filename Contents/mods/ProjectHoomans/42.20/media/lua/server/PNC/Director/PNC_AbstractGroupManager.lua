-- Persistent strategic groups reference canonical NPC/community/faction data.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractGroups = PNC.AbstractGroups or {}

local Groups = PNC.AbstractGroups
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Locations = PNC.AbstractLocations
local Core = PNC.Core
local Const = PNC.Const

Groups.Metrics = Groups.Metrics or { profileInvalidations = 0 }

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function touch(group, reason)
    group.revision = (tonumber(group.revision) or 0) + 1
    Store.Touch(reason)
end

local function groupTypeForFaction(faction)
    local mapping = { looter = "LOOTER", trader = "TRADER",
        refugee = "REFUGEE", settler = "SETTLEMENT_PARTY" }
    return mapping[faction and faction.archetypeID] or "WANDERER"
end

local function memberIDs(faction)
    local output = {}
    for npcID, present in pairs(faction and faction.memberIDs or {}) do
        local record = present == true and PNC.Registry
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then output[#output + 1] = npcID end
    end
    table.sort(output)
    return output
end

local function memberSignature(ids)
    return table.concat(ids or {}, "|")
end

function Groups.Get(groupID)
    Store.EnsureLoaded()
    return Store.Registry.groupsByID[tostring(groupID or "")]
end

function Groups.List()
    Store.EnsureLoaded()
    local output = {}
    for _, group in pairs(Store.Registry.groupsByID) do
        output[#output + 1] = group
    end
    table.sort(output, function(a, b) return a.id < b.id end)
    return output
end

function Groups.FindByFactionID(factionID)
    Store.EnsureLoaded()
    for _, group in pairs(Store.Registry.groupsByID) do
        if group.factionId == factionID then return group end
    end
    return nil
end

function Groups.Create(spec)
    if not authority() then return nil, "not_authority" end
    Store.EnsureLoaded()
    local group = Types.NormalizeGroup(spec, spec and spec.id)
    if not group then return nil, "invalid_group" end
    if Store.Registry.groupsByID[group.id] then
        return Store.Registry.groupsByID[group.id], "existing"
    end
    Store.Registry.groupsByID[group.id] = group
    if PNC.AbstractBehaviorProfile and PNC.AbstractBehaviorProfile.Build then
        PNC.AbstractBehaviorProfile.Build(group)
    end
    touch(group, "group_created")
    Locations.Arrive(group, Store.WorldAgeHours(), 0)
    Store.Emit("GROUP_CREATED", { groupId = group.id })
    return group, "created"
end

function Groups.ImportMobileFaction(factionOrID)
    if not authority() then return nil, "not_authority" end
    local faction = type(factionOrID) == "table" and factionOrID
        or PNC.Factions and PNC.Factions.Get(factionOrID) or nil
    if not faction or not PNC.Factions.IsMobileGroup(faction) then
        return nil, "not_mobile_group"
    end
    local location, reason = Locations.RegisterSite(faction.mobile.site, {
        tags = { SHELTER = true,
            SAFE = faction.archetypeID == "refugee",
            COMMERCIAL = faction.archetypeID == "trader" },
    })
    if not location then return nil, reason end
    local existing = Groups.FindByFactionID(faction.id)
    if existing then
        Groups.ReconcileMembers(existing, faction)
        return existing, "existing"
    end
    local ids = memberIDs(faction)
    local group, createReason = Groups.Create({
        id = "agroup_" .. tostring(faction.id),
        factionId = faction.id,
        homeCommunityId = nil,
        groupType = groupTypeForFaction(faction),
        memberIds = ids,
        leaderId = faction.leaderNPCID,
        -- Advanced trade/migration execution is deferred. Existing mobile
        -- factions begin with the supported foundational SCAVENGE mission.
        mission = "SCAVENGE",
        state = "IDLE",
        location = Locations.Ref(location),
        resources = { food = 50, water = 50,
            ammo = faction.archetypeID == "looter" and 50 or 15,
            medical = 10, materials = 0 },
        combatProfileDirty = true,
        combatProfileReason = "mobile_faction_import",
        diagnostics = { memberSignature = memberSignature(ids) },
    })
    if group then Groups.RefreshLOD(group, Store.WorldAgeHours()) end
    return group, createReason
end

function Groups.ReconcileMembers(groupOrID, faction)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    faction = faction or group and group.factionId and PNC.Factions
        and PNC.Factions.Get(group.factionId) or nil
    if not group or not faction then return false, "missing_group_or_faction" end
    local ids
    if group.homeCommunityId then
        ids = {}
        local community = PNC.Communities and PNC.Communities.Get
            and PNC.Communities.Get(group.homeCommunityId) or nil
        for _, npcID in ipairs(group.memberIds or {}) do
            local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
            if record and record.alive ~= false and community
                and community.memberIDs and community.memberIDs[npcID] == true then
                ids[#ids + 1] = npcID
            end
        end
        table.sort(ids)
    else
        ids = memberIDs(faction)
    end
    local signature = memberSignature(ids)
    group.diagnostics = group.diagnostics or {}
    if group.diagnostics.memberSignature == signature then
        return false, "unchanged"
    end
    group.memberIds = ids
    group.leaderId = faction.leaderNPCID
    group.diagnostics.memberSignature = signature
    Groups.MarkCombatProfileDirty(group, "membership_changed")
    touch(group, "group_members_reconciled")
    return true, "reconciled"
end

function Groups.MarkCombatProfileDirty(groupOrID, reason)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    if not group then return false end
    if group.combatProfileDirty ~= true then
        Groups.Metrics.profileInvalidations = Groups.Metrics.profileInvalidations + 1
    end
    group.combatProfileDirty = true
    group.combatProfileReason = tostring(reason or "meaningful_change")
    return true
end

function Groups.MarkMemberChanged(npcID, reason)
    local changed = 0
    for _, group in ipairs(Groups.List()) do
        for _, memberID in ipairs(group.memberIds) do
            if memberID == npcID then
                Groups.MarkCombatProfileDirty(group, reason)
                touch(group, "member_combat_data_changed")
                changed = changed + 1
                break
            end
        end
    end
    return changed
end

function Groups.GetNeeds(groupOrID)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    local faction = group and group.factionId and PNC.Factions
        and PNC.Factions.Get(group.factionId) or nil
    if faction and PNC.GroupNeeds and PNC.GroupNeeds.Ensure then
        return PNC.GroupNeeds.Ensure(faction)
    end
    return { hunger = 100, hydration = 100, fatigue = 100 }
end

function Groups.GetResourceNeeds(groupOrID)
    if PNC.AbstractResourceNeeds and PNC.AbstractResourceNeeds.Get then
        return PNC.AbstractResourceNeeds.Get(groupOrID)
    end
    return { food = 0, water = 0, ammo = 0,
        medical = 0, materials = 0 }, "resource_needs_unavailable"
end

local function rememberExpiry(map, key, expiry, now)
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
    if locationID then rememberExpiry(group.recentAvoidedLocations,
        tostring(locationID), expiry, now) end
    if hostileGroupID then rememberExpiry(group.recentHostileGroups,
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

function Groups.SetMission(groupOrID, mission, at, force)
    if not authority() then return false, "not_authority" end
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
    touch(group, "group_mission_changed")
    return true, "changed"
end

function Groups.SetState(groupOrID, state, at, endsAt)
    if not authority() then return false, "not_authority" end
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    state = tostring(state or "")
    if not group or not Config.STATES[state] then return false, "invalid_state" end
    group.state = state
    group.stateStartedAt = tonumber(at) or Store.WorldAgeHours()
    group.stateEndsAt = math.max(group.stateStartedAt, tonumber(endsAt)
        or group.stateStartedAt)
    touch(group, "group_state_changed")
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
    if not authority() then return false, "not_authority" end
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
