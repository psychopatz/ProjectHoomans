if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Lifecycle = PNC.PlayerCharacterLifecycle
local H = Lifecycle.Internal

function Lifecycle.OnCreatePlayer(first, second)
    local player = H.CallbackPlayer(first, second)
    if player and H.Service() then
        return H.EnsureIdentityAndProfile(
            player, "OnCreatePlayer", H.WorldAgeHours())
    end
    return nil, "player_unavailable"
end

function Lifecycle.OnPlayerDeath(first, second)
    local player = H.CallbackPlayer(first, second)
    if player and H.Service() then
        local at = H.WorldAgeHours()
        local entityKey = H.Service().GetEntityKey
            and H.Service().GetEntityKey(player, {
                callback = "OnPlayerDeath",
                worldAgeHours = at,
            }) or nil
        local faction = PNC.Factions
            and PNC.Factions.GetPlayerDiplomacyFaction
            and PNC.Factions.GetPlayerDiplomacyFaction(player) or nil
        local changed, reason = H.Service().MarkDead(
            player, at, "OnPlayerDeath")
        if entityKey and PNC.Factions
            and PNC.Factions.HandlePlayerCharacterDeath
        then
            PNC.Factions.HandlePlayerCharacterDeath(entityKey, at)
        end
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordCallback({
                operation = "player_death",
                worldAgeHours = at,
                actorKey = entityKey,
                sourceFactionID = faction and faction.id or nil,
                result = changed and "accepted" or "rejected",
                reason = reason,
            })
        end
        if faction and PNC.FactionBehavior
            and PNC.FactionBehavior.ReconcileFaction
        then
            PNC.FactionBehavior.ReconcileFaction(
                faction.id, "player_character_died")
        end
        return changed, reason
    end
    return false, "player_unavailable"
end

return Lifecycle
