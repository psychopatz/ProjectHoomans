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
    if not player or not player.getUsername then return false, "player_unavailable" end
    local username = player:getUsername()
    if not username or username == "" then return false, "player_unavailable" end
    if not record or record.alive == false then return false, "npc_not_found" end
    if not Factions or not Factions.EnsurePlayerFaction then
        return false, "factions_unavailable"
    end
    local provider = PNC.Persistence and PNC.Persistence.CoreProvider
    if not provider then return false, "core_provider_unavailable" end
    if not record.coreBacked or not record.coreActorID then
        local adopted, adoptionReason = provider.EnsureActor(record, PsychopatzCore)
        if not adopted then return false, adoptionReason end
    end
    local at = H.WorldAgeHours()
    local pending = record.runtime and record.runtime.pendingRecruitmentRollback
    if pending then
        local restored = H.RollbackMembership(record, pending.affiliation, at)
        if not restored then return false, "recruitment_rollback_pending" end
        record.runtime.pendingRecruitmentRollback = nil
    end
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
    local characterUUID = H.PlayerCharacterUUID(player)
    if PNC.PlayerCharacters and not characterUUID then
        return false, "player_character_unavailable"
    end
    local affiliation = Factions.GetNPCAffiliation
        and Factions.GetNPCAffiliation(record.id) or nil
    local previous = {
        affiliation = Core.DeepCopy(record.affiliation),
        recruited = record.recruited,
        tacticalClass = record.tacticalClass,
        ownerUsername = record.ownerUsername,
        ownerOnlineID = record.ownerOnlineID,
        ownerCharacterUUID = record.ownerCharacterUUID,
        orderSpec = Core.DeepCopy(record.orderSpec),
        hostility = Core.DeepCopy(record.hostility),
    }
    local function rollback(failure)
        local restored, reason = H.RollbackMembership(record, previous.affiliation, at)
        record.recruited = previous.recruited
        record.tacticalClass = previous.tacticalClass
        record.ownerUsername = previous.ownerUsername
        record.ownerOnlineID = previous.ownerOnlineID
        record.ownerCharacterUUID = previous.ownerCharacterUUID
        record.orderSpec = previous.orderSpec
        record.hostility = previous.hostility
        if not restored then
            record.runtime.pendingRecruitmentRollback = { affiliation = previous.affiliation }
            Core.LogWarn("PNC recruitment rollback pending id=" .. record.id
                .. " reason=" .. tostring(reason))
            return false, "recruitment_rollback_pending"
        end
        return false, failure
    end
    local options = {
        role = "civilian",
        rank = "member",
        membershipStatus = "member",
        worldAgeHours = at,
        joinedAt = at,
        deferBehavior = true,
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
        return rollback(reason or "community_assignment_failed")
    end
    local source = tostring(args.source or "companion_recruit")
    record.recruited = true
    record.tacticalClass = Const.TACTICAL_CLASS_COLONIST
    record.ownerUsername = username
    record.ownerOnlineID = player.getOnlineID and player:getOnlineID() or nil
    record.ownerCharacterUUID = characterUUID
    local synced, syncReason = provider.SyncPromotedCoreActorToCore(
        record, PsychopatzCore, { syncAffiliation = true }
    )
    if not synced then
        return rollback(syncReason or "core_recruitment_commit_failed")
    end
    if PNC.OrderSystem and PNC.OrderSystem.SetHostility then
        PNC.OrderSystem.SetHostility(record, PNC.Types.DefaultHostility(record.tacticalClass))
    end
    if args.preserveOrder == true then
        H.PreserveOwnedState(record, player, source)
    else
        H.ForceFollow(record, player, source)
    end
    if args.publish ~= false and PNC.Network and PNC.Network.BroadcastRecord then
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
