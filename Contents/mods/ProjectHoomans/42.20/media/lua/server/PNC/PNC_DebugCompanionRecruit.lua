-- Debug-only conversion of a neutral/hostile conversation target into the
-- current player's companion.  The caller is responsible for debug authority;
-- this service owns eligibility and canonical faction membership changes.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}

local Recruit = PNC.DebugCompanionRecruit
PNC.Recruitment = PNC.Recruitment or Recruit
local Const = PNC.Const
local Core = PNC.Core
local Factions = PNC.Factions
local Registry = PNC.Registry
local Graph = PNC.RelationshipGraph

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0)
        or 0
end

function Recruit.IsEligible(record)
    if not record or record.alive == false or record.recruited == true then
        return false
    end
    local faction = PNC.Types and PNC.Types.NormalizeFaction
        and PNC.Types.NormalizeFaction(record.faction)
        or tostring(record.faction or "")
    return faction == Const.FACTION_NEUTRAL
        or faction == Const.FACTION_HOSTILE
end

-- Recruitment is an action requirement, not another relationship axis.  The
-- normal route is the upper-right (approval + respect) region; a frightened
-- NPC may also accept when respect is exceptionally high even though approval
-- is negative.  Hostile audience classification is always rejected by the
-- conversation path, regardless of its coordinates.
function Recruit.EvaluateConversation(record, relationship)
    relationship = type(relationship) == "table" and relationship or {}
    if not record or record.alive == false then
        return { eligible = false, reason = "npc_unavailable" }
    end
    if record.recruited == true then
        return { eligible = false, reason = "already_recruited" }
    end
    local faction = PNC.Types and PNC.Types.NormalizeFaction
        and PNC.Types.NormalizeFaction(record.faction)
        or tostring(record.faction or "")
    if faction == Const.FACTION_HOSTILE then
        return { eligible = false, reason = "hostile_audience" }
    end
    local approval = tonumber(relationship.approval) or 0
    local respect = tonumber(relationship.respect) or 0
    local personality = record.personality or record.socialProfile or {}
    local loyalty = math.max(0, math.min(1,
        tonumber(personality.loyalty) or 0))
    local bravery = math.max(0, math.min(1,
        tonumber(personality.bravery) or 0))
    local loyaltyPenalty = loyalty * 20
    local admireScore = respect * 0.55 + approval * 0.45
        - loyaltyPenalty
    local fearScore = respect * 0.70
        + math.max(0, -approval) * 0.30
        - bravery * 25 - loyaltyPenalty
    local normal = approval >= 25 and respect >= 35 and admireScore >= 60
    local fear = approval <= -30 and respect >= 70
        and fearScore >= 60 and bravery < 0.85
    local affiliation = PNC.Factions and PNC.Factions.GetNPCAffiliation
        and PNC.Factions.GetNPCAffiliation(record.id) or nil
    local leader = record.leader == true
        or affiliation and (affiliation.role == "leader"
            or affiliation.rank == "leader" or affiliation.role == "chief")
    if leader and not record.leaderAlone then
        normal, fear = false, false
    end
    local route = normal and "admire" or fear and "fear" or nil
    local evaluation = Graph and Graph.Evaluate
        and Graph.Evaluate(approval, respect, "recruit") or nil
    return {
        eligible = route ~= nil,
        reason = route and "eligible"
            or leader and "leader_active"
            or "relationship_threshold",
        route = route,
        approval = approval,
        respect = respect,
        attitude = evaluation and evaluation.attitude or nil,
        score = evaluation and evaluation.finalScore or nil,
        threshold = evaluation and evaluation.threshold or 35,
        admireScore = admireScore,
        fearScore = fearScore,
        loyaltyPenalty = loyaltyPenalty,
        leaderBlocked = leader == true and route == nil,
    }
end

local function playerPosition(player)
    return {
        x = player and player.getX and player:getX() or 0,
        y = player and player.getY and player:getY() or 0,
        z = player and player.getZ and player:getZ() or 0,
        radius = 12,
    }
end

local function ensureCommunity(playerFaction, player, record, at)
    local Communities = PNC.Communities
    if not Communities or not Communities.GetForFaction
        or not Communities.Create or not Communities.AddNPC
    then
        return nil, false, "communities_unavailable"
    end
    local community
    for _, value in ipairs(
        Communities.GetForFaction(playerFaction.id) or {}
    ) do
        if value.status == "active" then
            community = value
            break
        end
    end
    local created = false
    if not community then
        local ok
        local reason
        ok, reason, community = Communities.Create({
            factionID = playerFaction.id,
            name = playerFaction.name,
            renamePending = false,
            mode = "camped",
            createdAt = at,
            home = playerPosition(player),
        })
        if not ok then return nil, false, reason end
        created = true
    end
    local ok, reason = Communities.AddNPC(community.id, record.id, {
        communityRole = "resident",
        joinedAt = at,
    })
    if not ok and reason ~= "unchanged" then
        return nil, created, reason
    end
    return community, created, nil
end

local function forceFollow(record, player, reason)
    local username = player and player.getUsername
        and player:getUsername() or nil
    local onlineID = player and player.getOnlineID
        and player:getOnlineID() or nil
    record.recruited = true
    record.faction = Const.FACTION_COLONIST
    record.ownerUsername = username
    record.ownerOnlineID = onlineID
    record.runtime = record.runtime or {}
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = username,
            ownerOnlineID = onlineID,
        })
    else
        record.orderSpec = {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = username,
            ownerOnlineID = onlineID,
        }
    end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "companion_recruit")
    end
end

local function preserveOwnedState(record, player, reason)
    record.recruited = true
    record.faction = Const.FACTION_COLONIST
    if not record.ownerUsername and player and player.getUsername then
        record.ownerUsername = player:getUsername()
    end
    if record.ownerOnlineID == nil and player and player.getOnlineID then
        record.ownerOnlineID = player:getOnlineID()
    end
    if Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "companion_membership_repair")
    end
end

local function synchronizeRecordMembership(record, faction, community)
    if not record or not faction or not community then return false end
    record.affiliation = record.affiliation or {}
    local changed = tostring(record.affiliation.factionID or "")
            ~= tostring(faction.id or "")
        or tostring(record.affiliation.communityID or "")
            ~= tostring(community.id or "")
        or tostring(record.factionId or "") ~= tostring(faction.id or "")
        or tostring(record.communityId or "") ~= tostring(community.id or "")
    record.affiliation.factionID = faction.id
    record.affiliation.factionId = faction.id
    record.affiliation.communityID = community.id
    record.affiliation.communityId = community.id
    record.factionId = faction.id
    record.communityId = community.id
    if changed and Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "canonical_membership_sync")
    end
    return changed
end

-- Recruitment crosses three authoritative stores: the NPC record, faction
-- membership, and community membership. Commit all three at the successful
-- boundary so a restart cannot expose a half-recruited NPC or recreate the
-- first-colony naming prompt from stale ModData.
local function saveRecruitment()
    if Registry and Registry.Save then Registry.Save() end
    if Factions and Factions.Save then Factions.Save() end
    if PNC.Communities and PNC.Communities.Save then
        PNC.Communities.Save()
    end
    if GlobalModData and GlobalModData.save then GlobalModData.save() end
end


-- Shared authoritative assignment boundary used by both normal/debug
-- recruitment and character-start companions. Eligibility belongs to the
-- caller; this function owns the cross-store faction/community transaction.
function Recruit.Assign(player, record, args)
    args = type(args) == "table" and args or {}
    if not player then return false, "player_unavailable" end
    if not record or record.alive == false then return false, "npc_not_found" end
    if not Factions or not Factions.EnsurePlayerFaction then
        return false, "factions_unavailable"
    end
    local at = worldAgeHours()
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
    community, communityCreated, reason = ensureCommunity(
        playerFaction, player, record, at
    )
    if not community then
        return false, reason or "community_assignment_failed"
    end
    synchronizeRecordMembership(record, playerFaction, community)
    local source = tostring(args.source or "companion_recruit")
    if args.preserveOrder == true then
        preserveOwnedState(record, player, source)
    else
        forceFollow(record, player, source)
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
    saveRecruitment()
    return true, "recruited", {
        npcID = record.id,
        factionID = playerFaction.id,
        communityID = community.id,
        communityCreated = communityCreated == true,
    }
end

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
        synchronizeRecordMembership(record, playerFaction, community)
        return true, "unchanged"
    end
    return Recruit.Assign(player, record, {
        source = "companion_membership_repair",
        endConversation = false,
        preserveOrder = true,
    })
end

function Recruit.Try(player, args)
    args = type(args) == "table" and args or {}
    if not player then return false, "player_unavailable" end
    local npcID = tostring(args.npcID or args.id or "")
    local record = npcID ~= "" and Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end
    if not Recruit.IsEligible(record) then
        return false, "npc_not_debug_recruitable"
    end
    local ok
    local reason
    local result
    ok, reason, result = Recruit.Assign(player, record, {
        source = "debug_companion_recruit",
        tags = { debugCreated = true },
    })
    if not ok then return false, reason end
    if Core and Core.LogInfo then
        Core.LogInfo("PNC debug recruited npc=" .. tostring(record.id)
            .. " player=" .. tostring(player and player.getUsername
                and player:getUsername() or "unknown"))
    end
    return true, "recruited", result
end

function Recruit.TryConversation(player, args, relationship)
    args = type(args) == "table" and args or {}
    local npcID = tostring(args.npcID or args.id or "")
    local record = npcID ~= "" and Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end
    local evaluation = Recruit.EvaluateConversation(record, relationship)
    if not evaluation.eligible then
        return false, evaluation.reason, evaluation
    end
    local ok, reason, result = Recruit.Try(player, { npcID = npcID })
    if not ok then return false, reason, result end
    result = type(result) == "table" and result or {}
    result.route = evaluation.route
    result.relationship = {
        approval = evaluation.approval,
        respect = evaluation.respect,
        attitude = evaluation.attitude,
    }
    return true, reason, result
end

return Recruit
