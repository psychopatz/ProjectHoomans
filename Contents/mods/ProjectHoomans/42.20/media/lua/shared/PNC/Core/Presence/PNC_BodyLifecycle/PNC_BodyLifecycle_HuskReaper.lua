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
    droppedReasons = {},
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
    The fallback predicate lives on the ledger so the reclaim and debug census
    agree. It is positive-only: a learned PNC carrier id is required. An
    unmarked body with no carrier or ledger identity remains ordinary/unknown
    and is never deleted by this lane.
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
            Lifecycle.ShellCarrierCount
                and Lifecycle.ShellCarrierCount() or 0))
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

local function isProtectedBody(zombie)
    local ownership
    local ok
    local value
    if not zombie then
        return false
    end
    if zombie.isReanimatedPlayer then
        ok, value = pcall(zombie.isReanimatedPlayer, zombie)
        if ok and value == true then
            return true
        end
    end
    ownership = PNC.Compatibility and PNC.Compatibility.ActorOwnership
    if ownership and ownership.IsForeignOwned then
        ok, value = pcall(ownership.IsForeignOwned, zombie)
        if ok and value == true then
            return true
        end
    end
    return false
end

-- Any PNC marker means the body is ours or a restored shell. Those are owned by
-- the registry/audit lanes and must never be reaped here.
local function isMarkedBody(zombie)
    if isProtectedBody(zombie) then
        return true
    end
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

local function bodyIdentity(zombie)
    local outfitID
    local populationID
    local onlineID
    local ok
    if not zombie then
        return {}
    end
    if zombie.getPersistentOutfitID then
        ok, outfitID = pcall(zombie.getPersistentOutfitID, zombie)
        if not ok then outfitID = nil end
    end
    if Lifecycle.GetBodyPopulationID then
        ok, populationID = pcall(Lifecycle.GetBodyPopulationID, zombie)
        if not ok then populationID = nil end
    end
    if Internal.normalizeOnlineID then
        ok, onlineID = pcall(Internal.normalizeOnlineID, zombie)
        if not ok then onlineID = nil end
    elseif zombie.getOnlineID then
        ok, onlineID = pcall(zombie.getOnlineID, zombie)
        if not ok then onlineID = nil end
    end
    return {
        outfitID = outfitID,
        populationID = populationID,
        onlineID = onlineID,
        x = zombie.getX and zombie:getX() or nil,
        y = zombie.getY and zombie:getY() or nil,
        z = zombie.getZ and zombie:getZ() or nil,
    }
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

local function findLoadedHuskForRecord(npcId, entries, now)
    local census = PNC.WorldCensus
    local bodies
    local entry
    local zombie
    local i
    local j
    if not census or not census.GetAll then
        return nil
    end
    bodies = census.GetAll(now or Core.Now(), false)
    if type(bodies) ~= "table" then
        return nil
    end
    for i = 1, #entries do
        entry = entries[i]
        if entry and tostring(entry.npcId or "") == tostring(npcId)
        then
            for j = 1, #bodies do
                zombie = bodies[j]
                if zombie and not isDeadBody(zombie)
                    and not isMarkedBody(zombie)
                    and Lifecycle.HuskLedgerMatchesEntry
                    and Lifecycle.HuskLedgerMatchesEntry(
                        zombie, entry, true
                    )
                then
                    return true
                end
            end
        end
    end
    return false
end

function Lifecycle.HasPendingHuskForRecord(npcId)
    local id = npcId ~= nil and tostring(npcId) or nil
    local ledger
    local hasLedgerEntry = false
    local hasBlockingLedgerEntry = false
    local loadedHusk
    local i
    local pending
    if not id then
        return false
    end
    if Lifecycle.HuskLedgerCount then
        Lifecycle.HuskLedgerCount()
    end
    ledger = Lifecycle.HuskLedger
    for i = 1, #(ledger and ledger.entries or {}) do
        if ledger.entries[i]
            and tostring(ledger.entries[i].npcId or "") == id
        then
            hasLedgerEntry = true
            if tostring(ledger.entries[i].reason or "") ~= "startup_seed"
            then
                hasBlockingLedgerEntry = true
            end
        end
    end
    pending = Lifecycle.HuskReaper.pending
    for i = 1, #pending do
        if pending[i].entry
            and tostring(pending[i].entry.npcId or "") == id
        then
            return true, "pending_reap"
        end
    end
    if not hasLedgerEntry then
        return false, "no_ledger_entry"
    end
    loadedHusk = findLoadedHuskForRecord(
        id,
        ledger.entries,
        Core and Core.Now and Core.Now() or 0
    )
    if loadedHusk == true then
        return true, "loaded_husk"
    end
    if loadedHusk == nil and hasBlockingLedgerEntry then
        -- Fail closed if the loaded-world census is unavailable. A persisted
        -- non-seed loss is not enough to block when the census is healthy, but
        -- spawning while the world cannot be inspected could duplicate a husk.
        return true, "census_unavailable"
    end
    -- The ledger row remains armed for a future population-manager respawn,
    -- but it does not prove that a husk is currently loaded. Allow the NPC to
    -- materialize now; OnZombieCreate will still reclaim a later match.
    return false, "ledger_only"
end

local function logReap(entry, reason, identity)
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
            .. " reason=" .. tostring(reason or "husk_respawn")
            .. " outfitID=" .. tostring(identity and identity.outfitID or "nil")
            .. " populationID=" .. tostring(
                identity and identity.populationID or "nil")
            .. " onlineID=" .. tostring(identity and identity.onlineID or "nil")
            .. " detached=true")
    end
end

--[[
    Queue a matched husk for removal on the next pump.

    The ledger entry remains armed until removal is verified. The engine can
    virtualize this body again before the next pump; consuming the row here
    would lose the NPC association and turn the next return into an unknown
    anonymous shell. pendingContains() prevents duplicate queueing while the
    body is pending.
]]
local function queueHuskReap(zombie, entry, reason)
    local reaper = Lifecycle.HuskReaper
    local pending = reaper.pending
    local identity
    if not zombie or pendingContains(zombie) then
        return false
    end
    if not entry and not matchesOrphanedShell(zombie) then
        return false
    end
    if #pending >= (tonumber(Const.HUSK_REAP_PENDING_MAX) or 32) then
        return false
    end
    -- Positive identity proof is already established here. Neutralize the
    -- body before it reaches the next NPC combat tick while removal waits for
    -- the safe post-create pump.
    if Lifecycle.ClearEngineInvulnerability then
        pcall(Lifecycle.ClearEngineInvulnerability, zombie)
    end
    if Internal.clearBodyCombat then
        pcall(Internal.clearBodyCombat, zombie)
    end
    if not entry then
        reaper.orphanReaps = (tonumber(reaper.orphanReaps) or 0) + 1
        noteIncrement("HuskReaper.OrphanQueued")
    end
    identity = bodyIdentity(zombie)
    if Core and Core.LogInfo then
        pcall(Core.LogInfo, "PNC husk identified npc="
            .. tostring(entry and entry.npcId or "unknown")
            .. " reason=" .. tostring(reason or "husk_respawn")
            .. " outfitID=" .. tostring(identity.outfitID or "nil")
            .. " populationID=" .. tostring(identity.populationID or "nil")
            .. " onlineID=" .. tostring(identity.onlineID or "nil")
            .. " pos=" .. tostring(identity.x or "nil") .. ","
            .. tostring(identity.y or "nil") .. ","
            .. tostring(identity.z or "nil"))
    end
    pending[#pending + 1] = {
        zombie = zombie,
        entry = entry,
        reason = reason or "husk_respawn",
        attempts = 0,
        identity = identity,
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
    -- A missed ledger callback can still be recovered by the positive carrier
    -- fingerprint. Do not use the current zombie-spawn setting as ownership
    -- evidence: ordinary zombies may be present in an existing save.
    if matchesOrphanedShell(zombie)
    then
        queueHuskReap(zombie, nil, "orphaned_shell")
    end
end

local function sameLedgerPosition(entry, zombie)
    local radius
    local dx
    local dy
    local dz
    if not entry or not zombie or not zombie.getX then
        return false
    end
    radius = tonumber(Const.HUSK_LEDGER_MATCH_RADIUS) or 2
    dz = (tonumber(zombie:getZ()) or 0) - (tonumber(entry.z) or 0)
    if math.abs(dz) > 1 then
        return false
    end
    dx = (tonumber(zombie:getX()) or 0) - (tonumber(entry.x) or 0)
    dy = (tonumber(zombie:getY()) or 0) - (tonumber(entry.y) or 0)
    return dx * dx + dy * dy <= radius * radius
end

local function matchesPendingStartupSeed(record)
    local entry = record and record.entry or nil
    local queuedIdentity = record and record.identity or nil
    local currentPopulationID
    local expectedPopulationID
    if not entry or tostring(entry.reason or "") ~= "startup_seed"
        or not queuedIdentity
    then
        return false
    end
    -- This fallback is only for the create-event proof that was accepted while
    -- PZ still returned outfit 0. It never turns a later anonymous zombie into
    -- a candidate merely because it occupies an NPC's saved position.
    if queuedIdentity.outfitID ~= nil
        and tonumber(queuedIdentity.outfitID) ~= 0
    then
        return false
    end
    expectedPopulationID = entry.populationId
    if expectedPopulationID ~= nil
        and tostring(expectedPopulationID) ~= ""
        and tostring(expectedPopulationID) ~= "0"
        and Lifecycle.GetBodyPopulationID
    then
        currentPopulationID = Lifecycle.GetBodyPopulationID(record.zombie)
        if currentPopulationID ~= nil
            and tostring(currentPopulationID) ~= tostring(expectedPopulationID)
        then
            return false
        end
    end
    return sameLedgerPosition(entry, record.zombie)
end

local function revalidatePending(record)
    local entry = record.entry
    if not record.zombie or isDeadBody(record.zombie) then
        return false, "body_gone"
    end
    -- removeZombie() deliberately returns true for an already-detached body
    -- so ordinary callers can treat idempotent cleanup as success. That is not
    -- success for a husk: a detached body may already have crossed back into
    -- the population manager, and consuming the ledger here would lose the
    -- only identity that can reclaim its next real-zombie incarnation.
    if Internal.isBodyDetached and Internal.isBodyDetached(record.zombie) then
        return false, "body_gone"
    end
    if isMarkedBody(record.zombie) then
        return false, "body_marked"
    end
    if entry then
        if not Lifecycle.HuskLedgerMatchesEntry(record.zombie, entry) then
            if not matchesPendingStartupSeed(record) then
                return false, "identity_drifted"
            end
            record.reason = tostring(record.reason or "husk_respawn")
                .. "_outfit_rewritten"
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
    record.identity = record.identity or bodyIdentity(zombie)
    if Lifecycle.ClearEngineInvulnerability then
        pcall(Lifecycle.ClearEngineInvulnerability, zombie)
    end
    if PNC.LiveBodyControl and PNC.LiveBodyControl.ApplyHumanizedBodyFlags then
        pcall(PNC.LiveBodyControl.ApplyHumanizedBodyFlags, zombie)
    end
    if PNC.LiveBodyControl and PNC.LiveBodyControl.SuppressZombieSounds then
        pcall(PNC.LiveBodyControl.SuppressZombieSounds, zombie)
    end
    local removed = Internal.removeZombie(zombie)
    local detached = removed == true or Internal.isBodyDetached(zombie)
    if Lifecycle.IdentityAudit and Lifecycle.IdentityAudit.RecordRemoval then
        Lifecycle.IdentityAudit.RecordRemoval(
            zombie,
            "husk_reaper_removal",
            record.entry and record.entry.npcId or nil,
            record.reason,
            detached
        )
    end
    return detached
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
            local dropKey = tostring(invalidReason or "unknown")
            reaper.droppedReasons[dropKey] =
                (tonumber(reaper.droppedReasons[dropKey]) or 0) + 1
            noteIncrement("HuskReaper.Dropped")
            -- The ledger row stays armed from queue time through every
            -- revalidation outcome. Rearm is retained for compatibility with
            -- older in-memory callers and persists attempt/abandon changes.
            rearmsEntry(record)
            if Core and Core.LogWarn and invalidReason ~= "body_gone" then
                pcall(Core.LogWarn, "PNC husk pending dropped npc="
                    .. tostring(record.entry and record.entry.npcId or "unknown")
                    .. " reason=" .. dropKey
                    .. " outfitID=" .. tostring(
                        record.identity and record.identity.outfitID or "nil")
                    .. " populationID=" .. tostring(
                        record.identity and record.identity.populationID or "nil"))
            end
        elseif removeHusk(record) then
            table.remove(pending, i)
            if record.entry then
                -- Only a verified detach may consume the historical identity.
                Lifecycle.ConsumeHuskEntry(record.entry)
            end
            logReap(record.entry, record.reason, record.identity)
            removed = removed + 1
        else
            table.remove(pending, i)
            reaper.failed = (tonumber(reaper.failed) or 0) + 1
            if Core and Core.LogWarn then
                pcall(Core.LogWarn, "PNC husk removal failed npc="
                    .. tostring(record.entry and record.entry.npcId or "unknown")
                    .. " reason=" .. tostring(record.reason or "unknown")
                    .. " attached=" .. tostring(
                        Internal.isBodyAttached(record.zombie)))
            end
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
    local carrierRule = Lifecycle.ShellCarrierCount
        and Lifecycle.ShellCarrierCount() > 0
    if ledgerCount <= 0 and not carrierRule then
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
            elseif matchesOrphanedShell(zombie)
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
        droppedReasons = reaper.droppedReasons,
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
