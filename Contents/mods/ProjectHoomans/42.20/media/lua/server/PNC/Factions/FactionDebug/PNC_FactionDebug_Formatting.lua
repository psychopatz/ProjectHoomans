if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Debug = PNC.FactionDebug
local Internal = Debug.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance


function Debug.FormatList()
    local lines = { "Faction Debug", "Factions:" }
    for _, faction in ipairs(Factions.List()) do
        lines[#lines + 1] = string.format(
            "  %s | %s | %s | %s",
            faction.id,
            faction.name,
            faction.archetypeID,
            faction.status
        )
    end
    if #lines == 2 then lines[#lines + 1] = "  (none)" end
    return table.concat(lines, "\n")
end

function Debug.FormatFaction(factionID)
    local faction, reason = Factions.Get(factionID)
    if not faction then
        return "Faction Debug\nStatus: " .. tostring(reason)
    end
    return table.concat({
        "Faction Debug",
        "ID: " .. faction.id,
        "Name: " .. faction.name,
        "Archetype: " .. faction.archetypeID,
        "Status: " .. faction.status,
        "Leader: " .. tostring(faction.leaderNPCID),
        "Members: " .. tostring(Core.TableSize(faction.memberIDs)),
        "Revision: " .. tostring(faction.revision),
    }, "\n")
end

function Debug.FormatMembers(factionID)
    local members, reason = Factions.GetMembers(factionID)
    local lines = {
        "Faction Members",
        "Faction: " .. tostring(factionID),
    }
    if reason then
        lines[#lines + 1] = "Status: " .. tostring(reason)
        return table.concat(lines, "\n")
    end
    for _, member in ipairs(members) do
        local affiliation = member.affiliation or {}
        lines[#lines + 1] = string.format(
            "  %s | %s | %s | %s | %s",
            member.npcID,
            member.name,
            affiliation.membershipStatus or "unknown",
            affiliation.role or "unknown",
            affiliation.rank or "unknown"
        )
    end
    if #members == 0 then lines[#lines + 1] = "  (none)" end
    return table.concat(lines, "\n")
end


return Debug
