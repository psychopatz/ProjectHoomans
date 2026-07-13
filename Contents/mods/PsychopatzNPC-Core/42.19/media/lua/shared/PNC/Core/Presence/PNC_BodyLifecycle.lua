--[[
    PNC Body Lifecycle
    Owns engine-body leases, orphan removal, inert corpses, and lifecycle
    diagnostics. Canonical NPC records remain authoritative across reloads.
]]

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}

local Lifecycle = PNC.BodyLifecycle
local Core = PNC.Core
local Const = PNC.Const

Lifecycle.PendingCorpses = Lifecycle.PendingCorpses or {}
Lifecycle.NextAuditAt = Lifecycle.NextAuditAt or 0
Lifecycle.NextCorpseAuditAt = Lifecycle.NextCorpseAuditAt or 0
Lifecycle.CorpseAuditCursor = Lifecycle.CorpseAuditCursor or 1
Lifecycle.LastAudit = Lifecycle.LastAudit or {
    scanned = 0,
    removed = 0,
    rebound = 0,
    duplicates = 0,
    corpses = 0,
}

local function registry()
    return PNC.Registry
end

local function ensureRuntime(record)
    local now = Core.Now()
    record.runtime = record.runtime or {}
    record.runtime.lifecycle = record.runtime.lifecycle or {
        phase = record.presenceState or "unknown",
        bodyState = "missing",
        lastReason = "runtime_created",
        lastTransitionAt = now,
        lastAuditAt = 0,
        lastError = nil,
        corpseState = record.alive == false and "unresolved" or "none",
    }
    return record.runtime.lifecycle
end

local function mark(record, phase, bodyState, reason, errorText)
    local state
    if not record then
        return
    end
    state = ensureRuntime(record)
    if phase and state.phase ~= phase then
        state.lastTransitionAt = Core.Now()
    end
    state.phase = phase or state.phase
    state.bodyState = bodyState or state.bodyState
    state.lastReason = reason or state.lastReason
    state.lastError = errorText
end

local function noteCleanup(record, cleanupState, reason)
    local state
    if not record then
        return
    end
    state = ensureRuntime(record)
    state.lastCleanupState = cleanupState
    state.lastCleanupReason = reason
    state.lastCleanupAt = Core.Now()
end

local function worldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours and tonumber(gameTime:getWorldAgeHours()) or 0
end

local function normalizeOnlineID(zombie)
    local value = zombie and zombie.getOnlineID and tonumber(zombie:getOnlineID()) or nil
    return value and value >= 0 and value or nil
end

local function clearBodyCombat(zombie)
    if not zombie then
        return
    end
    if PNC.ZombieAggro and PNC.ZombieAggro.ClearForNPCBody then
        pcall(PNC.ZombieAggro.ClearForNPCBody, zombie)
    end
    if zombie.clearAggroList then
        pcall(zombie.clearAggroList, zombie)
    end
    if zombie.setTarget then
        pcall(zombie.setTarget, zombie, nil)
    end
    if zombie.setAttackedBy then
        pcall(zombie.setAttackedBy, zombie, nil)
    end
    if zombie.setUseless then
        pcall(zombie.setUseless, zombie, true)
    end
    if zombie.setRunning then
        pcall(zombie.setRunning, zombie, false)
    end
    if zombie.setReanimate then
        pcall(zombie.setReanimate, zombie, false)
    end
end

local function removeZombie(zombie)
    local ok
    local removed = false
    if not zombie then
        return false
    end
    clearBodyCombat(zombie)
    if VirtualZombieManager and VirtualZombieManager.instance
        and VirtualZombieManager.instance.removeZombieFromWorld
    then
        ok, removed = pcall(
            VirtualZombieManager.instance.removeZombieFromWorld,
            VirtualZombieManager.instance,
            zombie
        )
        removed = ok and removed == true
    end
    if not removed and zombie.removeFromWorld then
        pcall(zombie.removeFromWorld, zombie)
    end
    if not removed and zombie.removeFromSquare then
        pcall(zombie.removeFromSquare, zombie)
    end
    return true
end

local function removeCorpse(corpse)
    local square
    if not corpse then
        return false
    end
    square = corpse.getSquare and corpse:getSquare() or nil
    if square and square.transmitRemoveItemFromSquare then
        pcall(square.transmitRemoveItemFromSquare, square, corpse)
    end
    if corpse.removeFromWorld then
        pcall(corpse.removeFromWorld, corpse)
    end
    if corpse.removeFromSquare then
        pcall(corpse.removeFromSquare, corpse)
    end
    if corpse.setSquare then
        pcall(corpse.setSquare, corpse, nil)
    end
    return true
end

local function forEachCorpse(square, callback)
    local seen = {}
    local list
    local i
    local corpse
    if not square or type(callback) ~= "function" then
        return
    end
    list = square.getDeadBodys and square:getDeadBodys() or nil
    if list then
        for i = list:size() - 1, 0, -1 do
            corpse = list:get(i)
            if corpse and not seen[corpse] then
                seen[corpse] = true
                callback(corpse)
            end
        end
    end
    list = square.getStaticMovingObjects and square:getStaticMovingObjects() or nil
    if list then
        for i = list:size() - 1, 0, -1 do
            corpse = list:get(i)
            if corpse and not seen[corpse]
                and instanceof and instanceof(corpse, "IsoDeadBody")
            then
                seen[corpse] = true
                callback(corpse)
            end
        end
    end
end

local function makeCorpseInert(corpse)
    local reanimateAt = worldHour() + 100000000
    if not corpse then
        return
    end
    if corpse.setFakeDead then
        pcall(corpse.setFakeDead, corpse, false)
    end
    if corpse.setReanimateTime then
        pcall(corpse.setReanimateTime, corpse, reanimateAt)
    end
end

local function stampCorpse(record, corpse, token)
    local modData
    if not record or not corpse or not corpse.getModData then
        return false
    end
    token = tostring(token or Core.GenerateID("corpse"))
    modData = corpse:getModData()
    modData.PNC_NPC = true
    modData.PNC_UUID = tostring(record.id)
    modData.PNC_BodyKind = "corpse"
    modData.PNC_CorpseToken = token
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    makeCorpseInert(corpse)
    record.corpse = record.corpse or {}
    record.corpse.token = token
    record.corpse.x = corpse.getX and corpse:getX() or record.x
    record.corpse.y = corpse.getY and corpse:getY() or record.y
    record.corpse.z = corpse.getZ and corpse:getZ() or record.z
    record.corpse.createdWorldHour = tonumber(record.corpse.createdWorldHour) or worldHour()
    ensureRuntime(record).corpseState = "inert_loaded"
    return true
end

function Lifecycle.StampLiveBody(record, zombie)
    local modData
    if not record or not zombie or not zombie.getModData then
        return nil
    end
    record.runtime = record.runtime or {}
    if not record.runtime.bodyLease or tostring(record.runtime.bodyLease) == "" then
        record.runtime.bodyLease = Core.GenerateID("body")
    end
    modData = zombie:getModData()
    modData.PNC_NPC = true
    modData.PNC_UUID = tostring(record.id)
    modData.PNC_BodyKind = "live"
    modData.PNC_BodyLease = tostring(record.runtime.bodyLease)
    modData.PNC_CorpseToken = nil
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    mark(record, "live", "bound", "body_stamped")
    return record.runtime.bodyLease
end

function Lifecycle.RemoveLiveBody(record, zombie, reason)
    local reg = registry()
    if zombie then
        removeZombie(zombie)
    end
    if record then
        record.runtime = record.runtime or {}
        record.runtime.bodyLease = nil
        if reg and reg.LiveByID then
            reg.LiveByID[record.id] = nil
        end
        record.liveBodyInstanceID = nil
        record.liveBodyOnlineID = nil
        record.presenceRevision = (tonumber(record.presenceRevision) or 0) + 1
        if record.presenceState ~= Const.PRESENCE_CORPSE then
            record.presenceState = Const.PRESENCE_ABSTRACT
            mark(record, "abstract", "missing", reason or "body_removed")
        else
            mark(record, "corpse", "missing", reason or "source_body_removed")
        end
    end
    return true
end

local function scheduleCorpseFinalize(record, x, y, z, token, reason)
    Lifecycle.PendingCorpses[#Lifecycle.PendingCorpses + 1] = {
        npcId = tostring(record.id),
        x = math.floor(tonumber(x) or 0),
        y = math.floor(tonumber(y) or 0),
        z = math.floor(tonumber(z) or 0),
        token = token,
        reason = reason,
        attempts = 0,
    }
end

function Lifecycle.CreateInertCorpse(record, zombie, reason)
    local x
    local y
    local z
    local token
    local createdWorldHour
    local ok
    local corpse
    if not record or not zombie then
        return false, nil
    end
    x = zombie.getX and zombie:getX() or record.x
    y = zombie.getY and zombie:getY() or record.y
    z = zombie.getZ and zombie:getZ() or record.z
    token = record.corpse and record.corpse.token or Core.GenerateID("corpse")
    createdWorldHour = record.corpse and tonumber(record.corpse.createdWorldHour) or worldHour()
    record.x = x
    record.y = y
    record.z = z
    record.corpse = {
        token = token,
        x = x,
        y = y,
        z = z,
        createdWorldHour = createdWorldHour,
    }
    if zombie.setReanimate then
        pcall(zombie.setReanimate, zombie, false)
    end
    if zombie.setReanim then
        pcall(zombie.setReanim, zombie, false)
    end
    if IsoDeadBody and IsoDeadBody.new then
        ok, corpse = pcall(IsoDeadBody.new, zombie, false, true)
        if not ok or not corpse then
            ok, corpse = pcall(IsoDeadBody.new, zombie, false)
        end
    end
    if corpse then
        stampCorpse(record, corpse, token)
        if isServer and isServer() and corpse.transmitCompleteItemToClients then
            pcall(corpse.transmitCompleteItemToClients, corpse)
        end
    else
        if zombie.becomeCorpseSilently then
            pcall(zombie.becomeCorpseSilently, zombie)
        end
        scheduleCorpseFinalize(record, x, y, z, token, reason or "death")
        ensureRuntime(record).corpseState = "finalizing"
    end
    Lifecycle.RemoveLiveBody(record, zombie, reason or "death")
    record.presenceState = Const.PRESENCE_CORPSE
    mark(record, "corpse", "missing", reason or "death")
    if corpse then
        ensureRuntime(record).corpseState = "inert_loaded"
    end
    return corpse ~= nil, corpse
end

local function pumpPendingCorpses()
    local cell = getCell and getCell() or nil
    local i
    local pending
    local record
    local square
    local found
    if not cell then
        return
    end
    for i = #Lifecycle.PendingCorpses, 1, -1 do
        pending = Lifecycle.PendingCorpses[i]
        pending.attempts = (tonumber(pending.attempts) or 0) + 1
        record = registry() and registry().Get and registry().Get(pending.npcId) or nil
        square = cell:getGridSquare(pending.x, pending.y, pending.z)
        found = nil
        forEachCorpse(square, function(corpse)
            local modData = corpse.getModData and corpse:getModData() or nil
            if not found and (not modData or not modData.PNC_UUID or tostring(modData.PNC_UUID) == pending.npcId) then
                found = corpse
            end
        end)
        if found and record then
            stampCorpse(record, found, pending.token)
            table.remove(Lifecycle.PendingCorpses, i)
        elseif pending.attempts >= 8 then
            if record then
                ensureRuntime(record).corpseState = "missing"
                mark(record, "corpse", "missing", "corpse_finalize_timeout", "corpse_not_found")
            end
            table.remove(Lifecycle.PendingCorpses, i)
        end
    end
end

local function auditCorpseRecord(record)
    local cell = getCell and getCell() or nil
    local descriptor = record and record.corpse or nil
    local square
    local accepted
    local token
    local state
    if not cell or not record or record.alive ~= false then
        return
    end
    state = ensureRuntime(record)
    if not descriptor then
        state.corpseState = "missing"
        return
    end
    square = cell:getGridSquare(
        math.floor(tonumber(descriptor.x) or tonumber(record.x) or 0),
        math.floor(tonumber(descriptor.y) or tonumber(record.y) or 0),
        math.floor(tonumber(descriptor.z) or tonumber(record.z) or 0)
    )
    if not square then
        state.corpseState = "unloaded"
        return
    end
    token = descriptor.token and tostring(descriptor.token) or nil
    forEachCorpse(square, function(corpse)
        local modData = corpse.getModData and corpse:getModData() or nil
        local corpseId = modData and modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
        local corpseToken = modData and modData.PNC_CorpseToken and tostring(modData.PNC_CorpseToken) or nil
        if corpseId == tostring(record.id) then
            if not token then
                token = corpseToken or Core.GenerateID("corpse")
                descriptor.token = token
            end
            if corpseToken == token or corpseToken == nil then
                if not accepted then
                    accepted = corpse
                    stampCorpse(record, corpse, token)
                else
                    removeCorpse(corpse)
                end
            else
                removeCorpse(corpse)
            end
        end
    end)
    state.corpseState = accepted and "inert_loaded" or "missing"
end

local function auditCorpseBatch(reg)
    local dead = {}
    local batchSize = math.max(1, tonumber(Const.CORPSE_AUDIT_BATCH_SIZE) or 12)
    local startAt
    local count
    local i
    reg.ForEach(function(candidate)
        if candidate.alive == false then
            dead[#dead + 1] = candidate
        end
    end)
    if #dead <= 0 then
        Lifecycle.CorpseAuditCursor = 1
        return
    end
    table.sort(dead, function(a, b)
        return tostring(a.id or "") < tostring(b.id or "")
    end)
    startAt = math.max(1, math.min(#dead, tonumber(Lifecycle.CorpseAuditCursor) or 1))
    count = math.min(batchSize, #dead)
    for i = 0, count - 1 do
        auditCorpseRecord(dead[((startAt - 1 + i) % #dead) + 1])
    end
    Lifecycle.CorpseAuditCursor = ((startAt - 1 + count) % #dead) + 1
end

function Lifecycle.AuditLoadedBodies(now, force)
    local reg = registry()
    local cell
    local zombieList
    local accepted = {}
    local stats = { scanned = 0, removed = 0, rebound = 0, duplicates = 0, corpses = 0 }
    local i
    local zombie
    local modData
    local npcId
    local kind
    local lease
    local tagVersion
    local record
    local expected
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not reg or not reg.EnsureLoaded then
        return stats
    end
    if not force and now < (tonumber(Lifecycle.NextAuditAt) or 0) then
        pumpPendingCorpses()
        return Lifecycle.LastAudit
    end
    Lifecycle.NextAuditAt = now + (tonumber(Const.BODY_AUDIT_INTERVAL_MS) or 250)
    reg.EnsureLoaded()
    cell = getCell and getCell() or nil
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if zombieList then
        for i = zombieList:size() - 1, 0, -1 do
            zombie = zombieList:get(i)
            modData = zombie and zombie.getModData and zombie:getModData() or nil
            if modData and modData.PNC_NPC == true then
                stats.scanned = stats.scanned + 1
                npcId = modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
                kind = tostring(modData.PNC_BodyKind or "live")
                lease = modData.PNC_BodyLease and tostring(modData.PNC_BodyLease) or nil
                tagVersion = tonumber(modData.PNC_TagVersion)
                record = npcId and reg.Get(npcId) or nil
                if kind == "corpse" and record and record.alive == false then
                    stats.corpses = stats.corpses + 1
                    record.runtime = record.runtime or {}
                    record.runtime.corpseRecoveryAttempts = (tonumber(record.runtime.corpseRecoveryAttempts) or 0) + 1
                    if record.runtime.corpseRecoveryAttempts <= (tonumber(Const.CORPSE_REANIMATE_RETRY_MAX) or 3) then
                        Lifecycle.CreateInertCorpse(record, zombie, "corpse_reanimated")
                    else
                        removeZombie(zombie)
                        ensureRuntime(record).corpseState = "missing"
                        mark(record, "corpse", "stale_cleaned", "corpse_recovery_capped", "reanimation_retry_limit")
                    end
                elseif kind == "live"
                    and record
                    and record.alive ~= false
                    and record.presenceState == Const.PRESENCE_LIVE
                    and record.runtime
                    and record.runtime.bodyLease
                    and lease == tostring(record.runtime.bodyLease)
                    and tagVersion == tonumber(Const.BODY_TAG_VERSION)
                then
                    if not accepted[npcId] then
                        accepted[npcId] = zombie
                        expected = reg.LiveByID and reg.LiveByID[npcId] or nil
                        if expected ~= zombie then
                            reg.LiveByID[npcId] = zombie
                            record.liveBodyInstanceID = zombie.getPersistentOutfitID and zombie:getPersistentOutfitID() or nil
                            record.liveBodyOnlineID = normalizeOnlineID(zombie)
                            stats.rebound = stats.rebound + 1
                        end
                        ensureRuntime(record).lastAuditAt = now
                        mark(record, "live", "bound", "body_audit_valid")
                    else
                        stats.duplicates = stats.duplicates + 1
                        stats.removed = stats.removed + 1
                        noteCleanup(record, "duplicate", "duplicate_lease_removed")
                        removeZombie(zombie)
                    end
                else
                    stats.removed = stats.removed + 1
                    if record then
                        noteCleanup(record, "stale_cleaned", "orphan_body_removed")
                        mark(record, record.presenceState, "stale_cleaned", "orphan_body_removed")
                    end
                    removeZombie(zombie)
                end
            end
        end
    end
    if zombieList then
        reg.ForEach(function(candidate)
            local id = tostring(candidate.id)
            local registered = reg.LiveByID and reg.LiveByID[id] or nil
            if candidate.presenceState == Const.PRESENCE_LIVE and not accepted[id] then
                if registered then
                    removeZombie(registered)
                end
                reg.LiveByID[id] = nil
                candidate.runtime = candidate.runtime or {}
                candidate.runtime.bodyLease = nil
                candidate.liveBodyInstanceID = nil
                candidate.liveBodyOnlineID = nil
                candidate.presenceState = Const.PRESENCE_ABSTRACT
                candidate.presenceRevision = (tonumber(candidate.presenceRevision) or 0) + 1
                mark(candidate, "abstract", "missing", registered and "body_invalid" or "body_pruned")
            end
        end)
    end
    pumpPendingCorpses()
    if force or now >= (tonumber(Lifecycle.NextCorpseAuditAt) or 0) then
        Lifecycle.NextCorpseAuditAt = now + (tonumber(Const.CORPSE_AUDIT_INTERVAL_MS) or 1000)
        auditCorpseBatch(reg)
    end
    Lifecycle.LastAudit = stats
    return stats
end

function Lifecycle.BuildDiagnostics(record)
    local state
    local body
    local bite
    local diagnosticBodyState
    if not record then
        return nil
    end
    state = ensureRuntime(record)
    body = registry() and registry().GetLiveZombie and registry().GetLiveZombie(record.id) or nil
    bite = record.runtime and record.runtime.lastZombieBite or nil
    diagnosticBodyState = state.bodyState
    if record.presenceState == Const.PRESENCE_CORPSE then
        diagnosticBodyState = state.corpseState == "inert_loaded" and "corpse-loaded" or "corpse-missing"
    end
    return {
        id = tostring(record.id),
        name = record.name,
        faction = record.faction,
        presenceState = record.presenceState,
        alive = record.alive ~= false,
        phase = state.phase,
        bodyState = diagnosticBodyState,
        bodyLease = record.runtime and record.runtime.bodyLease or nil,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyInstanceID = record.liveBodyInstanceID,
        x = record.x,
        y = record.y,
        z = record.z,
        lastReason = state.lastReason,
        lastTransitionAt = state.lastTransitionAt,
        lastAuditAt = state.lastAuditAt,
        lastError = state.lastError,
        lastCleanupState = state.lastCleanupState,
        lastCleanupReason = state.lastCleanupReason,
        lastCleanupAt = state.lastCleanupAt,
        corpseState = state.corpseState,
        corpseToken = record.corpse and record.corpse.token or nil,
        bodyActionState = body and body.getActionStateName and body:getActionStateName() or nil,
        activeJob = record.activeJob,
        activeBehavior = record.activeBehavior,
        healthState = record.health and record.health.state or nil,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        targetKind = record.runtime and record.runtime.targetKind or "none",
        combatBlockReason = record.runtime and record.runtime.combatBlockReason or nil,
        bite = bite and Core.DeepCopy(bite) or nil,
    }
end
