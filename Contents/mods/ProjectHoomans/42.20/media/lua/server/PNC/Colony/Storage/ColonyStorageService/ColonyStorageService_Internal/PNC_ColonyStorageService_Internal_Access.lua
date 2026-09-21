if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal
local Repository = Internal.Repository
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local function factionForPlayer(player, ownershipContext)
    local key
    local ok
    local reason
    if type(ownershipContext) == "table" then
        key = ownershipContext.playerKey or ownershipContext.entityKey
        if not key and ownershipContext.unavailable == true then
            return nil, ownershipContext.reason
        end
    end
    if key and PNC.Factions
        and type(PNC.Factions.GetFactionForPlayerKey) == "function"
    then
        return PNC.Factions.GetFactionForPlayerKey(tostring(key))
    end
    if PNC.PlayerCharacters
        and type(PNC.PlayerCharacters.GetEntityKey) == "function"
        and PNC.Factions
        and type(PNC.Factions.GetFactionForPlayerKey) == "function"
    then
        ok, key, reason = pcall(
            PNC.PlayerCharacters.GetEntityKey,
            player,
            { callback = "colony_storage_snapshot" }
        )
        if not ok then return nil, "identity_resolution_failed" end
        if not key then return nil, reason or "player_identity_unavailable" end
        return PNC.Factions.GetFactionForPlayerKey(tostring(key))
    end
    if PNC.Factions and type(PNC.Factions.GetPlayerFaction) == "function" then
        return PNC.Factions.GetPlayerFaction(player)
    end
    return nil, "faction_lookup_unavailable"
end

local function activeColony(factionID)
    if not PNC.Communities or not PNC.Communities.GetForFaction then
        return nil
    end
    for _, community in ipairs(PNC.Communities.GetForFaction(factionID) or {}) do
        if community.status == "active" then return community end
    end
    return nil
end

function Service.ResolveForPlayer(player, requestedStorageID,
    ownershipContext)
    local faction, reason = factionForPlayer(player, ownershipContext)
    reason = reason or "unaffiliated"
    if not faction then return nil, reason end
    local storage
    local colony = activeColony(faction.id)
    if requestedStorageID and tostring(requestedStorageID) ~= "" then
        storage = Repository.Get(tostring(requestedStorageID))
        reason = storage and nil or "storage_not_found"
    else
        storage, reason = Repository.GetPrimary(
            faction.id, colony and colony.id or nil)
    end
    if not storage then return nil, reason end
    if storage.ownerFactionId ~= faction.id then
        return nil, "storage_not_owned"
    end
    return storage, nil, faction, colony
end

function Service.BuildPlayerAccess(player, storage)
    local base = storage and storage.settlementId and PNC.BaseService
        and PNC.BaseService.GetForColony(storage.settlementId) or nil
    local stockpile = base and PNC.FacilityValidationService
        and PNC.FacilityValidationService.GetStockpile
        and PNC.FacilityValidationService.GetStockpile(base, true) or nil
    local hasStockpile = stockpile ~= nil
    local zone = base and Zones.get(base.baseZoneId) or nil
    local x = player and player.getX and tonumber(player:getX()) or nil
    local y = player and player.getY and tonumber(player:getY()) or nil
    local insideBase = x ~= nil and y ~= nil and zone and zone.geometry
        and GridRegion.containsXY(zone.geometry, math.floor(x), math.floor(y))
        or false
    return {
        baseId = base and base.id or nil,
        hasStockpile = hasStockpile,
        insideBase = insideBase == true,
        writable = hasStockpile and insideBase == true,
        reason = not hasStockpile and "stockpile_required"
            or not insideBase and "outside_base" or "writable",
    }
end

function Service.RequirePlayerAccess(player, storage)
    local access = Service.BuildPlayerAccess(player, storage)
    return access.writable == true, access.reason, access
end

return Service
