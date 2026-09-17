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

function Recruit.ReconcileOwned(player, record, options)
    options = type(options) == "table" and options or {}
    local ownershipContext = options.ownershipContext
    local playerFaction = options.playerFaction
    local npcFaction
    local ownershipConfirmed
    if not player or not record or record.alive == false then
        return false, "npc_not_found"
    end
    ownershipConfirmed = PNC.CompanionCommands
        and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(
            record, player, ownershipContext)
    if not ownershipConfirmed and ownershipContext
        and ownershipContext.playerKey and playerFaction and Factions
        and Factions.GetNPCFaction
    then
        npcFaction = Factions.GetNPCFaction(record.id)
        ownershipConfirmed = npcFaction
            and tostring(npcFaction.id or "")
                == tostring(playerFaction.id or "")
    end
    if not ownershipConfirmed then
        return false, "npc_not_owned"
    end
    playerFaction = playerFaction or Factions.GetPlayerFaction(player)
    npcFaction = npcFaction or Factions.GetNPCFaction(record.id)
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
