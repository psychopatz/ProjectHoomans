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

function Tolls.Pump(now)
    now = tonumber(now) or (Core.Now and Core.Now()) or 0
    if Tolls.LastPumpAt
        and now - Tolls.LastPumpAt < PUMP_INTERVAL_MS
    then
        return 0
    end
    Tolls.LastPumpAt = now
    local at = H.WorldAgeHours()
    local communities = Communities
        and Communities.List and Communities.List() or {}
    table.sort(communities, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    local created = 0
    if not Core.ForEachPlayer then return created end
    Core.ForEachPlayer(function(player)
        local key = H.PlayerKey(player, at)
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
                and H.Eligible(
                    faction,
                    playerFaction,
                    key,
                    at
                )
                and H.Inside(community, player)
            then
                current[community.factionID] = true
                if not previous[community.factionID]
                    and H.CreateDemand(
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
                    H.ApplyRelationshipOutcome(
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
                    H.Result(
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

