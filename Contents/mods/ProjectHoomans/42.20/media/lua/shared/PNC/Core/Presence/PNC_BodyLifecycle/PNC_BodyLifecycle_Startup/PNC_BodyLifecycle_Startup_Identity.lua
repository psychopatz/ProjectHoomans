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

Internal.StartupListCount = listCount
Internal.IsNakedStartupShell = isNakedShell
Internal.GetLiveShellIdentity = getLiveShellIdentity
Internal.GetStartupBodyInstanceID = getBodyInstanceID
Internal.IsCanonicalStartupBody = isCanonicalBody
Internal.StartupDistanceSqToRecord = distanceSqToRecord
Internal.StartupBodyHintMatches = bodyHintMatches
Internal.ResolveRecordForStartupShell = resolveRecordForShell
