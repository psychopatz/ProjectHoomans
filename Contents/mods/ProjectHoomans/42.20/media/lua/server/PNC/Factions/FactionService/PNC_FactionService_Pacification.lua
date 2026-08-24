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
function Factions.GetPlayerPacification(
    factionID,
    playerKey,
    worldAgeHours
)
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    if not EntityRef.IsPlayer(playerKey) then
        return nil, "invalid_player_key"
    end
    local entry = Types.NormalizePlayerPacification(
        faction.playerPacifications
            and faction.playerPacifications[playerKey],
        playerKey
    )
    if not entry then return nil, "not_pacified" end
    local at = Internal.finiteTimestamp(worldAgeHours, 0)
    if entry.untilWorldAgeHours <= at then
        return nil, "pacification_expired"
    end
    return Internal.copy(entry), "active"
end

function Factions.IsPacifiedForPlayer(
    factionID,
    playerKey,
    worldAgeHours
)
    local entry = Factions.GetPlayerPacification(
        factionID,
        playerKey,
        worldAgeHours
    )
    return entry ~= nil
end

function Factions.PacifyForPlayer(
    factionID,
    playerKey,
    options
)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    options = type(options) == "table" and options or {}
    local at = Internal.finiteTimestamp(options.worldAgeHours, 0)
    local durationHours = Internal.finiteTimestamp(
        options.durationHours,
        Constants.PLAYER_PACIFICATION_DEFAULT_HOURS
    )
    if durationHours <= 0 then
        return false, "invalid_duration"
    end
    local existing = faction.playerPacifications
        and faction.playerPacifications[playerKey] or nil
    local entry = Types.NormalizePlayerPacification({
        playerKey = playerKey,
        createdAt = at,
        untilWorldAgeHours = at + durationHours,
        reason = options.reason or "temporary_pacification",
        sourceNPCID = options.sourceNPCID,
        revision = math.max(
            0,
            math.floor(tonumber(
                existing and existing.revision
            ) or 0)
        ) + 1,
    }, playerKey)
    if not entry then
        return false, "invalid_pacification"
    end
    faction.playerPacifications =
        faction.playerPacifications or {}
    faction.playerPacifications[playerKey] = entry
    faction.playerPacifications =
        Types.NormalizePlayerPacifications(
            faction.playerPacifications
        )
    if not faction.playerPacifications[playerKey] then
        return false, "pacification_limit"
    end
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior
            .ReconcilePlayerPacification
    then
        PNC.FactionBehavior.ReconcilePlayerPacification(
            factionID,
            playerKey,
            "player_pacified"
        )
    end
    return true, "pacified", Internal.copy(entry)
end

function Factions.PacifyForRuntimePlayer(
    factionID,
    player,
    options
)
    local playerKey, reason = Internal.playerKeyFor(
        player,
        "pacify_for_player",
        true
    )
    if not playerKey then return false, reason end
    return Factions.PacifyForPlayer(
        factionID,
        playerKey,
        options
    )
end

function Factions.ClearPlayerPacification(
    factionID,
    playerKey
)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    if not faction.playerPacifications
        or not faction.playerPacifications[playerKey]
    then
        return false, "not_pacified"
    end
    faction.playerPacifications[playerKey] = nil
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "cleared"
end

function Factions.ClearRuntimePlayerPacification(
    factionID,
    player
)
    local playerKey, reason = Internal.playerKeyFor(
        player,
        "clear_player_pacification",
        true
    )
    if not playerKey then return false, reason end
    return Factions.ClearPlayerPacification(
        factionID,
        playerKey
    )
end

function Factions.PrunePlayerPacifications(worldAgeHours)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local at = Internal.finiteTimestamp(worldAgeHours, 0)
    local removed = 0
    for _, faction in pairs(Factions.Registry.byID or {}) do
        local changed = false
        for playerKey, raw in pairs(
            faction.playerPacifications or {}
        ) do
            local entry = Types.NormalizePlayerPacification(
                raw,
                playerKey
            )
            if not entry
                or entry.untilWorldAgeHours <= at
            then
                faction.playerPacifications[playerKey] = nil
                removed = removed + 1
                changed = true
            end
        end
        if changed then Internal.touchFaction(faction) end
    end
    if removed > 0 then Internal.touchRegistry() end
    return true, removed > 0 and "pruned" or "unchanged",
        removed
end

return Factions
