-- AI faction leadership selection and succession.
--
-- Player-owned factions retain their player-membership leadership flow. This
-- service owns only NPC leaders for active AI factions, keeping succession
-- separate from faction membership and community placement systems.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.FactionLeadership = PNC.FactionLeadership or {}

local Leadership = PNC.FactionLeadership
local Factions = PNC.Factions
local Core = PNC.Core

local RANK_PRIORITY = {
    leader = 5,
    second = 4,
    officer = 3,
    senior = 2,
    member = 1,
}

local function authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

local function worldAgeHours(value)
    value = tonumber(value)
    if value and value == value
        and value ~= math.huge and value ~= -math.huge
    then
        return math.max(0, value)
    end
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(
            0,
            tonumber(gameTime:getWorldAgeHours()) or 0
        ) or 0
end

function Leadership.IsAIFaction(faction)
    return type(faction) == "table"
        and faction.status == "active"
        and faction.ownerPlayerKey == nil
end

local function candidateFor(faction, npcID)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    local affiliation = record and record.affiliation or nil
    if not record or record.alive == false
        or record.recruited == true
        or type(affiliation) ~= "table"
        or affiliation.factionID ~= faction.id
        or affiliation.membershipStatus ~= "member"
    then
        return nil
    end
    return {
        id = tostring(npcID),
        rank = RANK_PRIORITY[affiliation.rank] or 0,
        joinedAt = tonumber(affiliation.joinedAt) or 0,
    }
end

function Leadership.SelectSuccessor(factionID)
    if not Factions or not Factions.Get then return nil end
    local faction = Factions.Get(factionID)
    if not Leadership.IsAIFaction(faction) then return nil end
    local candidates = {}
    for npcID, present in pairs(faction.memberIDs or {}) do
        if present == true then
            local candidate = candidateFor(faction, npcID)
            if candidate then
                candidates[#candidates + 1] = candidate
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.rank ~= right.rank then
            return left.rank > right.rank
        end
        if left.joinedAt ~= right.joinedAt then
            return left.joinedAt < right.joinedAt
        end
        return left.id < right.id
    end)
    return candidates[1] and candidates[1].id or nil
end

function Leadership.EnsureLeader(factionID, reason, at)
    if not authority() then return false, "not_authority" end
    if not Factions or not Factions.Get then
        return false, "factions_unavailable"
    end
    local faction = Factions.Get(factionID)
    if not Leadership.IsAIFaction(faction) then
        return false, "player_faction_ignored"
    end
    local current = faction.leaderNPCID
        and candidateFor(faction, faction.leaderNPCID) or nil
    if current then return false, "leader_valid", current.id end
    local successor = Leadership.SelectSuccessor(faction.id)
    if not successor then return false, "no_eligible_successor" end
    local ok, result = Factions.SetLeader(
        faction.id,
        successor,
        worldAgeHours(at)
    )
    if not ok then return false, result end
    return true, tostring(reason or "leader_succeeded"), successor
end

function Leadership.OnMemberDeparture(
    factionID,
    reason,
    at
)
    return Leadership.EnsureLeader(factionID, reason, at)
end

return Leadership
