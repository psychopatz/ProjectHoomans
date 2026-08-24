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


function Internal.handleDiplomacyAction(player, args, action, context)
    if action ~= "war" and action ~= "peace" and action ~= "truce"
        and action ~= "alliance" and action ~= "break_alliance"
    then return false end
    if not context.factionID or not context.targetFactionID
        or context.factionID == context.targetFactionID
    then return true, false, "select_distinct_factions" end
    local options = {
        worldAgeHours = context.at,
        instigatorFactionID = context.factionID,
    }
    local ok
    local reason
    if action == "war" then
        options.reason = "manual_debug"
        ok, reason, context.value = Factions.DeclareWar(
            context.factionID, context.targetFactionID, options)
    elseif action == "peace" then
        ok, reason, context.value = Factions.MakePeace(
            context.factionID, context.targetFactionID, options)
    elseif action == "truce" then
        options.truceUntil = context.at
            + (Balance and Balance.Get("defaultTruceHours") or 24)
        ok, reason, context.value = Factions.StartTruce(
            context.factionID, context.targetFactionID, options)
    elseif action == "alliance" then
        options.override = true
        ok, reason, context.value = Factions.FormAlliance(
            context.factionID, context.targetFactionID, options)
    else
        ok, reason, context.value = Factions.BreakAlliance(
            context.factionID, context.targetFactionID, options)
    end
    return true, ok, reason
end

return Debug
