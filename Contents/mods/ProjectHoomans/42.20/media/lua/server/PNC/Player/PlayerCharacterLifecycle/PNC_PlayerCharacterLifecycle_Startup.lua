if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Lifecycle = PNC.PlayerCharacterLifecycle
local H = Lifecycle.Internal

function Lifecycle.OnServerStarted(now)
    local identity = H.Service()
    if not identity then return false, "service_unavailable" end
    if not identity.Loaded then
        identity.Load()
    else
        identity.ResetRuntimeBindings("server_started")
    end
    if PNC.SocialProfiles and PNC.SocialProfiles.ResetRuntimePlayers then
        PNC.SocialProfiles.ResetRuntimePlayers()
    end
    Lifecycle.LastPumpAt = nil
    Lifecycle.ValidatedUUIDByPlayer = setmetatable({}, { __mode = "k" })
    Lifecycle.LastValidationAtByPlayer = setmetatable({}, { __mode = "k" })
    Lifecycle.Pump(now, true)
    return true
end

function H.OnInitGlobalModData()
    if H.Service() then H.Service().Load() end
end

if Events and Events.OnInitGlobalModData
    and not Lifecycle.GlobalModDataHookRegistered
then
    Events.OnInitGlobalModData.Add(H.OnInitGlobalModData)
    Lifecycle.GlobalModDataHookRegistered = true
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
