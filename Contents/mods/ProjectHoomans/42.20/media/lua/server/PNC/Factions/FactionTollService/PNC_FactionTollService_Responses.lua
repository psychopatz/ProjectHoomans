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

function H.Result(player, ok, reason, demand, fields)
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
    H.Send(player, payload)
    return ok, reason
end

function Tolls.HandleResponse(player, args)
    args = type(args) == "table" and args or {}
    local at = H.WorldAgeHours()
    local key = H.PlayerKey(player, at)
    local demand = key
        and Tolls.PendingByPlayerKey[key] or nil
    if not key or not demand
        or args.demandID ~= demand.id
    then
        return H.Result(
            player,
            false,
            "invalid_or_expired_demand",
            demand
        )
    end
    if demand.expiresAt <= at then
        Tolls.PendingByPlayerKey[key] = nil
        return H.Result(player, false, "demand_expired", demand)
    end
    local response = tostring(args.response or "")
    if response == "pay" then
        local paid, remaining = H.RemoveMoney(
            player,
            demand.amount
        )
        if not paid then
            return H.Result(
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
        H.ApplyRelationshipOutcome(
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
        return H.Result(
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
            return H.Result(
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
        H.ApplyRelationshipOutcome(
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
        return H.Result(
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
        return H.Result(
            player,
            true,
            "toll_deferred",
            demand
        )
    end
    return H.Result(player, false, "invalid_response", demand)
end

return Tolls

