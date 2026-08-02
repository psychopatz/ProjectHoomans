-- Debug-only conversion of a neutral/hostile conversation target into the
-- current player's companion.  The caller is responsible for debug authority;
-- this service owns eligibility and canonical faction membership changes.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}

local Recruit = PNC.DebugCompanionRecruit
local Const = PNC.Const
local Core = PNC.Core
local Factions = PNC.Factions
local Registry = PNC.Registry

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
            name = "New Colony",
            renamePending = true,
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

local function forceFollow(record, player)
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
        Registry.MarkDirty(record, "debug_companion_recruit")
    end
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

function Recruit.Try(player, args)
    args = type(args) == "table" and args or {}
    if not player then return false, "player_unavailable" end
    local npcID = tostring(args.npcID or args.id or "")
    local record = npcID ~= "" and Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end
    if not Recruit.IsEligible(record) then
        return false, "npc_not_debug_recruitable"
    end
    if not Factions or not Factions.EnsurePlayerFaction then
        return false, "factions_unavailable"
    end

    local ok
    local reason
    local playerFaction
    ok, reason, playerFaction = Factions.EnsurePlayerFaction(player, {
        worldAgeHours = worldAgeHours(),
        tags = { debugCreated = true },
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
        worldAgeHours = worldAgeHours(),
        joinedAt = worldAgeHours(),
    }
    if affiliation and affiliation.factionID then
        ok, reason = Factions.TransferNPC(record.id, playerFaction.id, options)
    else
        ok, reason = Factions.AddNPC(playerFaction.id, record.id, options)
    end
    if not ok then return false, reason or "membership_change_failed" end

    local at = worldAgeHours()
    local community
    local communityCreated
    community, communityCreated, reason = ensureCommunity(
        playerFaction,
        player,
        record,
        at
    )
    if not community then return false, reason or "community_assignment_failed" end

    forceFollow(record, player)
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "debug_companion_recruit")
    end

    if PNC.IndividualNeeds and PNC.IndividualNeeds.Ensure then
        PNC.IndividualNeeds.Ensure(record)
    end
    if PNC.ConversationScene and PNC.ConversationScene.End then
        PNC.ConversationScene.End(
            record,
            Registry.GetLiveZombie and Registry.GetLiveZombie(record.id),
            nil,
            "debug_recruited"
        )
    end
    saveRecruitment()
    if Core and Core.LogInfo then
        Core.LogInfo("PNC debug recruited npc=" .. tostring(record.id)
            .. " player=" .. tostring(player and player.getUsername
                and player:getUsername() or "unknown"))
    end
    return true, "recruited", {
        npcID = record.id,
        factionID = playerFaction.id,
        communityID = community.id,
        communityCreated = communityCreated == true,
    }
end

return Recruit
