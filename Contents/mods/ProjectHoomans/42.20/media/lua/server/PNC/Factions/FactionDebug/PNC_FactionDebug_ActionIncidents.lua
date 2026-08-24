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


function Internal.handleIncidentAction(player, args, action, context)
    local incidentTypes = {
        incident_minor = "member_attacked_minor",
        incident_severe = "member_attacked_severe",
        incident_killed = "member_killed",
        incident_rescue = "member_rescued",
    }
    if action ~= "recalculate" and not incidentTypes[action] then
        return false
    end
    if not context.factionID or not context.targetFactionID
        or context.factionID == context.targetFactionID
    then return true, false, "select_distinct_factions" end
    local ok
    local reason
    if action == "recalculate" then
        ok, reason, context.value = Factions.RecalculateRelation(
            context.factionID, context.targetFactionID, context.at)
    else
        ok, reason, context.value = PNC.FactionIncidentService.AddIncident(
            context.factionID, context.targetFactionID,
            incidentTypes[action], {
                worldAgeHours = context.at,
                externalID = "debug:" .. action .. ":"
                    .. context.factionID .. ":" .. context.targetFactionID
                    .. ":" .. tostring(context.at),
                public = true,
                witnessed = true,
            })
    end
    return true, ok, reason
end

return Debug
