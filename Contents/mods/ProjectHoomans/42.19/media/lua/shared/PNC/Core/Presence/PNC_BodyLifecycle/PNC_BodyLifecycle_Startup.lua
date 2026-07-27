-- Persisted live-body shell cleanup and relog reconciliation.
--
-- IsoZombie bodies are engine-owned world objects and can be restored before
-- the PNC registry has rebuilt its runtime lease.  Treat those restored bodies
-- as disposable shells: remove them before materializing the record again.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

Lifecycle.StartupCleanup = Lifecycle.StartupCleanup or {
    begun = false,
    active = false,
    complete = true,
    passes = 0,
    quietPasses = 0,
    startedAt = 0,
    removed = 0,
}

local function listCount(list)
    return list and list.size and list:size() or 0
end

local function isNakedShell(zombie)
    local wornItems
    local itemVisuals
    if not zombie or (zombie.isDead and zombie:isDead()) then
        return false
    end
    wornItems = zombie.getWornItems and zombie:getWornItems() or nil
    itemVisuals = zombie.getItemVisuals and zombie:getItemVisuals() or nil
    return listCount(wornItems) <= 0 and listCount(itemVisuals) <= 0
end

local function getLiveShellIdentity(zombie)
    local modData
    local npcId
    local strong = false
    local weak = false
    if not zombie or (zombie.isDead and zombie:isDead()) then
        return nil, false, false
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        npcId = modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
        strong = modData.PNC_NPC == true
            or modData.PNC_PersistedShell == true
            or modData.PNC_BodyLease ~= nil
            or modData.PNC_TagVersion ~= nil
            or npcId ~= nil
        if tostring(modData.PNC_BodyKind or "live") == "corpse"
            or modData.PNC_DeathMarkerID ~= nil
        then
            return npcId, false, false
        end
    end
    if zombie.getVariableBoolean then
        strong = strong
            or zombie:getVariableBoolean("PNCActor") == true
            or zombie:getVariableBoolean("PNCLive") == true
    end
    if zombie.isUseless then
        weak = zombie:isUseless() == true
    end
    return npcId, strong, weak
end

local function getBodyInstanceID(zombie)
    local value = zombie and zombie.getPersistentOutfitID
        and zombie:getPersistentOutfitID() or nil
    if value == nil then
        return nil
    end
    return tostring(value)
end

local function isCanonicalBody(record, zombie)
    local reg = Internal.registry()
    local modData
    local lease
    if not record or not zombie then
        return false
    end
    if reg and reg.LiveByID and reg.LiveByID[tostring(record.id)] == zombie then
        return true
    end
    modData = zombie.getModData and zombie:getModData() or nil
    lease = record.runtime and record.runtime.bodyLease
    return record.presenceState == Const.PRESENCE_LIVE
        and lease ~= nil
        and modData
        and tostring(modData.PNC_BodyLease or "") == tostring(lease)
end

local function distanceSqToRecord(zombie, record)
    local dx
    local dy
    local dz
    if not zombie or not record or record.x == nil or record.y == nil then
        return nil
    end
    dz = (tonumber(zombie:getZ()) or 0) - (tonumber(record.z) or 0)
    if math.abs(dz) > 1 then
        return nil
    end
    dx = (tonumber(zombie:getX()) or 0) - (tonumber(record.x) or 0)
    dy = (tonumber(zombie:getY()) or 0) - (tonumber(record.y) or 0)
    return dx * dx + dy * dy
end

local function bodyHintMatches(record, zombie)
    local hint = record and record.runtime and record.runtime.startupBodyHint or nil
    local wanted = hint and hint.instanceID
    local dx
    local dy
    local dz
    if wanted == nil
        or tostring(wanted) ~= tostring(getBodyInstanceID(zombie) or "")
    then
        return false
    end
    -- Persistent outfit/body IDs are collision-prone engine hints, not actor
    -- identity. Accept one only when it is also close to the saved body/record
    -- position, as Dynamic Trading V2 does for startup recovery.
    dx = (tonumber(zombie:getX()) or 0)
        - (tonumber(hint.x) or tonumber(record.x) or 0)
    dy = (tonumber(zombie:getY()) or 0)
        - (tonumber(hint.y) or tonumber(record.y) or 0)
    dz = (tonumber(zombie:getZ()) or 0)
        - (tonumber(hint.z) or tonumber(record.z) or 0)
    return math.abs(dz) <= 1 and (dx * dx + dy * dy) <= (3.5 * 3.5)
end

local function resolveRecordForShell(reg, zombie, npcId, strongSignature, naked)
    local exact = npcId and reg.Get and reg.Get(npcId) or nil
    local best
    local bestScore
    if exact then
        return exact, "uuid"
    end
    if not reg.ForEach then
        return nil, nil
    end
    reg.ForEach(function(record)
        local distSq
        local radius
        local score
        if record and record.alive ~= false
            and record.presenceState ~= Const.PRESENCE_CORPSE
        then
            if bodyHintMatches(record, zombie) then
                score = 100000
            else
                distSq = distanceSqToRecord(zombie, record)
                radius = strongSignature and 3.5 or naked and 1.25 or 0
                if distSq and radius > 0 and distSq <= radius * radius then
                    -- Unmarked positional cleanup is only valid while the soul
                    -- is abstract. This avoids deleting an unrelated naked
                    -- zombie merely because it later walks beside a live NPC.
                    if strongSignature or record.presenceState ~= Const.PRESENCE_LIVE then
                        score = math.floor((radius * radius - distSq) * 100) + 1
                    end
                end
            end
            if score and (not bestScore or score > bestScore) then
                best = record
                bestScore = score
            end
        end
    end)
    return best, bodyHintMatches(best, zombie) and "body_hint"
        or strongSignature and "signature_position"
        or naked and "naked_position"
        or nil
end

local function notifyBodyRemoval(record, zombie, reason)
    local network = PNC.Network
    if network and network.BroadcastBodyRemoval then
        network.BroadcastBodyRemoval(
            record and record.id or nil,
            getBodyInstanceID(zombie),
            Internal.normalizeOnlineID(zombie),
            reason
        )
    end
end

local function removeShell(record, zombie, reason)
    local now = Core.Now()
    local id = record and record.id or nil
    local instanceID = getBodyInstanceID(zombie)
    local reg
    if PNC.LiveBodyControl and PNC.LiveBodyControl.ApplyHumanizedBodyFlags then
        -- Positional legacy shells may have lost every PNC marker, so the
        -- managed-only safety predicate cannot recognize them yet. Apply the
        -- harmless body flags directly before removal: no teeth, no target,
        -- useless, and no lunge are effective immediately.
        PNC.LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
        if PNC.LiveBodyControl.SuppressZombieSounds then
            PNC.LiveBodyControl.SuppressZombieSounds(zombie)
        end
    else
        Internal.clearBodyCombat(zombie)
    end
    notifyBodyRemoval(record, zombie, reason)
    Internal.removeZombie(zombie)
    if record then
        record.runtime = record.runtime or {}
        record.runtime.materializeRetryAt = now
            + (tonumber(Const.BODY_SHELL_RESPAWN_DELAY_MS) or 50)
        record.runtime.startupBodyHint = nil
        reg = Internal.registry()
        if reg and reg.LiveByID
            and reg.LiveByID[tostring(record.id)] == zombie
        then
            Internal.detachLiveBody(record, reason)
        end
        Internal.noteCleanup(record, "stale_cleaned", reason)
        Internal.mark(
            record,
            record.presenceState or Const.PRESENCE_ABSTRACT,
            "stale_cleaned",
            reason
        )
    end
    Core.LogWarn("PNC persisted_shell_repaired npc=" .. tostring(id or "orphan")
        .. " bodyInstanceID=" .. tostring(instanceID or "nil")
        .. " reason=" .. tostring(reason))
    return true
end

function Lifecycle.CleanupRecordShells(record, now)
    local cell
    local zombieList
    local candidates = {}
    local seen = {}
    local lifecycleCandidates
    local nearby
    local censusAll
    local removed = 0
    local i
    local zombie
    local npcId
    local strong
    local weak
    local naked
    local exactID
    local closeEnough
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not record or record.alive == false then
        return 0
    end
    if PNC.WorldCensus and PNC.WorldCensus.GetLifecycleCandidates then
        lifecycleCandidates = PNC.WorldCensus.GetLifecycleCandidates(
            now,
            false
        )
        for i = 1, #lifecycleCandidates do
            zombie = lifecycleCandidates[i]
            if zombie and not seen[zombie] then
                seen[zombie] = true
                candidates[#candidates + 1] = zombie
            end
        end
    end
    if PNC.SpatialIndex and PNC.SpatialIndex.QueryZombies then
        nearby = PNC.SpatialIndex.QueryZombies(
            record.x,
            record.y,
            3.5
        )
        for i = 1, #nearby do
            zombie = nearby[i]
            if zombie and not seen[zombie] then
                seen[zombie] = true
                candidates[#candidates + 1] = zombie
            end
        end
    end
    if PNC.WorldCensus and PNC.WorldCensus.GetAll
        and (not PNC.SpatialIndex
            or tonumber(PNC.SpatialIndex.LastRebuildAt) == nil)
    then
        censusAll = PNC.WorldCensus.GetAll(now, false)
        for i = 1, #censusAll do
            zombie = censusAll[i]
            closeEnough = distanceSqToRecord(zombie, record)
            if zombie and not seen[zombie]
                and closeEnough ~= nil
                and closeEnough <= (3.5 * 3.5)
            then
                seen[zombie] = true
                candidates[#candidates + 1] = zombie
            end
        end
    end
    if #candidates <= 0
        and (not PNC.WorldCensus or not PNC.WorldCensus.GetLifecycleCandidates)
    then
        cell = getCell and getCell() or nil
        zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
        if zombieList then
            for i = 0, zombieList:size() - 1 do
                candidates[#candidates + 1] = zombieList:get(i)
            end
        end
    end
    for i = #candidates, 1, -1 do
        zombie = candidates[i]
        npcId, strong, weak = getLiveShellIdentity(zombie)
        naked = isNakedShell(zombie)
        exactID = npcId ~= nil and tostring(npcId) == tostring(record.id)
        closeEnough = distanceSqToRecord(zombie, record)
        closeEnough = closeEnough ~= nil and closeEnough <= (naked and 1.25 * 1.25 or 3.5 * 3.5)
        if not isCanonicalBody(record, zombie)
            and (
                exactID
                or bodyHintMatches(record, zombie)
                or (naked and closeEnough and npcId == nil)
            )
        then
            removeShell(
                record,
                zombie,
                exactID and "pre_materialize_uuid_shell"
                    or bodyHintMatches(record, zombie) and "pre_materialize_body_hint"
                    or "pre_materialize_naked_shell"
            )
            removed = removed + 1
        end
    end
    return removed
end

function Lifecycle.SweepPersistedLiveShells(now)
    local reg = Internal.registry()
    local cell
    local zombieList
    local stats = { available = false, scanned = 0, removed = 0, matched = 0 }
    local i
    local zombie
    local npcId
    local strong
    local weak
    local naked
    local record
    local matchReason
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not reg or not reg.EnsureLoaded then
        return stats
    end
    reg.EnsureLoaded()
    cell = getCell and getCell() or nil
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then
        return stats
    end
    stats.available = true
    for i = zombieList:size() - 1, 0, -1 do
        zombie = zombieList:get(i)
        npcId, strong, weak = getLiveShellIdentity(zombie)
        naked = isNakedShell(zombie)
        -- Unmarked naked-zombie correlation is a startup-only sweep. Distant
        -- cells loaded later use the record-local materialization preflight,
        -- avoiding an O(naked zombies * NPC records) steady-state scan.
        if strong or (Lifecycle.StartupCleanup.active == true and naked) then
            stats.scanned = stats.scanned + 1
            record, matchReason = resolveRecordForShell(reg, zombie, npcId, strong, naked)
            if (record and not isCanonicalBody(record, zombie))
                or (strong and not record)
            then
                stats.matched = stats.matched + 1
                removeShell(
                    record,
                    zombie,
                    record and ("startup_" .. tostring(matchReason or "shell"))
                        or "startup_orphan_signature"
                )
                stats.removed = stats.removed + 1
            end
        end
    end
    return stats
end

function Lifecycle.InterceptLoadedShell(zombie, source)
    local reg = Internal.registry()
    local registryWasLoaded
    local npcId
    local strong
    local weak
    local naked
    local record
    local matchReason
    if not zombie or (zombie.isDead and zombie:isDead()) then
        return false
    end
    if not Core.IsAuthority() then
        if Core.IsManagedNPCBody and Core.IsManagedNPCBody(zombie)
            and PNC.LiveBodyControl
            and PNC.LiveBodyControl.EnforceManagedSafety
        then
            PNC.LiveBodyControl.EnforceManagedSafety(
                zombie,
                source or "early_client_shell"
            )
        end
        return false
    end
    if not reg or not reg.EnsureLoaded then
        return false
    end
    registryWasLoaded = reg.Loaded == true
    reg.EnsureLoaded()
    if not registryWasLoaded then
        Lifecycle.StartupCleanup.earlyRegistryLoad = true
    end
    if Lifecycle.StartupCleanup.begun ~= true then
        Lifecycle.BeginStartupBodyCleanup(Core.Now(), false)
    end
    npcId, strong, weak = getLiveShellIdentity(zombie)
    naked = isNakedShell(zombie)
    -- Marked PNC bodies remain cheap to recognize throughout play. Expensive
    -- positional correlation for unmarked naked shells is restricted to the
    -- startup gate; later streamed cells use CleanupRecordShells immediately
    -- before their record can materialize.
    if not strong
        and not (Lifecycle.StartupCleanup.active == true and naked)
    then
        return false
    end
    record, matchReason = resolveRecordForShell(reg, zombie, npcId, strong, naked)
    if record and not isCanonicalBody(record, zombie) then
        return removeShell(
            record,
            zombie,
            tostring(source or "early_shell") .. "_"
                .. tostring(matchReason or "matched")
        )
    end
    if strong and not record then
        return removeShell(
            nil,
            zombie,
            tostring(source or "early_shell") .. "_orphan_signature"
        )
    end
    return false
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
