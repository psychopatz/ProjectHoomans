-- Server-authoritative territorial looter tolls.
--
-- Roaming looter factions retain their normal predatory behavior. Only
-- factions tagged territorialToll=true use this radius-entry demand flow.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.FactionTolls = PNC.FactionTolls or {}

local Tolls = PNC.FactionTolls
local Core = PNC.Core
local Const = PNC.Const
local Factions = PNC.Factions
local Communities = PNC.Communities
local EntityRef = PNC.EntityRef

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

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(
            0,
            tonumber(gameTime:getWorldAgeHours()) or 0
        ) or 0
end

local function playerKey(player, at)
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

local function send(player, payload)
    return PNC.Network and PNC.Network.Internal
        and PNC.Network.Internal.SendToPlayer
        and PNC.Network.Internal.SendToPlayer(
            player,
            Const.CMD_FACTION_TOLL,
            payload
        ) or false
end

local function inside(community, player)
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

local function demandAmount(community)
    local population = math.max(
        1,
        math.floor(
            tonumber(community.currentPopulation) or 1
        )
    )
    return math.max(10, math.min(50, 8 + population * 2))
end

local function eligible(faction, playerFaction, key, at)
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

local function createDemand(
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
        amount = demandAmount(community),
        createdAt = at,
        expiresAt = at + DEMAND_LIFETIME_HOURS,
    }
    Tolls.PendingByPlayerKey[key] = demand
    send(player, {
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

local function moneyItems(inventory, fullType)
    if not inventory or not inventory.getItemsFromType then
        return {}
    end
    local values = inventory:getItemsFromType(fullType, true)
    local output = {}
    if not values or not values.size or not values.get then
        return output
    end
    local index
    for index = 0, values:size() - 1 do
        output[#output + 1] = values:get(index)
    end
    return output
end

local function removeItem(inventory, item)
    local container = item and item.getContainer
        and item:getContainer() or inventory
    if container and container.Remove then
        container:Remove(item)
        return true
    end
    return false
end

local function removeMoney(player, amount)
    local inventory = player and player.getInventory
        and player:getInventory() or nil
    if not inventory then return false, 0 end
    local loose = moneyItems(inventory, "Base.Money")
    local wealth = #loose
    if wealth < amount then return false, wealth end
    local remaining = amount
    local index = 1
    while remaining > 0 and loose[index] do
        removeItem(inventory, loose[index])
        remaining = remaining - 1
        index = index + 1
    end
    return true, wealth - amount
end

local function representativeNPCID(factionID)
    local faction = Factions.Registry.byID[factionID]
    if not faction then return nil end
    local leader = faction.leaderNPCID
        and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(faction.leaderNPCID) or nil
    if leader and leader.alive ~= false then
        return leader.id
    end
    local members = {}
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            members[#members + 1] = npcID
        end
    end
    table.sort(members)
    return members[1]
end

local function applyRelationshipOutcome(
    demand,
    targetKey,
    memoryType,
    approval,
    respect,
    familiarity,
    at,
    tags
)
    local observerNPCID =
        representativeNPCID(demand.factionID)
    if not observerNPCID
        or not PNC.Relationships
        or not PNC.Relationships.ApplyEventMutation
    then
        return false
    end
    local eventID = "toll:" .. memoryType
        .. ":" .. demand.id
    return PNC.Relationships.ApplyEventMutation(
        observerNPCID,
        targetKey,
        {
            eventID = eventID,
            worldAgeHours = at,
            familiarityDelta = familiarity,
            moraleDelta = 0,
            memory = {
                id = eventID,
                type = memoryType,
                aboutKey = targetKey,
                createdAt = at,
                lastEvaluatedAt = at,
                approvalEffect = approval,
                respectEffect = respect,
                moraleEffect = 0,
                strength = 1,
                decayPerDay = 0.0075,
                permanent = false,
                shareable = true,
                knowledgeSource = "experienced",
                tags = tags,
            },
        }
    )
end

local function result(player, ok, reason, demand, fields)
    local payload = fields or {}
    payload.kind = "result"
    payload.ok = ok == true
    payload.reason = reason
    payload.demandID = demand and demand.id or nil
    payload.factionID = demand and demand.factionID or nil
    payload.factionName = demand and demand.factionName or nil
    payload.communityName =
        demand and demand.communityName or nil
    payload.amount = demand and demand.amount or 0
    send(player, payload)
    return ok, reason
end

function Tolls.HandleResponse(player, args)
    args = type(args) == "table" and args or {}
    local at = worldAgeHours()
    local key = playerKey(player, at)
    local demand = key
        and Tolls.PendingByPlayerKey[key] or nil
    if not key or not demand
        or args.demandID ~= demand.id
    then
        return result(
            player,
            false,
            "invalid_or_expired_demand",
            demand
        )
    end
    if demand.expiresAt <= at then
        Tolls.PendingByPlayerKey[key] = nil
        return result(player, false, "demand_expired", demand)
    end
    local response = tostring(args.response or "")
    if response == "pay" then
        local paid, remaining = removeMoney(
            player,
            demand.amount
        )
        if not paid then
            return result(
                player,
                false,
                "insufficient_money",
                demand,
                { reopen = true, available = remaining }
            )
        end
        Factions.PacifyForPlayer(
            demand.factionID,
            key,
            {
                worldAgeHours = at,
                durationHours =
                    PAID_PACIFICATION_HOURS,
                reason = "territorial_toll_paid",
            }
        )
        applyRelationshipOutcome(
            demand,
            key,
            "extortion_complied",
            1,
            -3,
            2,
            at,
            {
                extortion = true,
                compliance = true,
                profitable = true,
            }
        )
        Tolls.PendingByPlayerKey[key] = nil
        return result(
            player,
            true,
            "toll_paid",
            demand,
            {
                remaining = remaining,
                pacifiedUntil =
                    at + PAID_PACIFICATION_HOURS,
            }
        )
    end
    if response == "refuse" then
        local playerFaction =
            Factions.GetDiplomacyFactionForPlayerKey(key)
        if not playerFaction then
            local ensured
            ensured, _, playerFaction =
                Factions.EnsurePlayerDiplomacyFaction(
                    player,
                    { worldAgeHours = at }
                )
            if not ensured then playerFaction = nil end
        end
        if not playerFaction then
            return result(
                player,
                false,
                "player_faction_unavailable",
                demand
            )
        end
        Factions.DeclareWar(
            demand.factionID,
            playerFaction.id,
            {
                worldAgeHours = at,
                reason = "scripted",
                instigatorFactionID = demand.factionID,
            }
        )
        applyRelationshipOutcome(
            demand,
            key,
            "defied_extortion",
            -15,
            4,
            5,
            at,
            {
                extortion = true,
                defiance = true,
                threat = true,
            }
        )
        Tolls.PendingByPlayerKey[key] = nil
        return result(
            player,
            true,
            "toll_refused_war",
            demand
        )
    end
    if response == "leave" then
        Tolls.PendingByPlayerKey[key] = nil
        Tolls.DepartureByPlayerKey[key] = {
            demand = demand,
            expiresAt = at + DEPARTURE_GRACE_HOURS,
        }
        return result(
            player,
            true,
            "toll_deferred",
            demand
        )
    end
    return result(player, false, "invalid_response", demand)
end

function Tolls.Pump(now)
    now = tonumber(now) or (Core.Now and Core.Now()) or 0
    if Tolls.LastPumpAt
        and now - Tolls.LastPumpAt < PUMP_INTERVAL_MS
    then
        return 0
    end
    Tolls.LastPumpAt = now
    local at = worldAgeHours()
    local communities = Communities
        and Communities.List and Communities.List() or {}
    table.sort(communities, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    local created = 0
    if not Core.ForEachPlayer then return created end
    Core.ForEachPlayer(function(player)
        local key = playerKey(player, at)
        if not key then return end
        local pending = Tolls.PendingByPlayerKey[key]
        if pending and pending.expiresAt <= at then
            Tolls.PendingByPlayerKey[key] = nil
            local previous =
                Tolls.InsideByPlayerKey[key] or {}
            previous[pending.factionID] = nil
        end
        local previous =
            Tolls.InsideByPlayerKey[key] or {}
        local current = {}
        local playerFaction =
            Factions.GetDiplomacyFactionForPlayerKey(key)
        for _, community in ipairs(communities) do
            local faction = Factions.Registry.byID[
                community.factionID
            ]
            if not current[community.factionID]
                and eligible(
                    faction,
                    playerFaction,
                    key,
                    at
                )
                and inside(community, player)
            then
                current[community.factionID] = true
                if not previous[community.factionID]
                    and createDemand(
                        player,
                        key,
                        faction,
                        community,
                        at
                    )
                then
                    created = created + 1
                end
            end
        end
        local departure =
            Tolls.DepartureByPlayerKey[key]
        if departure then
            local demand = departure.demand
            if not demand
                or not current[demand.factionID]
            then
                Tolls.DepartureByPlayerKey[key] = nil
            elseif departure.expiresAt <= at then
                local diplomacyFaction =
                    Factions.GetDiplomacyFactionForPlayerKey(
                        key
                    )
                if diplomacyFaction then
                    Factions.DeclareWar(
                        demand.factionID,
                        diplomacyFaction.id,
                        {
                            worldAgeHours = at,
                            reason = "scripted",
                            instigatorFactionID =
                                demand.factionID,
                        }
                    )
                    applyRelationshipOutcome(
                        demand,
                        key,
                        "ignored_extortion_warning",
                        -18,
                        2,
                        5,
                        at,
                        {
                            extortion = true,
                            defiance = true,
                            trespass = true,
                        }
                    )
                    result(
                        player,
                        true,
                        "toll_departure_ignored_war",
                        demand
                    )
                end
                Tolls.DepartureByPlayerKey[key] = nil
            end
        end
        Tolls.InsideByPlayerKey[key] = current
    end)
    return created
end

return Tolls
