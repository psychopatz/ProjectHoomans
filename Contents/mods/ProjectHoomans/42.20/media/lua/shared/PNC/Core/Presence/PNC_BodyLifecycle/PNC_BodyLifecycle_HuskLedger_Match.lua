PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const
local Deps = Internal.HuskLedgerStorage or {}
local ensureLoaded = Deps.ensureLoaded
local indexEntry = Deps.indexEntry
local chunkKey = Deps.chunkKey
local evictOverflow = Deps.evictOverflow
local evictPerRecord = Deps.evictPerRecord
local noteIncrement = Deps.noteIncrement
local noteGauge = Deps.noteGauge
local worldAgeHours = Deps.worldAgeHours
local logDebug = Deps.logDebug
local persist = Deps.persist

local function positionOf(record, zombie)
    local x
    local y
    local z
    if zombie and zombie.getX then
        local ok, bodyX, bodyY, bodyZ = pcall(function()
            return zombie:getX(), zombie:getY(), zombie:getZ()
        end)
        if ok then
            x, y, z = bodyX, bodyY, bodyZ
        end
    end
    if x == nil or y == nil or z == nil then
        -- The persisted body hint is the exact position the lost shell last
        -- occupied, so it is a better anchor than the record position.
        local hint = record and record.runtime
            and record.runtime.startupBodyHint or nil
        if hint and hint.x ~= nil and hint.y ~= nil and hint.z ~= nil then
            x, y, z = hint.x, hint.y, hint.z
        else
            x = record and record.x or nil
            y = record and record.y or nil
            z = record and record.z or nil
        end
    end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then
        return nil
    end
    return x, y, z
end

local function outfitHint(record, zombie)
    local value
    if zombie and zombie.getPersistentOutfitID then
        local ok, outfitID = pcall(zombie.getPersistentOutfitID, zombie)
        if ok then
            value = outfitID
        end
    end
    if value == nil and record then
        value = record.liveBodyInstanceID
            or (record.runtime and record.runtime.startupBodyHint
                and record.runtime.startupBodyHint.instanceID)
            or nil
    end
    if value == nil then
        return nil
    end
    return tostring(value)
end

--[[
    Record that `record` lost `zombie` without a verified removal.

    Returns the ledger entry, or nil when there is no engine identity hint to
    correlate the husk with later.
]]
function Lifecycle.NoteLostBody(record, zombie, reason)
    local ledger = ensureLoaded()
    local x, y, z = positionOf(record, zombie)
    local npcId = record and record.id ~= nil and tostring(record.id) or nil
    local hint = outfitHint(record, zombie)
    local key
    local existing
    local entry
    if not (Core and Core.IsAuthority and Core.IsAuthority() == true) then
        -- Only the authority owns the population records a husk comes from.
        return nil
    end
    if not x or not y or not z then
        ledger.skipped = (tonumber(ledger.skipped) or 0) + 1
        return nil
    end
    if hint == nil then
        -- No engine identity hint means the resurrected body is
        -- indistinguishable from an ordinary zombie. Prefer a permanent husk
        -- over deleting a vanilla zombie.
        ledger.skipped = (tonumber(ledger.skipped) or 0) + 1
        noteIncrement("HuskLedger.SkippedUnidentifiable")
        logDebug("PNC husk ledger skipped npc=" .. tostring(npcId or "unknown")
            .. " reason=no_identity_hint loss=" .. tostring(reason or "unknown"))
        return nil
    end
    key = chunkKey(x, y)
    if npcId then
        local i
        for i = 1, #ledger.entries do
            local candidate = ledger.entries[i]
            if candidate.npcId == npcId and candidate.chunkKey == key then
                existing = candidate
                break
            end
        end
    end
    if existing then
        existing.x = x
        existing.y = y
        existing.z = z
        existing.outfitId = hint
        existing.at = worldAgeHours()
        existing.reason = reason ~= nil and tostring(reason) or existing.reason
        existing.attempts = 0
        ledger.refreshes = (tonumber(ledger.refreshes) or 0) + 1
        noteIncrement("HuskLedger.Refreshes")
        persist(ledger)
        return existing
    end
    entry = {
        npcId = npcId,
        x = x,
        y = y,
        z = z,
        outfitId = hint,
        at = worldAgeHours(),
        attempts = 0,
        reason = reason ~= nil and tostring(reason) or nil,
        chunkKey = key,
    }
    ledger.entries[#ledger.entries + 1] = entry
    indexEntry(ledger, entry)
    ledger.writes = (tonumber(ledger.writes) or 0) + 1
    noteIncrement("HuskLedger.Writes")
    if npcId then
        evictPerRecord(ledger, npcId,
            tonumber(Const.HUSK_LEDGER_MAX_PER_RECORD) or 2)
    end
    evictOverflow(ledger, tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 256)
    persist(ledger)
    noteGauge("HuskLedger.Entries", #ledger.entries)
    logDebug("PNC husk ledger entry npc=" .. tostring(npcId or "unknown")
        .. " pos=" .. tostring(math.floor(x)) .. "," .. tostring(math.floor(y))
        .. "," .. tostring(math.floor(z))
        .. " outfitId=" .. tostring(hint)
        .. " reason=" .. tostring(reason or "unknown"))
    return entry
end

local function matchesEntry(entry, zombie, radiusSq)
    local outfitId
    local dx
    local dy
    local dz
    if not entry or entry.outfitId == nil or not zombie then
        return false
    end
    -- An abandoned entry is kept only as a record of an unreapable husk: it must
    -- never queue another removal attempt.
    if entry.abandoned == true then
        return false
    end
    outfitId = outfitHint(nil, zombie)
    if outfitId == nil or tostring(entry.outfitId) ~= tostring(outfitId) then
        return false
    end
    dz = (tonumber(zombie:getZ()) or 0) - (tonumber(entry.z) or 0)
    if math.abs(dz) > 1 then
        return false
    end
    dx = (tonumber(zombie:getX()) or 0) - (tonumber(entry.x) or 0)
    dy = (tonumber(zombie:getY()) or 0) - (tonumber(entry.y) or 0)
    return (dx * dx + dy * dy) <= radiusSq
end

local function findInChunk(ledger, key, zombie, radiusSq)
    local list = ledger.index[key]
    local i
    if not list then
        return nil
    end
    for i = 1, #list do
        if matchesEntry(list[i], zombie, radiusSq) then
            return list[i]
        end
    end
    return nil
end

--[[
    Find the ledger entry a freshly created body resurrects.

    Strict by construction: an entry only matches when the body carries the
    same engine persistent outfit id, sits within the recorded radius and on the
    same level. A population record keeps those fields, so the match survives
    chunk reload and save/load.
]]
function Lifecycle.FindHuskEntry(zombie)
    local ledger = ensureLoaded()
    local radius = tonumber(Const.HUSK_LEDGER_MATCH_RADIUS) or 2
    local radiusSq = radius * radius
    local x
    local y
    local baseChunkX
    local baseChunkY
    local offsetX
    local offsetY
    local i
    local j
    if #ledger.entries <= 0 or not zombie or not zombie.getX then
        return nil
    end
    x = tonumber(zombie:getX())
    y = tonumber(zombie:getY())
    if not x or not y then
        return nil
    end
    baseChunkX = math.floor(x / 8)
    baseChunkY = math.floor(y / 8)
    for i = -1, 1 do
        for j = -1, 1 do
            local key = tostring(baseChunkX + i) .. ":" .. tostring(baseChunkY + j)
            local entry = findInChunk(ledger, key, zombie, radiusSq)
            if entry then
                return entry
            end
        end
    end
    return nil
end

-- Revalidation hook used by the reaper between queueing and removal.
function Lifecycle.HuskLedgerMatchesEntry(zombie, entry)
    if not entry or not zombie then
        return false
    end
    local radius = tonumber(Const.HUSK_LEDGER_MATCH_RADIUS) or 2
    return matchesEntry(entry, zombie, radius * radius)
end

-- Put a loss back after a failed removal attempt. Keeps the entry bounded by
-- the same eviction rules as a fresh write and preserves its attempt count.
function Lifecycle.HuskLedgerRearm(entry)
    local ledger = ensureLoaded()
    local i
    if not entry or not entry.chunkKey then
        return false
    end
    for i = 1, #ledger.entries do
        if ledger.entries[i] == entry then
            return true
        end
    end
    if #ledger.entries >= (tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 256) then
        return false
    end
    ledger.entries[#ledger.entries + 1] = entry
    indexEntry(ledger, entry)
    evictOverflow(ledger, tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 256)
    persist(ledger)
    noteIncrement("HuskLedger.Rearms")
    noteGauge("HuskLedger.Entries", #ledger.entries)
    return true
end



return Lifecycle
