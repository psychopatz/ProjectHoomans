if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Internal.tracePlayerIdentity(
    callback,
    worldAgeHours,
    playerKey,
    resultReason
)
    if PNC.FactionTelemetry
        and PNC.FactionTelemetry.RecordAttribution
    then
        PNC.FactionTelemetry.RecordAttribution({
            operation = callback or "player_identity_resolution",
            worldAgeHours = worldAgeHours,
            actorKey = playerKey,
            result = playerKey and "resolved" or "rejected",
            reason = resultReason or (
                playerKey and "resolved"
                    or "actor_identity_missing"
            ),
        })
    end
end

function Internal.playerKeyFor(player, callback, ensure)
    if not player or not PNC.PlayerCharacters then
        Internal.tracePlayerIdentity(
            callback, 0, nil, "actor_identity_missing"
        )
        return nil, "player_identity_unavailable"
    end
    if ensure ~= true then
        local context = PNC.PlayerContext and PNC.PlayerContext.Peek
            and PNC.PlayerContext.Peek(player) or nil
        local uuid = context and context.characterUUID
            or PNC.PlayerCharacters.GetCharacterUUID
                and PNC.PlayerCharacters.GetCharacterUUID(player) or nil
        local record = uuid and PNC.PlayerCharacters.Registry
            and PNC.PlayerCharacters.Registry.byUUID
            and PNC.PlayerCharacters.Registry.byUUID[uuid] or nil
        local key = context and context.entityKey
            or record and EntityRef.ForPlayerIdentity(
                record.accountKey or record.accountIdentity, uuid
            ) or nil
        local reason = key and "resolved"
            or uuid and "invalid_character_uuid"
            or "actor_identity_missing"
        Internal.tracePlayerIdentity(callback, 0, key, reason)
        return key, key and "resolved"
            or "player_identity_unavailable"
    end
    if not PNC.PlayerCharacters.GetEntityKey then
        return nil, "player_identity_unavailable"
    end
    local at = getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
        and getGameTime():getWorldAgeHours() or 0
    local key
    local reason
    key, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = callback or "faction",
        worldAgeHours = Internal.finiteTimestamp(at, 0),
    })
    Internal.tracePlayerIdentity(callback, at, key, reason)
    return key, reason
end

function Factions.GetFactionForPlayerKey(playerKey)
    Factions.EnsureLoaded()
    if not EntityRef.IsPlayer(playerKey) then
        return nil, "invalid_player_key"
    end
    local factionID = Factions.Registry.byPlayerKey[playerKey]
    if not factionID then return nil, "unaffiliated" end
    local faction = Internal.registryRecord(factionID)
    if Internal.isProvisionalFaction(faction) then
        return nil, "provisional_only"
    end
    return faction and Internal.copy(faction) or nil,
        faction and nil or "faction_not_found"
end

function Factions.GetDiplomacyFactionForPlayerKey(playerKey)
    Factions.EnsureLoaded()
    if not EntityRef.IsPlayer(playerKey) then
        return nil, "invalid_player_key"
    end
    local factionID = Factions.Registry.byPlayerKey[playerKey]
    if not factionID then return nil, "unaffiliated" end
    return Factions.Get(factionID)
end

function Factions.GetPlayerFaction(player)
    local playerKey, reason = Internal.playerKeyFor(
        player,
        "get_player_faction",
        false
    )
    if not playerKey then return nil, reason end
    return Factions.GetFactionForPlayerKey(playerKey)
end

function Factions.GetPlayerDiplomacyFaction(player)
    local playerKey, reason = Internal.playerKeyFor(
        player,
        "get_player_diplomacy_faction",
        false
    )
    if not playerKey then return nil, reason end
    return Factions.GetDiplomacyFactionForPlayerKey(playerKey)
end

function Factions.IsProvisionalPlayerFaction(factionOrID)
    local faction = type(factionOrID) == "table"
        and factionOrID or Internal.registryRecord(factionOrID)
    return Internal.isProvisionalFaction(faction)
end

function Factions.IsTerritorialTollFaction(factionOrID)
    local faction = type(factionOrID) == "table"
        and factionOrID or Internal.registryRecord(factionOrID)
    return type(faction) == "table"
        and faction.archetypeID == "looter"
        and type(faction.tags) == "table"
        and faction.tags.territorialToll == true
end

function Factions.MarkTerritorialTollFaction(factionID, reason)
    local faction
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.archetypeID ~= "looter" then
        return false, "not_looter_faction"
    end
    if Factions.IsTerritorialTollFaction(faction) then
        return true, "unchanged", Internal.copy(faction)
    end
    faction.tags = faction.tags or {}
    faction.tags.settlementType = "looter_toll"
    faction.tags.territorialToll = true
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(reason or "territorial_toll_enabled")
        )
    end
    return true, "territorial_toll_enabled", Internal.copy(faction)
end

function Factions.ReconcileTerritorialLooterFactions()
    if not Internal.authority() then return 0, "not_authority" end
    Factions.EnsureLoaded()
    if not PNC.Communities
        or not PNC.Communities.GetForFaction
    then
        return 0, "communities_unavailable"
    end
    local candidates = {}
    for factionID, faction in pairs(
        Factions.Registry.byID or {}
    ) do
        if faction.status == "active"
            and faction.archetypeID == "looter"
            and not Factions.IsTerritorialTollFaction(faction)
        then
            for _, community in ipairs(
                PNC.Communities.GetForFaction(factionID)
                    or {}
            ) do
                if community.status == "active"
                    and community.mode == "settled"
                then
                    candidates[#candidates + 1] = factionID
                    break
                end
            end
        end
    end
    table.sort(candidates)
    for _, factionID in ipairs(candidates) do
        Factions.MarkTerritorialTollFaction(
            factionID,
            "existing_looter_settlement_reconciled"
        )
    end
    return #candidates,
        #candidates > 0 and "reconciled" or "unchanged"
end

return Factions
