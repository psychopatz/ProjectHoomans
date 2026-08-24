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

function H.PlayerPosition(player)
    return {
        x = player and player.getX and player:getX() or 0,
        y = player and player.getY and player:getY() or 0,
        z = player and player.getZ and player:getZ() or 0,
        radius = 12,
    }
end

function H.EnsureCommunity(playerFaction, player, record, at)
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
            home = H.PlayerPosition(player),
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

return Recruit

