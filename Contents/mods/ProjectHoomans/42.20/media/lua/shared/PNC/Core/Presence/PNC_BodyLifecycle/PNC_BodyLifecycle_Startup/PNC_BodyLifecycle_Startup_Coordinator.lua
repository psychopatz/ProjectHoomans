local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

function Lifecycle.BeginStartupBodyCleanup(now, forceReset)
    local state = Lifecycle.StartupCleanup
    if state.begun == true and forceReset ~= true then
        return state
    end
    state.begun = true
    state.active = true
    state.complete = false
    state.passes = 0
    state.quietPasses = 0
    state.startedAt = tonumber(now) or Core.Now()
    state.removed = 0
    state.lastStats = nil
    return state
end

function Lifecycle.RunStartupBodyCleanupNow(now, source, forceReset)
    local state = Lifecycle.BeginStartupBodyCleanup(now, forceReset == true)
    local passCount = (tonumber(Const.BODY_SHELL_STARTUP_PASSES) or 3) + 2
    local i
    for i = 1, passCount do
        Lifecycle.PumpStartupBodyCleanup(now, true)
        if state.complete == true then
            break
        end
    end
    if state.complete == true and source and Core.LogDebug then
        Core.LogDebug("startup_body_cleanup source=" .. tostring(source)
            .. " passes=" .. tostring(state.passes)
            .. " removed=" .. tostring(state.removed))
    end
    return state
end

function Lifecycle.PumpStartupBodyCleanup(now, force)
    local state = Lifecycle.StartupCleanup
    local stats
    now = tonumber(now) or Core.Now()
    if not state.active then
        if not force and now < (tonumber(state.nextMaintenanceAt) or 0) then
            return state.lastStats
        end
        state.nextMaintenanceAt = now
            + (tonumber(Const.BODY_SHELL_MAINTENANCE_MS) or 1000)
        return Lifecycle.SweepPersistedLiveShells(now)
    end
    stats = Lifecycle.SweepPersistedLiveShells(now)
    state.lastStats = stats
    if stats.available ~= true then
        return stats
    end
    state.passes = (tonumber(state.passes) or 0) + 1
    state.removed = (tonumber(state.removed) or 0) + (tonumber(stats.removed) or 0)
    if (tonumber(stats.removed) or 0) <= 0 then
        state.quietPasses = (tonumber(state.quietPasses) or 0) + 1
    else
        state.quietPasses = 0
    end
    if state.passes >= (tonumber(Const.BODY_SHELL_STARTUP_PASSES) or 3)
        and state.quietPasses >= 2
    then
        state.active = false
        state.complete = true
        state.completedAt = now
        state.nextMaintenanceAt = now
            + (tonumber(Const.BODY_SHELL_MAINTENANCE_MS) or 1000)
        Core.LogInfo("PNC startup body cleanup complete passes="
            .. tostring(state.passes) .. " removed=" .. tostring(state.removed))
    end
    return stats
end

function Lifecycle.IsStartupBodyCleanupComplete()
    return Lifecycle.StartupCleanup.complete ~= false
end

function Lifecycle.OnEarlyZombieUpdate(zombie)
    Lifecycle.InterceptLoadedShell(zombie, "early_zombie_update")
end

function Lifecycle.OnEarlyLivingCharacter(character)
    if instanceof and instanceof(character, "IsoZombie") then
        Lifecycle.InterceptLoadedShell(character, "early_character_create")
    end
end

function Lifecycle.OnEarlyWorldReady()
    local reg
    if Core.IsAuthority() then
        reg = Internal.registry()
        -- OnCreateLivingCharacter can expose a husk while the world is still
        -- streaming. Refresh once at the definitive world-ready event if that
        -- early lane had to bootstrap the registry before all ModData was
        -- guaranteed to be available.
        if Lifecycle.StartupCleanup.earlyRegistryLoad == true
            and reg and reg.Load
        then
            reg.Load()
            Lifecycle.StartupCleanup.earlyRegistryLoad = false
        end
        Lifecycle.RunStartupBodyCleanupNow(Core.Now(), "world_ready", true)
    end
end

if Events and Events.OnZombieUpdate then
    if Events.OnZombieUpdate.Remove then
        Events.OnZombieUpdate.Remove(Lifecycle.OnEarlyZombieUpdate)
    end
    Events.OnZombieUpdate.Add(Lifecycle.OnEarlyZombieUpdate)
end

if Events and Events.OnCreateLivingCharacter then
    if Events.OnCreateLivingCharacter.Remove then
        Events.OnCreateLivingCharacter.Remove(Lifecycle.OnEarlyLivingCharacter)
    end
    Events.OnCreateLivingCharacter.Add(Lifecycle.OnEarlyLivingCharacter)
end

if Events and Events.OnGameStart then
    if Events.OnGameStart.Remove then
        Events.OnGameStart.Remove(Lifecycle.OnEarlyWorldReady)
    end
    Events.OnGameStart.Add(Lifecycle.OnEarlyWorldReady)
end
