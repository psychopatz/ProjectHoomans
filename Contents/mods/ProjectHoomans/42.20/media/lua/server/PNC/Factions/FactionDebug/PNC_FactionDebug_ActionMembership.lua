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


function Internal.handleMembershipAction(player, args, action, context)
    local ok
    local reason
    if action == "assign" then
        ok, reason, context.value = Factions.AddNPC(
            context.factionID, context.npcID,
            { membershipStatus = "member", joinedAt = context.at })
    elseif action == "transfer" then
        ok, reason, context.value = Factions.TransferNPC(
            context.npcID, context.factionID,
            { membershipStatus = "member", worldAgeHours = context.at })
    elseif action == "remove" then
        ok, reason, context.value = Factions.RemoveNPC(
            context.factionID, context.npcID, "removed", context.at)
    elseif action == "leader" then
        ok, reason, context.value = Factions.SetLeader(
            context.factionID, context.npcID, context.at)
    elseif action == "role" then
        ok, reason, context.value = Factions.SetNPCRole(
            context.npcID, tostring(args and args.role or ""))
    elseif action == "rank" then
        ok, reason, context.value = Factions.SetNPCRank(
            context.npcID, tostring(args and args.rank or ""))
    elseif action == "archive" then
        ok, reason, context.value = Factions.Archive(
            context.factionID, "debug_archive", context.at)
    else
        return false
    end
    return true, ok, reason
end

return Debug
