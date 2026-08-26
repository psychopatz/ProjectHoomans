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
function Factions.Get(factionID)
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    return faction and Internal.copy(faction) or nil,
        faction and nil or "faction_not_found"
end

function Factions.GetPresentation(factionID)
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        status = faction.status,
        emblem = Internal.copy(faction.emblem),
    }
end

function Factions.List(options)
    local output = {}
    options = type(options) == "table" and options or {}
    Factions.EnsureLoaded()
    for _, faction in pairs(Factions.Registry.byID) do
        if options.includeProvisional == true
            or not Internal.isProvisionalFaction(faction)
        then
            output[#output + 1] = Internal.copy(faction)
        end
    end
    table.sort(output, function(left, right)
        if left.name ~= right.name then return left.name < right.name end
        return left.id < right.id
    end)
    return output
end

function Factions.GetByArchetype(archetypeID)
    local output = {}
    Factions.EnsureLoaded()
    if not Archetypes.Exists(archetypeID) then
        return output, "unknown_archetype"
    end
    for factionID, _ in pairs(
        Factions.Registry.byArchetype[archetypeID] or {}
    ) do
        if Factions.Registry.byID[factionID]
            and not Internal.isProvisionalFaction(
                Factions.Registry.byID[factionID]
            )
        then
            output[#output + 1] =
                Internal.copy(Factions.Registry.byID[factionID])
        end
    end
    table.sort(output, function(left, right)
        return left.id < right.id
    end)
    return output
end

function Factions.GetNPCAffiliation(npcID)
    Factions.EnsureLoaded()
    local record, reason = Internal.npcRecord(npcID, true)
    if not record then return nil, reason end
    return Internal.copy(Types.NormalizeAffiliation(
        record.affiliation,
        record.affiliation and record.affiliation.factionID
            and Internal.registryRecord(record.affiliation.factionID)
            or nil
    ))
end

function Factions.GetNPCFaction(npcID)
    local affiliation, reason =
        Factions.GetNPCAffiliation(npcID)
    if not affiliation then return nil, reason end
    if not affiliation.factionID then
        return nil, "unaffiliated"
    end
    return Factions.Get(affiliation.factionID)
end

function Factions.IsMember(factionID, npcID)
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false end
    local record = Internal.npcRecord(npcID, true)
    return record ~= nil
        and record.affiliation ~= nil
        and record.affiliation.factionID == factionID
end

function Factions.GetMembers(factionID)
    local output = {}
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return output, "faction_not_found" end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record then
            output[#output + 1] = {
                npcID = npcID,
                name = tostring(record.name or npcID),
                alive = record.alive ~= false,
                affiliation = Internal.copy(record.affiliation),
            }
        end
    end
    table.sort(output, function(left, right)
        return left.npcID < right.npcID
    end)
    return output
end

function Factions.GetLeader(factionID)
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    if not faction.leaderNPCID then return nil, "no_leader" end
    local record = PNC.Registry.Get(faction.leaderNPCID)
    if not record then return nil, "leader_not_found" end
    return {
        npcID = record.id,
        name = tostring(record.name or record.id),
        alive = record.alive ~= false,
        affiliation = Internal.copy(record.affiliation),
    }
end

function Factions.GetArchetype(archetypeID)
    return Archetypes.Get(archetypeID)
end

function Factions.GetAllowedRoles(archetypeID)
    local archetype = Archetypes.Get(archetypeID)
    return archetype and Internal.copy(archetype.allowedRoles)
        or nil, archetype and nil or "unknown_archetype"
end

function Factions.GetFactionID(record)
    return type(record) == "table"
        and record.affiliation
        and record.affiliation.factionID
        or nil
end

return Factions
