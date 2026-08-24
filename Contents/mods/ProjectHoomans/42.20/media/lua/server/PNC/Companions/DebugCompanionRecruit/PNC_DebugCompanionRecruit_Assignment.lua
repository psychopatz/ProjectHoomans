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

function Recruit.Assign(player, record, args)
    args = type(args) == "table" and args or {}
    if not player then return false, "player_unavailable" end
    if not record or record.alive == false then return false, "npc_not_found" end
    if not Factions or not Factions.EnsurePlayerFaction then
        return false, "factions_unavailable"
    end
    local at = H.WorldAgeHours()
    local ok
    local reason
    local playerFaction
    ok, reason, playerFaction = Factions.EnsurePlayerFaction(player, {
        worldAgeHours = at,
        tags = args.tags,
    })
    if not ok or not playerFaction then
        return false, reason or "player_faction_unavailable"
    end
    local affiliation = Factions.GetNPCAffiliation
        and Factions.GetNPCAffiliation(record.id) or nil
    local options = {
        role = "civilian",
        rank = "member",
        membershipStatus = "member",
        worldAgeHours = at,
        joinedAt = at,
    }
    if affiliation and affiliation.factionID == playerFaction.id then
        ok, reason = Factions.AddNPC(playerFaction.id, record.id, options)
    elseif affiliation and affiliation.factionID then
        ok, reason = Factions.TransferNPC(record.id, playerFaction.id, options)
    else
        ok, reason = Factions.AddNPC(playerFaction.id, record.id, options)
    end
    if not ok and reason ~= "unchanged" then
        return false, reason or "membership_change_failed"
    end

    local community
    local communityCreated
    community, communityCreated, reason = H.EnsureCommunity(
        playerFaction, player, record, at
    )
    if not community then
        return false, reason or "community_assignment_failed"
    end
    H.SynchronizeRecordMembership(record, playerFaction, community)
    local source = tostring(args.source or "companion_recruit")
    if args.preserveOrder == true then
        H.PreserveOwnedState(record, player, source)
    else
        H.ForceFollow(record, player, source)
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, source)
    end
    if PNC.IndividualNeeds and PNC.IndividualNeeds.Ensure then
        PNC.IndividualNeeds.Ensure(record)
    end
    if PNC.ProvisionScheduler and PNC.ProvisionScheduler.MarkAllDirty then
        PNC.ProvisionScheduler.MarkAllDirty(record)
    end
    if args.endConversation ~= false
        and PNC.ConversationScene and PNC.ConversationScene.End
    then
        PNC.ConversationScene.End(
            record,
            Registry.GetLiveZombie and Registry.GetLiveZombie(record.id),
            nil,
            source
        )
    end
    H.SaveRecruitment()
    return true, "recruited", {
        npcID = record.id,
        factionID = playerFaction.id,
        communityID = community.id,
        communityCreated = communityCreated == true,
    }
end

return Recruit

