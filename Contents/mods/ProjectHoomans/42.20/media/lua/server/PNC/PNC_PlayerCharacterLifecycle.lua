-- Idempotent lifecycle adapters around the centralized identity service.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.PlayerCharacterLifecycle =
    PNC.PlayerCharacterLifecycle or {}

local Lifecycle = PNC.PlayerCharacterLifecycle
local Core = PNC.Core
local Constants = PNC.PlayerCharacterConstants

Lifecycle.LastPumpAt = Lifecycle.LastPumpAt

local function worldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function service()
    return PNC.PlayerCharacters
end

local function ensureIdentityAndProfile(player, callback, at)
    local identity = service()
    local uuid
    local reason
    if not identity then
        return nil, "service_unavailable"
    end
    local context
    context, reason = PNC.PlayerContext.Resolve(player, callback)
    uuid = context and context.characterUUID or nil
    if uuid and PNC.SocialProfiles
        and PNC.SocialProfiles.EnsurePlayerProfile
    then
        PNC.SocialProfiles.EnsurePlayerProfile(player, at)
    end
    if uuid and PNC.Factions
        and PNC.Factions.EnsurePlayerDiplomacyFaction
    then
        PNC.Factions.EnsurePlayerDiplomacyFaction(
            player,
            { worldAgeHours = at }
        )
    end
    if uuid and PNC.Factions
        and PNC.Factions.GetPlayerDiplomacyFaction
        and PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        local faction =
            PNC.Factions.GetPlayerDiplomacyFaction(player)
        if faction then
            PNC.FactionBehavior.ReconcileFaction(
                faction.id,
                "player_identity_bound"
            )
        end
    end
    return uuid, reason
end

local function callbackPlayer(first, second)
    if first and first.getModData then
        return first
    end
    if second and second.getModData then
        return second
    end
    if type(first) == "number" and getSpecificPlayer then
        return getSpecificPlayer(first)
    end
    return nil
end

function Lifecycle.OnCreatePlayer(first, second)
    local player = callbackPlayer(first, second)
    if player and service() then
        return ensureIdentityAndProfile(
            player,
            "OnCreatePlayer",
            worldAgeHours()
        )
    end
    return nil, "player_unavailable"
end

function Lifecycle.OnPlayerDeath(first, second)
    local player = callbackPlayer(first, second)
    if player and service() then
        local at = worldAgeHours()
        local entityKey = service().GetEntityKey
            and service().GetEntityKey(player, {
                callback = "OnPlayerDeath",
                worldAgeHours = at,
            }) or nil
        local faction = PNC.Factions
            and PNC.Factions.GetPlayerDiplomacyFaction
            and PNC.Factions.GetPlayerDiplomacyFaction(player)
            or nil
        local changed, reason = service().MarkDead(
            player,
            at,
            "OnPlayerDeath"
        )
        if entityKey and PNC.Factions
            and PNC.Factions.HandlePlayerCharacterDeath
        then
            PNC.Factions.HandlePlayerCharacterDeath(
                entityKey,
                at
            )
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
                faction.id,
                "player_character_died"
            )
        end
        return changed, reason
    end
    return false, "player_unavailable"
end

function Lifecycle.Pump(now, force)
    local identity = service()
    local seen = {}
    local players = {}
    local index
    local staleCount
    local at
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if force ~= true
        and Lifecycle.LastPumpAt ~= nil
        and now - Lifecycle.LastPumpAt
            < Constants.LIFECYCLE_PUMP_MS
    then
        return 0, "not_due"
    end
    Lifecycle.LastPumpAt = now
    if not identity then
        return 0, "service_unavailable"
    end
    identity.EnsureLoaded()
    at = worldAgeHours()
    if Core and Core.ForEachPlayer then
        Core.ForEachPlayer(function(player)
            seen[player] = true
            players[#players + 1] = player
        end)
    end
    for stalePlayer, _ in pairs(
        identity.RuntimeByPlayer or {}
    ) do
        if not seen[stalePlayer] then
            local staleKey = identity.GetEntityKey
                and identity.GetEntityKey(stalePlayer, {
                    callback = "disconnect_sweep",
                    worldAgeHours = at,
                }) or nil
            if staleKey and PNC.FactionIncidentService
                and PNC.FactionIncidentService.CleanupEntity
            then
                PNC.FactionIncidentService.CleanupEntity(
                    staleKey, at, "player_disconnect"
                )
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
    -- Clear replaced/disconnected objects before validating current claims.
    -- This lets a newly loaded object rebind its survivor UUID instead of
    -- being mistaken for a simultaneous duplicate.
    staleCount = identity.SweepBindings(seen, at)
    for index = 1, #players do
        local player = players[index]
        if player.isDead and player:isDead() then
            identity.MarkDead(
                player,
                at,
                "authoritative_sweep"
            )
        else
            ensureIdentityAndProfile(
                player,
                "authoritative_sweep",
                at
            )
        end
    end
    if PNC.Factions
        and PNC.Factions.ReconcilePlayerMemberships
    then
        PNC.Factions.ReconcilePlayerMemberships(at)
    end
    return staleCount, "pumped"
end

function Lifecycle.OnServerStarted(now)
    local identity = service()
    if not identity then
        return false, "service_unavailable"
    end
    if not identity.Loaded then
        identity.Load()
    else
        identity.ResetRuntimeBindings("server_started")
    end
    if PNC.SocialProfiles
        and PNC.SocialProfiles.ResetRuntimePlayers
    then
        PNC.SocialProfiles.ResetRuntimePlayers()
    end
    Lifecycle.LastPumpAt = nil
    Lifecycle.Pump(now, true)
    return true
end

local function onInitGlobalModData()
    if service() then
        service().Load()
    end
end

local function onSave()
    if service() then
        service().Save()
    end
end

if Events and Events.OnInitGlobalModData
    and not Lifecycle.GlobalModDataHookRegistered
then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Lifecycle.GlobalModDataHookRegistered = true
end

if Events and Events.OnSave
    and not Lifecycle.SaveHookRegistered
then
    Events.OnSave.Add(onSave)
    Lifecycle.SaveHookRegistered = true
end

if Events and Events.OnCreatePlayer
    and not Lifecycle.CreatePlayerHookRegistered
then
    Events.OnCreatePlayer.Add(Lifecycle.OnCreatePlayer)
    Lifecycle.CreatePlayerHookRegistered = true
end

if Events and Events.OnPlayerDeath
    and not Lifecycle.PlayerDeathHookRegistered
then
    Events.OnPlayerDeath.Add(Lifecycle.OnPlayerDeath)
    Lifecycle.PlayerDeathHookRegistered = true
end

return Lifecycle
