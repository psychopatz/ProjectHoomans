local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

local function finalizeRehydrationMisses(now)
    local reg = Internal.registry and Internal.registry() or nil
    if not reg or not reg.ForEach then return 0 end
    local missed = 0
    reg.ForEach(function(record)
        if record and record.alive ~= false
            and record.runtime
            and record.runtime.startupRehydrateExpected == true
            and record.presenceState ~= Const.PRESENCE_LIVE
        then
            record.runtime.startupRehydrateExpected = nil
            record.runtime.startupRehydrateMissed = true
            record.runtime.lifecycle = record.runtime.lifecycle or {}
            record.runtime.lifecycle.lastReason = "startup_rehydrate_missed"
            record.runtime.lifecycle.lastTransitionAt = now
            missed = missed + 1
        end
    end)
    if missed > 0 and Core.LogInfo then
        Core.LogInfo("PNC startup rehydration fallback count="
            .. tostring(missed))
    end
    return missed
end

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
    state.lastBatch = nil
    state.settleUntil = 0
    state.nextMaterializeAt = 0
    state.nextReconcileAt = state.startedAt
    return state
end

function Lifecycle.RunStartupBodyCleanupNow(now, source, forceReset)
    local state = Lifecycle.BeginStartupBodyCleanup(now, forceReset == true)
    local passCount = (tonumber(Const.BODY_SHELL_STARTUP_PASSES) or 3) + 2
    local i
    -- Seed persisted husk proofs before the first body snapshot. The server
    -- lifecycle and the single-player OnGameStart path both enter here; doing
    -- it at this shared boundary prevents startup cleanup from classifying a
    -- proven restored shell as an ordinary anonymous zombie.
    if Lifecycle.SeedHuskLedgerFromRecords then
        Lifecycle.SeedHuskLedgerFromRecords(now)
    end
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
        and (tonumber(stats.pendingRehydrate) or 0) <= 0
        and (tonumber(stats.unresolvedRehydrate) or 0) <= 0
    then
        finalizeRehydrationMisses(now)
        state.active = false
        state.complete = true
        state.completedAt = now
        state.settleUntil = now
            + (tonumber(Const.BODY_SHELL_STARTUP_SETTLE_MS) or 1500)
        state.nextMaterializeAt = state.settleUntil
        state.nextMaintenanceAt = now
            + (tonumber(Const.BODY_SHELL_MAINTENANCE_MS) or 1000)
        Core.LogInfo("PNC startup body cleanup complete passes="
            .. tostring(state.passes) .. " removed=" .. tostring(state.removed)
            .. " ambiguous=" .. tostring(stats.ambiguous or 0)
            .. " ordinaryUnknown=" .. tostring(stats.ordinaryUnknown or 0)
            .. " blockedRecords=" .. tostring(stats.blockedRecords or 0))
    end
    return stats
end

function Lifecycle.IsStartupBodyCleanupComplete()
    local state = Lifecycle.StartupCleanup
    local now = Core.Now()
    if state.complete ~= true then
        if state.begun == true
            and (tonumber(state.startedAt) or 0) > 0
            and now - (tonumber(state.startedAt) or now)
                >= (tonumber(Const.BODY_SHELL_STARTUP_MAX_WAIT_MS) or 10000)
        then
            -- Do not deadlock presence when the early sweep could not inspect
            -- the cell. Materialize still performs its per-record shell
            -- cleanup immediately before spawning, while the maintenance
            -- sweep continues after this bounded fail-open.
            state.active = false
            state.complete = true
            state.failedOpen = true
            state.completedAt = now
            state.settleUntil = now
            state.nextMaterializeAt = now
            state.nextMaintenanceAt = now
                + (tonumber(Const.BODY_SHELL_MAINTENANCE_MS) or 1000)
            finalizeRehydrationMisses(now)
            if Core.LogWarn then
                Core.LogWarn("PNC startup body cleanup fail-open"
                    .. " reason=deadline"
                    .. " passes=" .. tostring(state.passes)
                    .. " removed=" .. tostring(state.removed))
            end
            return true
        end
        return false
    end
    return now >= (tonumber(state.settleUntil) or 0)
end

function Lifecycle.OnEarlyZombieUpdate(zombie)
    Lifecycle.InterceptLoadedShell(zombie, "early_zombie_update")
end

function Lifecycle.OnStartupReconcileTick()
    local state = Lifecycle.StartupCleanup
    local now
    if not Core.IsAuthority()
        or not state
        or state.active ~= true
    then
        return
    end
    now = Core.Now()
    if now < (tonumber(state.nextReconcileAt) or 0) then
        return
    end
    state.nextReconcileAt = now
        + (tonumber(Const.BODY_SHELL_REHYDRATE_PUMP_MS) or 100)
    Lifecycle.PumpStartupBodyCleanup(now, false)
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
            -- Early callbacks may have seeded from a provisional registry.
            -- Rerun the bounded seed after the definitive ModData reload; the
            -- ledger deduplicates matching rows, so this is idempotent.
            Lifecycle.HuskLedgerSeeded = false
        end
        Lifecycle.RunStartupBodyCleanupNow(Core.Now(), "world_ready", true)
    end
end

if Events and Events.OnTick then
    if Events.OnTick.Remove then
        Events.OnTick.Remove(Lifecycle.OnStartupReconcileTick)
    end
    Events.OnTick.Add(Lifecycle.OnStartupReconcileTick)
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
