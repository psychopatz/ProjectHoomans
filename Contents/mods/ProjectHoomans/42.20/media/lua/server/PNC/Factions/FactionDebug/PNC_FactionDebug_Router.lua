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


local worldAgeHours = Internal.worldAgeHours
local actionResult = Internal.actionResult
local copy = Internal.copy

function Debug.PerformAction(player, args)
    local action = tostring(args and args.factionAction or "")
    local context = {
        factionID = args and args.factionID,
        targetFactionID = args and args.targetFactionID,
        npcID = args and args.npcID,
        at = worldAgeHours(),
    }
    local handlers = {
        Internal.handleCreationAction,
        Internal.handleMembershipAction,
        Internal.handleDiplomacyAction,
        Internal.handleDiagnosticAction,
        Internal.handleIncidentAction,
    }
    local handled
    local ok
    local reason
    for _, handler in ipairs(handlers) do
        handled, ok, reason = handler(player, args, action, context)
        if handled then break end
    end
    if not handled then
        ok, reason = false, "unsupported_faction_action"
    end
    return Debug.BuildSnapshot(
        context.factionID,
        context.npcID,
        actionResult(ok, reason, {
            action = action,
            factionID = context.factionID,
            npcID = context.npcID,
            resultingRevision = context.value and context.value.revision,
            groupResult = copy(context.groupResult),
        }),
        player,
        context.targetFactionID)
end

return Debug
