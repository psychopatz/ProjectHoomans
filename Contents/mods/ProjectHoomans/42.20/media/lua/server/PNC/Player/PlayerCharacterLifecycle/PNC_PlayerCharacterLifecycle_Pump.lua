if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Lifecycle = PNC.PlayerCharacterLifecycle
local H = Lifecycle.Internal
local Core = PNC.Core
local Constants = PNC.PlayerCharacterConstants

function Lifecycle.IsDue(now, force)
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    return force == true or Lifecycle.LastPumpAt == nil
        or now - Lifecycle.LastPumpAt >= Constants.LIFECYCLE_PUMP_MS
end

function Lifecycle.Pump(now, force)
    local identity = H.Service()
    local seen = {}
    local players = {}
    local index
    local staleCount
    local at
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if not Lifecycle.IsDue(now, force) then return 0, "not_due" end
    Lifecycle.LastPumpAt = now
    if not identity then return 0, "service_unavailable" end
    identity.EnsureLoaded()
    at = H.WorldAgeHours()
    if Core and Core.ForEachPlayer then
        Core.ForEachPlayer(function(player)
            seen[player] = true
            players[#players + 1] = player
        end)
    end
    for stalePlayer, _ in pairs(identity.RuntimeByPlayer or {}) do
        if not seen[stalePlayer] then
            Lifecycle.ValidatedUUIDByPlayer[stalePlayer] = nil
            Lifecycle.LastValidationAtByPlayer[stalePlayer] = nil
            local staleKey = identity.GetEntityKey
                and identity.GetEntityKey(stalePlayer, {
                    callback = "disconnect_sweep",
                    worldAgeHours = at,
                }) or nil
            if staleKey and PNC.FactionIncidentService
                and PNC.FactionIncidentService.CleanupEntity
            then
                PNC.FactionIncidentService.CleanupEntity(
                    staleKey, at, "player_disconnect")
            end
            if PNC.FactionTelemetry then
                PNC.FactionTelemetry.RecordCallback({
                    operation = "player_disconnect_sweep",
                    worldAgeHours = at,
                    actorKey = staleKey,
                    result = staleKey and "resolved" or "rejected",
                    reason = staleKey and "stale_runtime_binding"
                        or "actor_identity_missing",
                })
            end
        end
    end
    staleCount = identity.SweepBindings(seen, at)
    for index = 1, #players do
        local player = players[index]
        if player.isDead and player:isDead() then
            Lifecycle.ValidatedUUIDByPlayer[player] = nil
            Lifecycle.LastValidationAtByPlayer[player] = nil
            identity.MarkDead(player, at, "authoritative_sweep")
        else
            local boundUUID = identity.RuntimeByPlayer
                and identity.RuntimeByPlayer[player] or nil
            local validatedUUID = Lifecycle.ValidatedUUIDByPlayer[player]
            local lastValidatedAt = tonumber(
                Lifecycle.LastValidationAtByPlayer[player]) or 0
            local refreshMs = math.max(
                tonumber(Constants.LIFECYCLE_PUMP_MS) or 1000,
                tonumber(Constants.LIFECYCLE_VALIDATION_REFRESH_MS) or 30000)
            if not boundUUID or validatedUUID ~= boundUUID
                or now - lastValidatedAt >= refreshMs
            then
                local ensuredUUID = H.EnsureIdentityAndProfile(
                    player, "authoritative_sweep", at)
                if ensuredUUID then
                    Lifecycle.ValidatedUUIDByPlayer[player] = ensuredUUID
                    Lifecycle.LastValidationAtByPlayer[player] = now
                end
            end
        end
    end
    if PNC.Factions and PNC.Factions.ReconcilePlayerMemberships then
        PNC.Factions.ReconcilePlayerMemberships(at)
    end
    return staleCount, "pumped"
end

return Lifecycle
