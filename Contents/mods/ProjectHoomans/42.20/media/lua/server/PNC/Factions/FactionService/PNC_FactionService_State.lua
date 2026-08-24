if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
Factions.Registry = Factions.Registry
    or Types.NewFactionRegistry()
Factions.Loaded = Factions.Loaded or false
Factions.Dirty = Factions.Dirty or false
Factions.IDGenerator = Factions.IDGenerator
    or function()
        return Core.GenerateID("faction")
    end

function Internal.authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

function Internal.copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

function Internal.assignTable(target, source)
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(source) do target[key] = value end
end

function Internal.finiteTimestamp(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
        or value < 0
    then
        value = tonumber(fallback) or 0
    end
    return math.max(0, value)
end

function Internal.registryRecord(factionID)
    return Types.IsValidFactionID(factionID)
        and Factions.Registry.byID[factionID] or nil
end

function Internal.isProvisionalFaction(faction)
    return type(faction) == "table"
        and type(faction.tags) == "table"
        and faction.tags.provisionalPlayerFaction == true
end


function Internal.npcRecord(npcID, allowDead)
    local record = Types.IsValidNPCID(npcID)
        and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end
    if not allowDead and record.alive == false then
        return nil, "npc_not_living"
    end
    return record
end

function Internal.touchFaction(faction)
    faction.revision = math.max(
        0,
        math.floor(tonumber(faction.revision) or 0)
    ) + 1
end

function Internal.touchRegistry()
    Factions.Registry.revision = math.max(
        0,
        math.floor(tonumber(Factions.Registry.revision) or 0)
    ) + 1
    Factions.Dirty = true
end

function Internal.commitAffiliation(record, affiliation)
    affiliation.revision = math.max(
        0,
        math.floor(tonumber(
            record.affiliation and record.affiliation.revision
        ) or 0)
    ) + 1
    record.affiliation = affiliation
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "affiliation")
    end
end

function Internal.addHistory(affiliation, factionID, at, reason)
    affiliation = Types.AppendFormerFaction(
        affiliation,
        factionID,
        at,
        reason
    )
    return affiliation.formerFactionIDs
end

function Internal.affiliationFor(record, faction)
    return Types.NormalizeAffiliation(
        record and record.affiliation,
        faction
    )
end

function Internal.normalizeRole(faction, requested)
    local role = requested
        or Archetypes.GetDefaultRole(faction.archetypeID)
    if not Types.IsValidFactionRole(role)
        or not Archetypes.IsRoleAllowed(
            faction.archetypeID,
            role
        )
    then
        return nil, "role_not_allowed"
    end
    return role
end

function Internal.normalizeRank(value)
    value = value or "member"
    if not Types.IsValidFactionRank(value) then
        return nil, "invalid_rank"
    end
    return value
end

function Internal.normalizeMembershipStatus(value)
    value = value or "member"
    if not Types.IsValidMembershipStatus(value)
        or value == "unaffiliated"
    then
        return nil, "invalid_membership_status"
    end
    return value
end

return Factions
