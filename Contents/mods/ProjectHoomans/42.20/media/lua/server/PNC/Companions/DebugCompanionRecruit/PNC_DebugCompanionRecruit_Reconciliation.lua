if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}
PNC.Recruitment = PNC.Recruitment or PNC.DebugCompanionRecruit
PNC.DebugCompanionRecruitInternal =
    PNC.DebugCompanionRecruitInternal or {}

local Recruit = PNC.DebugCompanionRecruit
local H = PNC.DebugCompanionRecruitInternal
local Const = PNC.Const
local Core = PNC.Core
local Factions = PNC.Factions
local Registry = PNC.Registry
local Graph = PNC.RelationshipGraph

function Recruit.ReconcileOwned(player, record)
    if not player or not record or record.alive == false then
        return false, "npc_not_found"
    end
    if not PNC.CompanionCommands
        or not PNC.CompanionCommands.IsOwnedByPlayer
        or not PNC.CompanionCommands.IsOwnedByPlayer(record, player)
    then
        return false, "npc_not_owned"
    end
    local playerFaction = Factions.GetPlayerFaction(player)
    local npcFaction = Factions.GetNPCFaction(record.id)
    local community = PNC.Communities
        and PNC.Communities.GetNPCCommunity
        and PNC.Communities.GetNPCCommunity(record.id) or nil
    if playerFaction and npcFaction and npcFaction.id == playerFaction.id
        and community and community.factionID == playerFaction.id
    then
        H.SynchronizeRecordMembership(record, playerFaction, community)
        return true, "unchanged"
    end
    return Recruit.Assign(player, record, {
        source = "companion_membership_repair",
        endConversation = false,
        preserveOrder = true,
    })
end

return Recruit

