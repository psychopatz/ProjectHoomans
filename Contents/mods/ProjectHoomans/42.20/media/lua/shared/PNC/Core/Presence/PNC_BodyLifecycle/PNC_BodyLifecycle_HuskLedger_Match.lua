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

local function safeMember(object, name)
    local ok, value = pcall(function() return object and object[name] end)
    return ok and value or nil
end

local function validEngineIdentity(value)
    local numeric
    if value == nil then
        return false
    end
    if tostring(value) == "" or tostring(value) == "0" then
        return false
    end
    numeric = tonumber(value)
    return numeric == nil or numeric ~= 0
end

local function populationIDOf(zombie)
    local value
    local getter
    if not zombie then
        return nil
    end
    value = safeMember(zombie, "persistentId")
    if value == nil then
        getter = safeMember(zombie, "getPersistentID")
        if not getter then
            getter = safeMember(zombie, "getPersistentId")
        end
        if getter then
            local ok, result = pcall(getter, zombie)
            if ok then value = result end
        end
    end
    value = tonumber(value)
    if not value or value == 0 then
        return nil
    end
    return tostring(value)
end

function Lifecycle.GetBodyPopulationID(zombie)
    return populationIDOf(zombie)
end

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
    local readFromEngine = false
    if zombie and zombie.getPersistentOutfitID then
        readFromEngine = true
        local ok, outfitID = pcall(zombie.getPersistentOutfitID, zombie)
        if ok then
            value = outfitID
        end
    end
    -- A returned zero is an explicit engine result, not a missing API. Never
    -- replace it with an old record hint: doing so turns a non-identifying
    -- zombie into a false positive during startup cleanup.
    if not readFromEngine and value == nil and record then
        value = record.liveBodyInstanceID
            or (record.runtime and record.runtime.lastIdentityOutfitID)
            or (record.runtime and record.runtime.lastLiveBodyInstanceID)
            or (record.runtime and record.runtime.startupBodyHint
                and record.runtime.startupBodyHint.instanceID)
            or nil
    end
    if not validEngineIdentity(value) then
        return nil
    end
    return tostring(value)
end

local function samePosition(entry, zombie, radiusSq)
    local dx
    local dy
    local dz
    if not entry or not zombie then
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

local function isUnmarkedBody(zombie)
    local modData
    if not zombie then
        return false
    end
    if isProtectedBody(zombie) then
        return false
    end
    if PNC.Core and PNC.Core.IsManagedNPCBody
        and PNC.Core.IsManagedNPCBody(zombie) == true
    then
        return false
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if not modData then
        return true
    end
    return modData.PNC_UUID == nil
        and modData.PNC_NPC ~= true
        and modData.PNC_Owner == nil
        and modData.PNC_PersistedShell ~= true
        and modData.PNC_BodyLease == nil
        and modData.PNC_TagVersion == nil
        and modData.PNC_DeathMarkerID == nil
end

-- Historical zero-ID rows are retained for diagnostics, but position,
-- companion ownership and gender cannot prove which vanilla zombie they name.
function Lifecycle.IsLegacyAnonymousHusk(entry, zombie)
    return false
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
    local populationId = populationIDOf(zombie)
        or (record and validEngineIdentity(record.liveBodyPopulationID)
            and tostring(record.liveBodyPopulationID) or nil)
        or (record and record.runtime
            and validEngineIdentity(record.runtime.lastIdentityPopulationID)
            and tostring(record.runtime.lastIdentityPopulationID) or nil)
        or (record and record.runtime
            and validEngineIdentity(record.runtime.lastLiveBodyPopulationID)
            and tostring(record.runtime.lastLiveBodyPopulationID) or nil)
        or (record and record.runtime and record.runtime.startupBodyHint
            and validEngineIdentity(
                record.runtime.startupBodyHint.populationId
            )
            and tostring(record.runtime.startupBodyHint.populationId) or nil)
    local key
    local existing
    local entry

    local function sameLossIdentity(candidate)
        local candidateOutfit = candidate and candidate.outfitId or nil
        local candidatePopulation = candidate and candidate.populationId or nil
        if not candidate or candidate.abandoned == true then
            return false
        end
        -- A new persistent outfit or population id is a different carrier.
        -- Keep both rows: the engine can hand either virtualized shell back
        -- after the record has already been materialized again.
        if validEngineIdentity(candidateOutfit)
            and validEngineIdentity(hint)
            and tostring(candidateOutfit) ~= tostring(hint)
        then
            return false
        end
        if validEngineIdentity(candidatePopulation)
            and validEngineIdentity(populationId)
            and tostring(candidatePopulation) ~= tostring(populationId)
        then
            return false
        end
        return true
    end
    if not (Core and Core.IsAuthority and Core.IsAuthority() == true) then
        -- Only the authority owns the population records a husk comes from.
        return nil
    end
    if not x or not y or not z then
        ledger.skipped = (tonumber(ledger.skipped) or 0) + 1
        return nil
    end
    if hint == nil and populationId == nil then
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
            if candidate.npcId == npcId and candidate.chunkKey == key
                and sameLossIdentity(candidate)
            then
                existing = candidate
                break
            end
        end
    end
    if existing then
        existing.x = x
        existing.y = y
        existing.z = z
        existing.outfitId = hint or existing.outfitId
        existing.populationId = populationId or existing.populationId
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
        populationId = populationId,
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

local function matchesEntry(entry, zombie, radiusSq, includeAbandoned)
    local outfitId
    local populationId
    local dx
    local dy
    local dz
    if not entry or not zombie then
        return false
    end
    -- An abandoned entry is kept only as a record of an unreapable husk: it must
    -- never queue another removal attempt.
    if entry.abandoned == true and includeAbandoned ~= true then
        return false
    end
    if validEngineIdentity(entry.populationId) then
        populationId = populationIDOf(zombie)
        -- The population id is the strongest identity and survives the
        -- engine's virtualization boundary. A population-only ledger entry is
        -- safe to match; an ordinary zombie cannot claim another population
        -- record's exact id.
        if populationId == nil
            or tostring(entry.populationId) ~= tostring(populationId)
        then
            if populationId ~= nil then
                return false
            end
        else
            return true
        end
    end
    outfitId = outfitHint(nil, zombie)
    -- PNCShellCarrier is a positive PNC-owned fingerprint. Once a carrier id
    -- has been learned from a body PNC created, its exact outfit id remains a
    -- safe identity match even if the population manager moved the returned
    -- husk before the next audit/reaper pump. This is intentionally narrower
    -- than the legacy positional Naked lane.
    if isUnmarkedBody(zombie)
        and validEngineIdentity(entry.outfitId)
        and outfitId ~= nil
        and tostring(entry.outfitId) == tostring(outfitId)
        and Lifecycle.IsShellCarrierID
        and Lifecycle.IsShellCarrierID(outfitId) == true
    then
        return true
    end
    if not validEngineIdentity(entry.outfitId) then
        return false
    end
    if outfitId == nil
        or tostring(entry.outfitId) ~= tostring(outfitId)
    then
        return false
    end
    return samePosition(entry, zombie, radiusSq)
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
    same engine persistent outfit id, sits within the recorded radius and on
    the same level. When the engine exposes its population id, that id must
    also agree. The outfit/position proof remains for the create-event window
    before the population manager assigns the returned body's id.
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
    local populationId
    local outfitId
    if #ledger.entries <= 0 or not zombie or not zombie.getX then
        return nil
    end
    -- Search the bounded ledger by exact population identity before using the
    -- positional index. The body may have moved after being handed back, but
    -- the exact engine identity remains safe and authoritative.
    populationId = populationIDOf(zombie)
    if populationId ~= nil then
        for i = 1, #ledger.entries do
            if ledger.entries[i].abandoned ~= true
                and validEngineIdentity(ledger.entries[i].populationId)
                and tostring(ledger.entries[i].populationId)
                    == tostring(populationId)
            then
                return ledger.entries[i]
            end
        end
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
    -- A carrier shell may be restored at a new position. Search the bounded
    -- historical ledger by exact learned carrier id after the cheap spatial
    -- index, so repeated live/abstract churn cannot become an anonymous reap.
    outfitId = outfitHint(nil, zombie)
    if outfitId ~= nil and Lifecycle.IsShellCarrierID
        and Lifecycle.IsShellCarrierID(outfitId) == true
    then
        for i = 1, #ledger.entries do
            if matchesEntry(ledger.entries[i], zombie, radiusSq) then
                return ledger.entries[i]
            end
        end
    end
    return nil
end

-- Revalidation hook used by the reaper between queueing and removal.
function Lifecycle.HuskLedgerMatchesEntry(zombie, entry, includeAbandoned)
    if not entry or not zombie then
        return false
    end
    local radius = tonumber(Const.HUSK_LEDGER_MATCH_RADIUS) or 2
    return matchesEntry(
        entry,
        zombie,
        radius * radius,
        includeAbandoned == true
    )
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
            -- Queueing no longer consumes an entry before verified removal.
            -- Persist here so failed-removal attempts and abandonment remain
            -- durable when the already-armed row is revalidated.
            persist(ledger)
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
