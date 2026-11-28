if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractGroups = PNC.AbstractGroups or {}
PNC.AbstractGroupManagerInternal =
    PNC.AbstractGroupManagerInternal or {}

local Groups = PNC.AbstractGroups
local H = PNC.AbstractGroupManagerInternal
local Store = PNC.HoomansWorldView
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Locations = PNC.AbstractLocations
local Core = PNC.Core
local Const = PNC.Const

local function recoverMembersFromCoreActors(group)
    local coreActors = PsychopatzCore and PsychopatzCore.Actors or nil
    local coreReg = coreActors and coreActors.DefaultRegistry or nil
    if not coreReg or type(coreReg.records) ~= "table" then
        return {}
    end
    local recovered = {}
    local targetGroupID = tostring(group and group.id or "")
    local targetFactionID = tostring(group and group.factionId or "")
    for actorID, actor in pairs(coreReg.records) do
        if type(actor) == "table" and actor.alive ~= false then
            local status = string.lower(tostring(actor.status or actor.state or "active"))
            if status ~= "dead" and status ~= "deceased" and status ~= "removed" then
                local sw = type(actor.extensions) == "table"
                    and actor.extensions["PsychopatzCore.SurvivorWorld"] or nil
                if type(sw) == "table" then
                    local gMatch = targetGroupID ~= "" and tostring(sw.groupID or "") == targetGroupID
                    local fMatch = targetFactionID ~= "" and tostring(sw.factionID or "") == targetFactionID
                    if gMatch or fMatch then
                        recovered[#recovered + 1] = tostring(actor.actorId or actorID)
                    end
                end
            end
        end
    end
    table.sort(recovered)
    return recovered
end

function Groups.ReconcileMembers(groupOrID, faction)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    faction = faction or group and group.factionId and PNC.Factions
        and PNC.Factions.Get(group.factionId) or nil
    if not group then return false, "missing_group" end
    local ids
    local coreProvider = PNC.Persistence and PNC.Persistence.CoreProvider or nil
    if group.homeCommunityId then
        ids = {}
        local sourceMembers = (type(group.memberIds) == "table" and #group.memberIds > 0)
            and group.memberIds
            or (type(group.memberActorIDs) == "table" and group.memberActorIDs)
            or {}
        for _, npcID in ipairs(sourceMembers) do
            local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
            local isAlive = (record and record.alive ~= false)
                or (not record
                    and coreProvider
                    and type(coreProvider.IsAliveCoreActor) == "function"
                    and coreProvider.IsAliveCoreActor(npcID, PsychopatzCore))
            -- Keep every living group member (starter/bootstrap groups carry
            -- homeCommunityId while owning their own Core actors that are not
            -- necessarily duplicated in community.memberIDs).
            if isAlive then
                ids[#ids + 1] = npcID
            end
        end
        if #ids == 0 then
            ids = recoverMembersFromCoreActors(group)
        end
        table.sort(ids)
    else
        ids = faction and H.MemberIDs(faction) or {}
        if #ids == 0 then
            ids = recoverMembersFromCoreActors(group)
        end
    end
    local signature = H.MemberSignature(ids)
    group.diagnostics = group.diagnostics or {}
    -- Event-driven dissolution: if ANY group has 0 living members in both
    -- Hoomans and Core after recovery, dissolve it immediately instead of
    -- writing a 0-member ghost back to Core SurvivorWorld.
    if #ids == 0 then
        group.memberIds = ids
        group.memberActorIDs = ids
        group.diagnostics.memberSignature = signature
        if Locations and type(Locations.Depart) == "function" then
            pcall(Locations.Depart, group, Store and Store.WorldAgeHours and Store.WorldAgeHours() or 0)
        end
        if PNC.CoreSurvivorWorldAdapter
            and type(PNC.CoreSurvivorWorldAdapter.RemoveGroup) == "function"
        then
            pcall(PNC.CoreSurvivorWorldAdapter.RemoveGroup, group.id, "dissolved_empty_group")
        end
        if Store and Store.Registry and type(Store.Registry.groupsByID) == "table" then
            Store.Registry.groupsByID[group.id] = nil
            if type(Store.Touch) == "function" then
                Store.Touch("group_dissolved_empty")
            end
        end
        return true, "dissolved_empty"
    end
    if group.diagnostics.memberSignature == signature
        and #(group.memberIds or {}) == #ids
    then
        return false, "unchanged"
    end
    group.memberIds = ids
    group.memberActorIDs = ids
    group.leaderId = faction and faction.leaderNPCID or group.leaderId
    group.diagnostics.memberSignature = signature
    Groups.MarkCombatProfileDirty(group, "membership_changed")
    H.Touch(group, "group_members_reconciled")
    if PNC.CoreSurvivorWorldAdapter
        and type(PNC.CoreSurvivorWorldAdapter.CommitGroup) == "function"
    then
        pcall(PNC.CoreSurvivorWorldAdapter.CommitGroup, group, "group_members_reconciled")
    end
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

