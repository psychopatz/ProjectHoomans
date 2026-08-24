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

Groups.Metrics = Groups.Metrics or { profileInvalidations = 0 }

function H.Authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

function H.Touch(group, reason)
    group.revision = (tonumber(group.revision) or 0) + 1
    Store.Touch(reason)
end

function H.GroupTypeForFaction(faction)
    local mapping = { looter = "LOOTER", trader = "TRADER",
        refugee = "REFUGEE", settler = "SETTLEMENT_PARTY" }
    return mapping[faction and faction.archetypeID] or "WANDERER"
end

function H.MemberIDs(faction)
    local output = {}
    for npcID, present in pairs(faction and faction.memberIDs or {}) do
        local record = present == true and PNC.Registry
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then output[#output + 1] = npcID end
    end
    table.sort(output)
    return output
end

function H.MemberSignature(ids)
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
    if not H.Authority() then return nil, "not_authority" end
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
    H.Touch(group, "group_created")
    Locations.Arrive(group, Store.WorldAgeHours(), 0)
    Store.Emit("GROUP_CREATED", { groupId = group.id })
    return group, "created"
end

