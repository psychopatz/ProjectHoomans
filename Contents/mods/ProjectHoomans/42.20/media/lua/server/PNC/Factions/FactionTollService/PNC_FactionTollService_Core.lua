if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionTolls = PNC.FactionTolls or {}
PNC.FactionTollServiceInternal =
    PNC.FactionTollServiceInternal or {}

local Tolls = PNC.FactionTolls
local H = PNC.FactionTollServiceInternal
local Core = PNC.Core
local Const = PNC.Const
local Factions = PNC.Factions
local Communities = PNC.Communities
local EntityRef = PNC.EntityRef

local PUMP_INTERVAL_MS = 1000
local DEMAND_LIFETIME_HOURS = 0.05
local DEPARTURE_GRACE_HOURS = 0.02
local PAID_PACIFICATION_HOURS = 24

Tolls.PendingByPlayerKey =
    Tolls.PendingByPlayerKey or {}
Tolls.InsideByPlayerKey =
    Tolls.InsideByPlayerKey or {}
Tolls.DepartureByPlayerKey =
    Tolls.DepartureByPlayerKey or {}
Tolls.LastPumpAt = Tolls.LastPumpAt or nil

local PUMP_INTERVAL_MS = 1000
local DEMAND_LIFETIME_HOURS = 0.05
local DEPARTURE_GRACE_HOURS = 0.02
local PAID_PACIFICATION_HOURS = 24

function H.WorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(
            0,
            tonumber(gameTime:getWorldAgeHours()) or 0
        ) or 0
end

function H.PlayerKey(player, at)
    if not player or not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetEntityKey
    then
        return nil
    end
    return PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "faction_toll",
        worldAgeHours = at,
    })
end

function H.Send(player, payload)
    return PNC.Network and PNC.Network.Internal
        and PNC.Network.Internal.SendToPlayer
        and PNC.Network.Internal.SendToPlayer(
            player,
            Const.CMD_FACTION_TOLL,
            payload
        ) or false
end

function H.Inside(community, player)
    return community and community.status == "active"
        and player and player.getX and player.getY
        and PNC.CommunityMath
        and PNC.CommunityMath.IsInsideHomeArea
        and PNC.CommunityMath.IsInsideHomeArea(
            community,
            player:getX(),
            player:getY(),
            player.getZ and player:getZ() or 0
        ) == true
end

function H.DemandAmount(community)
    local population = math.max(
        1,
        math.floor(
            tonumber(community.currentPopulation) or 1
        )
    )
    return math.max(10, math.min(50, 8 + population * 2))
end

function H.Eligible(faction, playerFaction, key, at)
    if not faction
        or faction.status ~= "active"
        or not Factions.IsTerritorialTollFaction(faction)
        or playerFaction and playerFaction.id == faction.id
    then
        return false
    end
    if playerFaction and (
        Factions.AreAtWar(faction.id, playerFaction.id)
        or Factions.AreAllied(faction.id, playerFaction.id)
    ) then
        return false
    end
    return not Factions.GetPlayerPacification(
        faction.id,
        key,
        at
    )
end

function H.CreateDemand(
    player,
    key,
    faction,
    community,
    at
)
    if Tolls.PendingByPlayerKey[key] then return false end
    local demand = {
        id = table.concat({
            faction.id,
            key,
            tostring(math.floor(at * 1000)),
        }, "|"),
        playerKey = key,
        factionID = faction.id,
        factionName = faction.name,
        communityID = community.id,
        communityName = community.name,
        amount = H.DemandAmount(community),
        createdAt = at,
        expiresAt = at + DEMAND_LIFETIME_HOURS,
    }
    Tolls.PendingByPlayerKey[key] = demand
    H.Send(player, {
        kind = "demand",
        demandID = demand.id,
        factionID = demand.factionID,
        factionName = demand.factionName,
        communityID = demand.communityID,
        communityName = demand.communityName,
        amount = demand.amount,
    })
    return true
end

return Tolls

