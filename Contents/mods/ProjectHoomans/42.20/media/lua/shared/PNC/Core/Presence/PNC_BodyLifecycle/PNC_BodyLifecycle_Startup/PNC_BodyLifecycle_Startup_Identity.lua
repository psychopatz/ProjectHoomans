-- Persisted live-body shell cleanup and relog reconciliation.
--
-- IsoZombie bodies are engine-owned world objects and can be restored before
-- the PNC registry has rebuilt its runtime lease. Treat only bodies with a
-- positive PNC/ledger proof as disposable shells; anonymous bodies remain
-- untouched and make materialization defer until the ambiguity is gone.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

local function isProtectedBody(zombie)
    local ownership
    local ok
    local value
    if not zombie then
        return false
    end
    if zombie.isDead then
        ok, value = pcall(zombie.isDead, zombie)
        if ok and value == true then
            return true
        end
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

Lifecycle.StartupCleanup = Lifecycle.StartupCleanup or {
    begun = false,
    active = false,
    -- Presence must not assume that the engine restore phase is complete
    -- before OnGameStart/OnServerStarted has reconciled restored IsoZombies.
    complete = false,
    passes = 0,
    quietPasses = 0,
    startedAt = 0,
    removed = 0,
    -- The batch reconciler owns this snapshot; materialization only reads it
    -- through Lifecycle.IsStartupRecordBlocked.
    lastBatch = nil,
    settleUntil = 0,
    nextMaterializeAt = 0,
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

local function isDurableShellCarrier(zombie)
    local outfitID
    local ok
    if not zombie or not Lifecycle.IsShellCarrierID
        or not zombie.getPersistentOutfitID
    then
        return false
    end
    ok, outfitID = pcall(zombie.getPersistentOutfitID, zombie)
    if not ok or outfitID == nil then
        return false
    end
    return Lifecycle.IsShellCarrierID(outfitID) == true
end

local function getLiveShellIdentity(zombie)
    local modData
    local npcId
    local strong = false
    local weak = false
    if not zombie or isProtectedBody(zombie) then
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
    -- A virtualized population body does not retain PNC ModData. Its learned
    -- persistent outfit id is the durable carrier, but only ids recorded from
    -- PNC-created bodies are trusted; this avoids treating vanilla Naked
    -- zombies as NPC shells.
    strong = strong or isDurableShellCarrier(zombie)
    return npcId, strong, weak
end

local function getBodyInstanceID(zombie)
    local value = zombie and zombie.getPersistentOutfitID
        and zombie:getPersistentOutfitID() or nil
    if value == nil or tostring(value) == "" or tostring(value) == "0"
        or (tonumber(value) ~= nil and tonumber(value) == 0)
    then
        return nil
    end
    return tostring(value)
end

local function getBodyPopulationID(zombie)
    if Lifecycle.GetBodyPopulationID then
        return Lifecycle.GetBodyPopulationID(zombie)
    end
    return nil
end

local function isCanonicalBody(record, zombie)
    local reg = Internal.registry()
    local modData
    local lease
    if not record or not zombie then
        return false
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData
        and tostring(modData.PNC_UUID or "") == tostring(record.id)
        and tostring(modData.PNC_BodyKind or "live") ~= "corpse"
        and modData.PNC_DeathMarkerID == nil
    then
        lease = record.runtime and record.runtime.bodyLease
        if record.presenceState == Const.PRESENCE_LIVE then
            -- Explicit UUID/live markers are canonical when the active lease
            -- agrees. If an old save has no lease yet, preserve the marked
            -- live body while runtime is rebuilt; a mismatched lease is a
            -- stale shell and must be cleaned.
            return lease == nil
                or modData.PNC_BodyLease == nil
                or tostring(modData.PNC_BodyLease) == tostring(lease)
        end
    end
    if reg and reg.LiveByID and reg.LiveByID[tostring(record.id)] == zombie then
        -- Pointer identity alone is not enough for an attached object: PZ can
        -- recycle an IsoZombie after virtualization. Keep the compatibility
        -- fallback for test/legacy surfaces that expose no square query.
        return not zombie.getCurrentSquare
    end
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

local function populationHintMatches(record, zombie)
    local hint = record and record.runtime and record.runtime.startupBodyHint
        or nil
    local wanted = hint and hint.populationId or nil
    local actual
    if wanted == nil then
        return false
    end
    actual = getBodyPopulationID(zombie)
    return actual ~= nil and tostring(actual) == tostring(wanted)
end

local function startupRecordCandidates(
    reg,
    zombie,
    npcId,
    strongSignature,
    naked
)
    local candidates = {}
    local exact

    -- A persisted UUID is an actor identity, not a location hint. Keep this
    -- fast path, but still reject records which are already terminal corpses.
    exact = npcId and reg and reg.Get and reg.Get(npcId) or nil
    if exact and exact.alive ~= false
        and exact.presenceState ~= Const.PRESENCE_CORPSE
    then
        candidates[1] = {
            record = exact,
            reason = "uuid",
            score = 300000,
            identity = true,
        }
        return candidates
    end
    if not reg or not reg.ForEach then
        return candidates
    end

    reg.ForEach(function(record)
        local distSq
        local score
        local reason
        local identity = false
        if record and record.alive ~= false
            and record.presenceState ~= Const.PRESENCE_CORPSE
        then
            if populationHintMatches(record, zombie) then
                score = 200000
                reason = "population_id"
                identity = true
            elseif naked then
                -- A naked zombie has no PNC identity. It is deliberately not
                -- a cleanup candidate: ordinary zombies can have the same
                -- appearance and may occupy an NPC's previous square.
                return
            end
            if score then
                candidates[#candidates + 1] = {
                    record = record,
                    reason = reason,
                    score = score,
                    identity = identity,
                }
            end
        end
    end)
    return candidates
end

local function resolveRecordForShell(reg, zombie, npcId, strongSignature, naked)
    local candidates = startupRecordCandidates(
        reg,
        zombie,
        npcId,
        strongSignature,
        naked
    )
    local best
    local bestScore
    local topCount = 0
    local i
    if #candidates <= 0 then
        return nil, naked and "unidentified_naked_shell" or nil
    end
    for i = 1, #candidates do
        if not bestScore or candidates[i].score > bestScore then
            best = candidates[i]
            bestScore = candidates[i].score
            topCount = 1
        elseif candidates[i].score == bestScore then
            topCount = topCount + 1
        end
    end
    if topCount > 1 then
        return nil, "ambiguous_" .. tostring(best.reason)
    end
    if best.reason == "signature_position" and #candidates > 1 then
        return nil, "ambiguous_signature_position"
    end
    return best.record, best.reason
end

Internal.StartupListCount = listCount
Internal.IsProtectedBody = isProtectedBody
Internal.IsNakedStartupShell = isNakedShell
Internal.IsDurableShellCarrier = isDurableShellCarrier
Internal.GetLiveShellIdentity = getLiveShellIdentity
Internal.GetStartupBodyInstanceID = getBodyInstanceID
Internal.GetStartupBodyPopulationID = getBodyPopulationID
Internal.IsCanonicalStartupBody = isCanonicalBody
Internal.StartupDistanceSqToRecord = distanceSqToRecord
Internal.StartupBodyHintMatches = bodyHintMatches
Internal.StartupPopulationHintMatches = populationHintMatches
Internal.GetStartupRecordCandidates = startupRecordCandidates
Internal.ResolveRecordForStartupShell = resolveRecordForShell
