--[[
    Husk reaper.

    The population manager hands a virtualized shell back as a real IsoZombie
    through VirtualZombieManager.createRealZombieAlways, which fires the
    "OnZombieCreate" Lua event before the body reaches the zombie list. The
    record it came from is consumed by that hand-off, so removing the body here
    deletes the husk permanently.

    This module therefore:
      1. matches every freshly created unmarked body against the husk ledger,
      2. defers the removal to the next pump (the body is not fully registered
         while the create event is still inside the spawn call),
      3. revalidates identity, position and outfit before touching it, and
      4. falls back to a bounded sweep of the loaded census for husks whose
         create event was missed (for example bodies restored by a save load
         before the handler was registered).

    Nothing here can ever remove a body that has PNC ModData or that lacks a
    ledger entry.
]]

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

Lifecycle.HuskReaper = Lifecycle.HuskReaper or {
    pending = {},
    reaped = 0,
    dropped = 0,
    failed = 0,
    abandoned = 0,
    orphanReaps = 0,
    loggedActive = false,
    lastPumpAt = 0,
    lastSweepAt = 0,
}

local function noteIncrement(name)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and diagnostics.Increment then
        pcall(diagnostics.Increment, name)
    end
end

local function noteGauge(name, value)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and diagnostics.SetGauge then
        pcall(diagnostics.SetGauge, name, value)
    end
end

local function isAuthority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

--[[
    Husks in a world that cannot spawn vanilla zombies are simply orphans.

    The predicate lives on the ledger so the reclaim and the debug census agree.
    It needs no recorded loss, no position match and no persistent outfit id,
    which is what makes it work for shells the engine handed back anonymously.
]]
local function matchesOrphanedShell(zombie)
    return Lifecycle.IsOrphanedShell
        and Lifecycle.IsOrphanedShell(zombie) == true
end

local function logPumpActive()
    local reaper = Lifecycle.HuskReaper
    if reaper.loggedActive == true then
        return
    end
    reaper.loggedActive = true
    if Core and Core.LogInfo then
        pcall(Core.LogInfo, "PNC husk reaper pump active ledgerEntries="
            .. tostring(Lifecycle.HuskLedgerCount
                and Lifecycle.HuskLedgerCount() or 0)
            .. " orphansEnabled=" .. tostring(
                Lifecycle.AreZombieSpawnsDisabled
                    and Lifecycle.AreZombieSpawnsDisabled() or false))
    end
end

local function zombieModData(zombie)
    if not zombie or not zombie.getModData then
        return nil
    end
    local ok, modData = pcall(zombie.getModData, zombie)
    if ok then
        return modData
    end
    return nil
end

-- Any PNC marker means the body is ours or a restored shell. Those are owned by
-- the registry/audit lanes and must never be reaped here.
local function isMarkedBody(zombie)
    local modData = zombieModData(zombie)
    if PNC.Core and PNC.Core.IsManagedNPCBody
        and PNC.Core.IsManagedNPCBody(zombie)
    then
        return true
    end
    if not modData then
        return false
    end
    return modData.PNC_UUID ~= nil
        or modData.PNC_NPC == true
        or modData.PNC_Owner ~= nil
        or modData.PNC_PersistedShell == true
        or modData.PNC_BodyLease ~= nil
        or modData.PNC_TagVersion ~= nil
        or modData.PNC_DeathMarkerID ~= nil
end

local function isDeadBody(zombie)
    if not zombie.isDead then
        return false
    end
    local ok, dead = pcall(zombie.isDead, zombie)
    return ok and dead == true
end

local function pendingContains(zombie)
    local pending = Lifecycle.HuskReaper.pending
    local i
    for i = 1, #pending do
        if pending[i].zombie == zombie then
            return true
        end
    end
    return false
end

local function logReap(entry, reason)
    local reaper = Lifecycle.HuskReaper
    local count = (tonumber(reaper.reaped) or 0) + 1
    reaper.reaped = count
    Lifecycle.HuskLedger.reaped = (tonumber(Lifecycle.HuskLedger.reaped) or 0) + 1
    noteIncrement("HuskReaper.Reaped")
    if not (Core and Core.LogInfo) then
        return
    end
    if count <= 5 or count % 20 == 0 then
        pcall(Core.LogInfo, "PNC husk reaped npc="
            .. tostring(entry and entry.npcId or "unknown")
            .. " count=" .. tostring(count)
            .. " pos=" .. tostring(entry and math.floor(entry.x) or "?")
            .. "," .. tostring(entry and math.floor(entry.y) or "?")
            .. "," .. tostring(entry and math.floor(entry.z) or "?")
            .. " reason=" .. tostring(reason or "husk_respawn"))
    end
end

--[[
    Queue a matched husk for removal on the next pump.

    The ledger entry is consumed immediately so the same loss can never be
    reaped twice; its data travels with the pending record for revalidation.
]]
local function queueHuskReap(zombie, entry, reason)
    local reaper = Lifecycle.HuskReaper
    local pending = reaper.pending
    if not zombie or pendingContains(zombie) then
        return false
    end
    if not entry and not matchesOrphanedShell(zombie) then
        return false
    end
    if #pending >= (tonumber(Const.HUSK_REAP_PENDING_MAX) or 32) then
        return false
    end
    if entry then
        Lifecycle.ConsumeHuskEntry(entry)
    else
        reaper.orphanReaps = (tonumber(reaper.orphanReaps) or 0) + 1
        noteIncrement("HuskReaper.OrphanQueued")
    end
    pending[#pending + 1] = {
        zombie = zombie,
        entry = entry,
        reason = reason or "husk_respawn",
        attempts = 0,
    }
    noteGauge("HuskReaper.Pending", #pending)
    return true
end

function Lifecycle.OnZombieCreate(zombie)
    local ledgerCount
    if Internal.SpawnInProgress == true then
        -- Our own body: it is about to be stamped with PNC identity.
        return
    end
    if not isAuthority() then
        return
    end
    if not zombie or isDeadBody(zombie) then
        return
    end
    if isMarkedBody(zombie) then
        return
    end
    ledgerCount = Lifecycle.HuskLedgerCount
        and Lifecycle.HuskLedgerCount() or 0
    if ledgerCount > 0 then
        local entry = Lifecycle.FindHuskEntry
            and Lifecycle.FindHuskEntry(zombie) or nil
        if entry then
            queueHuskReap(zombie, entry, "husk_respawn")
            return
        end
    end
    -- No recorded loss matched. In a world that cannot spawn vanilla zombies,
    -- an unmarked body wearing a learned shell outfit is still an orphaned
    -- shell, so reclaim it here instead of leaving it in the world. The gate is
    -- cached, so a normal-population world pays two table lookups per spawn.
    if Lifecycle.AreZombieSpawnsDisabled
        and Lifecycle.AreZombieSpawnsDisabled() == true
    then
        queueHuskReap(zombie, nil, "orphaned_shell")
    end
end

local function revalidatePending(record)
    local entry = record.entry
    if not record.zombie or isDeadBody(record.zombie) then
        return false, "body_gone"
    end
    if isMarkedBody(record.zombie) then
        return false, "body_marked"
    end
    if entry then
        if not Lifecycle.HuskLedgerMatchesEntry(record.zombie, entry) then
            return false, "identity_drifted"
        end
        return true
    end
    if not matchesOrphanedShell(record.zombie) then
        return false, "orphan_rule_drifted"
    end
    return true
end

local function removeHusk(record)
    local zombie = record.zombie
    if PNC.LiveBodyControl and PNC.LiveBodyControl.ApplyHumanizedBodyFlags then
        pcall(PNC.LiveBodyControl.ApplyHumanizedBodyFlags, zombie)
    end
    if PNC.LiveBodyControl and PNC.LiveBodyControl.SuppressZombieSounds then
        pcall(PNC.LiveBodyControl.SuppressZombieSounds, zombie)
    end
    local removed = Internal.removeZombie(zombie)
    if removed == true or Internal.isBodyDetached(zombie) then
        return true
    end
    return false
end

local function rearmsEntry(record)
    local entry = record.entry
    if not entry then
        -- Fingerprint matches have no ledger record to restore; a failed
        -- removal is simply retried by the next sweep.
        return
    end
    -- Removal did not take. Keep the loss so a later pump or the loaded sweep
    -- can retry instead of forgetting the husk exists.
    entry.attempts = math.max(0, math.floor(tonumber(entry.attempts) or 0)) + 1
    if entry.attempts > (tonumber(Const.HUSK_REAP_MAX_ATTEMPTS) or 4) then
        -- Stop retrying but keep the loss as a bounded record of an
        -- unreapable husk. It is skipped by matching and expires with the
        -- ledger ttl, so a refusal cannot loop forever.
        if entry.abandoned ~= true then
            entry.abandoned = true
            Lifecycle.HuskReaper.abandoned =
                (tonumber(Lifecycle.HuskReaper.abandoned) or 0) + 1
            noteIncrement("HuskReaper.Abandoned")
            if Core and Core.LogWarn then
                pcall(Core.LogWarn, "PNC husk reap abandoned npc="
                    .. tostring(entry.npcId or "unknown")
                    .. " attempts=" .. tostring(entry.attempts)
                    .. " pos=" .. tostring(math.floor(entry.x))
                    .. "," .. tostring(math.floor(entry.y))
                    .. "," .. tostring(math.floor(entry.z)))
            end
        end
        Lifecycle.HuskLedgerRearm(entry)
        return
    end
    Lifecycle.HuskLedgerRearm(entry)
end

local function processPending(now)
    local reaper = Lifecycle.HuskReaper
    local pending = reaper.pending
    local i = #pending
    local removed = 0
    while i >= 1 do
        local record = pending[i]
        local valid, invalidReason = revalidatePending(record)
        if not valid then
            table.remove(pending, i)
            reaper.dropped = (tonumber(reaper.dropped) or 0) + 1
            noteIncrement("HuskReaper.Dropped")
            if invalidReason ~= "body_gone" then
                -- The body changed owner or identity while queued; keep the
                -- loss so the husk can still be found later.
                rearmsEntry(record)
            end
        elseif removeHusk(record) then
            table.remove(pending, i)
            logReap(record.entry, record.reason)
            removed = removed + 1
        else
            table.remove(pending, i)
            reaper.failed = (tonumber(reaper.failed) or 0) + 1
            rearmsEntry(record)
            noteIncrement("HuskReaper.Retry")
        end
        i = i - 1
    end
    noteGauge("HuskReaper.Pending", #pending)
    return removed
end

local function sweepLoadedHusks(now)
    local census = PNC.WorldCensus
    local bodies
    local found = 0
    local i
    if not census or not census.GetAll then
        return 0
    end
    local ledgerCount = Lifecycle.HuskLedgerCount
        and Lifecycle.HuskLedgerCount() or 0
    local orphanRule = Lifecycle.AreZombieSpawnsDisabled
        and Lifecycle.AreZombieSpawnsDisabled() == true
    if ledgerCount <= 0 and not orphanRule then
        return 0
    end
    bodies = census.GetAll(now, false)
    if type(bodies) ~= "table" then
        return 0
    end
    for i = 1, #bodies do
        local zombie = bodies[i]
        if zombie and not isDeadBody(zombie)
            and not isMarkedBody(zombie)
            and not pendingContains(zombie)
        then
            local entry = ledgerCount > 0 and Lifecycle.FindHuskEntry
                and Lifecycle.FindHuskEntry(zombie) or nil
            if entry then
                if queueHuskReap(zombie, entry, "loaded_husk_sweep") then
                    found = found + 1
                end
            elseif orphanRule
                and queueHuskReap(zombie, nil, "orphaned_shell_sweep")
            then
                found = found + 1
            end
        end
    end
    if found > 0 then
        noteIncrement("HuskReaper.SweepFound")
    end
    return found
end

--[[
    Server pump. Expires ledger entries, then revalidates and removes queued
    husks, then (throttled) sweeps the loaded census for missed husks.
]]
function Lifecycle.PumpHuskReaper(now, force)
    local reaper = Lifecycle.HuskReaper
    local interval = tonumber(Const.HUSK_REAP_PUMP_INTERVAL_MS) or 250
    local sweepInterval = tonumber(Const.HUSK_REAP_SWEEP_INTERVAL_MS) or 1000
    local removed
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if force ~= true and now < ((tonumber(reaper.lastPumpAt) or 0) + interval) then
        return reaper.lastResult
    end
    reaper.lastPumpAt = now
    if Lifecycle.PumpHuskLedger then
        Lifecycle.PumpHuskLedger(now)
    end
    logPumpActive()
    if not isAuthority() then
        return reaper.lastResult
    end
    removed = processPending(now)
    if now >= ((tonumber(reaper.lastSweepAt) or 0) + sweepInterval) then
        reaper.lastSweepAt = now
        removed = removed + sweepLoadedHusks(now)
        if removed > 0 then
            removed = removed + processPending(now)
        end
    end
    reaper.lastResult = removed
    return removed
end

function Lifecycle.BuildHuskReaperDiagnostics()
    local reaper = Lifecycle.HuskReaper
    return {
        pending = #reaper.pending,
        reaped = tonumber(reaper.reaped) or 0,
        dropped = tonumber(reaper.dropped) or 0,
        failed = tonumber(reaper.failed) or 0,
        abandoned = tonumber(reaper.abandoned) or 0,
        orphanReaps = tonumber(reaper.orphanReaps) or 0,
        active = reaper.loggedActive == true,
    }
end

--[[
    Load marker.

    Written once at load so a log always shows whether the husk lane exists,
    even in a session where no husk is ever reclaimed. `pump` additionally
    proves the per-tick pump link when it runs (see logPumpActive).
]]
if Core and Core.LogInfo then
    pcall(Core.LogInfo, "PNC husk lifecycle loaded reaper="
        .. tostring(Lifecycle.PumpHuskReaper ~= nil)
        .. " ledger=" .. tostring(Lifecycle.FindHuskEntry ~= nil)
        .. " factory=" .. tostring(Lifecycle.SpawnLiveBody ~= nil))
end

if Events and Events.OnZombieCreate and Events.OnZombieCreate.Add then
    if Events.OnZombieCreate.Remove then
        pcall(Events.OnZombieCreate.Remove, Lifecycle.OnZombieCreate)
    end
    Events.OnZombieCreate.Add(Lifecycle.OnZombieCreate)
end
