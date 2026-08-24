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
        ids = H.MemberIDs(faction)
    end
    local signature = H.MemberSignature(ids)
    group.diagnostics = group.diagnostics or {}
    if group.diagnostics.memberSignature == signature then
        return false, "unchanged"
    end
    group.memberIds = ids
    group.leaderId = faction.leaderNPCID
    group.diagnostics.memberSignature = signature
    Groups.MarkCombatProfileDirty(group, "membership_changed")
    H.Touch(group, "group_members_reconciled")
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
                H.Touch(group, "member_combat_data_changed")
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
    return { hunger = 100, thirst = 100, fatigue = 100 }
end

function Groups.GetResourceNeeds(groupOrID)
    if PNC.AbstractResourceNeeds and PNC.AbstractResourceNeeds.Get then
        return PNC.AbstractResourceNeeds.Get(groupOrID)
    end
    return { food = 0, water = 0, ammo = 0,
        medical = 0, materials = 0 }, "resource_needs_unavailable"
end

