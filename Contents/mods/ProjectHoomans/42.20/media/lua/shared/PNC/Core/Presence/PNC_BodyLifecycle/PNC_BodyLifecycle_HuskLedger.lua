--[[
    Husk ledger: where a live shell was lost without a verified removal.

    When a shell leaves the loaded world the engine absorbs it into the
    anonymous population record (position, direction, persistent outfit id and
    state booleans only). PNC ModData - PNC_UUID, PNC_BodyLease, PNC_Owner - is
    destroyed, so nothing downstream can recognize the body that the population
    manager later hands back as a real zombie. That body is the "husk".

    The ledger keeps a bounded, persisted memory of those losses so the reaper
    can delete the husk at the moment it is handed back. Entries only exist for
    bodies that carried an engine identity hint (persistent outfit id); without
    that hint a husk is indistinguishable from an ordinary zombie and we refuse
    to arm a reap rather than risk deleting a vanilla body.

    Entries never leave the ledger except by reaping or expiry, so a save that
    already contains husks is cleaned up on the next load instead of growing.
]]

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

Lifecycle.HuskLedger = Lifecycle.HuskLedger or {
    entries = {},
    index = {},
    shellOutfitIds = {},
    loaded = false,
    writes = 0,
    refreshes = 0,
    reaped = 0,
    expired = 0,
    skipped = 0,
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

local function logDebug(message)
    if Core and Core.LogDebug then
        pcall(Core.LogDebug, message)
    end
end

local function worldAgeHours()
    if type(getGameTime) ~= "function" then
        return 0
    end
    local ok, gameTime = pcall(getGameTime)
    if not ok or not gameTime or not gameTime.getWorldAgeHours then
        return 0
    end
    local hoursOk, hours = pcall(gameTime.getWorldAgeHours, gameTime)
    if not hoursOk then
        return 0
    end
    return tonumber(hours) or 0
end

local function chunkKey(x, y)
    return tostring(math.floor((tonumber(x) or 0) / 8))
        .. ":" .. tostring(math.floor((tonumber(y) or 0) / 8))
end

local function isMarkedZombie(zombie)
    local modData
    if not zombie or not zombie.getModData then
        return false
    end
    modData = zombie:getModData()
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

local function storage()
    if ModData == nil or ModData.getOrCreate == nil then
        return nil
    end
    local key = Const.HUSK_LEDGER_MODDATA_KEY or "PNC_HuskLedger"
    local ok, store = pcall(ModData.getOrCreate, key)
    if ok and type(store) == "table" then
        return store
    end
    return nil
end

local function indexEntry(ledger, entry)
    local key = entry.chunkKey
    if not key then
        return
    end
    local list = ledger.index[key]
    if not list then
        list = {}
        ledger.index[key] = list
    end
    list[#list + 1] = entry
end

local function rebuildIndex(ledger)
    local i
    ledger.index = {}
    for i = 1, #ledger.entries do
        local entry = ledger.entries[i]
        if entry and entry.chunkKey then
            indexEntry(ledger, entry)
        end
    end
end

--[[
    Persisted entry layout.

    Entries are written as positional arrays so the global ModData payload does
    not repeat a key name per field per entry. Field order is append-only and
    guarded by HUSK_LEDGER_LAYOUT_VERSION: bump the version when it changes and
    older rows are discarded instead of misread.

        1 x, 2 y, 3 z, 4 outfitId, 5 at (world hours), 6 attempts,
        7 npcId, 8 reason, 9 abandoned
]]
local ENTRY_LAYOUT = {
    "x", "y", "z", "outfitId", "at", "attempts", "npcId", "reason",
    "abandoned",
}

local function unpackEntry(row)
    local x
    local y
    local z
    if type(row) ~= "table" then
        return nil
    end
    x = tonumber(row[1])
    y = tonumber(row[2])
    z = tonumber(row[3])
    if not x or not y or not z then
        return nil
    end
    return {
        npcId = row[7] ~= nil and tostring(row[7]) or nil,
        x = x,
        y = y,
        z = z,
        outfitId = row[4],
        at = tonumber(row[5]) or 0,
        attempts = math.max(0, math.floor(tonumber(row[6]) or 0)),
        reason = row[8] ~= nil and tostring(row[8]) or nil,
        abandoned = row[9] == true or nil,
        chunkKey = chunkKey(x, y),
    }
end

local function packEntry(entry, row)
    local index
    for index = 1, #ENTRY_LAYOUT do
        local value = entry[ENTRY_LAYOUT[index]]
        if value ~= nil and value ~= false then
            row[index] = value
        end
    end
    return row
end

local function persist(ledger)
    local store = ledger.store
    local packed
    local index
    if not store then
        return
    end
    packed = {}
    for index = 1, #ledger.entries do
        packed[index] = packEntry(ledger.entries[index], {})
    end
    store.entries = packed
    store.shellOutfitIds = ledger.shellOutfitIds
    store.layoutVersion = tonumber(Const.HUSK_LEDGER_LAYOUT_VERSION) or 2
end

local function ensureLoaded()
    local ledger = Lifecycle.HuskLedger
    if ledger.loaded == true then
        return ledger
    end
    ledger.loaded = true
    local store = storage()
    local layoutVersion = tonumber(Const.HUSK_LEDGER_LAYOUT_VERSION) or 2
    local index
    if store then
        if tonumber(store.layoutVersion) ~= layoutVersion then
            -- Unknown layout: drop the rows rather than misread them. Learned
            -- shell outfits are version-stable and kept.
            store.entries = {}
            store.layoutVersion = layoutVersion
        end
        ledger.store = store
        ledger.entries = {}
        if type(store.entries) == "table" then
            for index = 1, #store.entries do
                local entry = unpackEntry(store.entries[index])
                if entry then
                    ledger.entries[#ledger.entries + 1] = entry
                end
            end
        end
        if type(store.shellOutfitIds) == "table" then
            ledger.shellOutfitIds = store.shellOutfitIds
        end
        ledger.store = store
        persist(ledger)
    end
    rebuildIndex(ledger)
    noteGauge("HuskLedger.Entries", #ledger.entries)
    return ledger
end

local function removeEntryAt(ledger, index)
    local entry = ledger.entries[index]
    if not entry then
        return nil
    end
    table.remove(ledger.entries, index)
    local key = entry.chunkKey
    local list = key and ledger.index[key] or nil
    if list then
        local i
        for i = #list, 1, -1 do
            if list[i] == entry then
                table.remove(list, i)
            end
        end
        if #list <= 0 then
            ledger.index[key] = nil
        end
    end
    return entry
end

function Lifecycle.ConsumeHuskEntry(entry)
    local ledger = ensureLoaded()
    local i
    if not entry then
        return false
    end
    for i = #ledger.entries, 1, -1 do
        if ledger.entries[i] == entry then
            removeEntryAt(ledger, i)
            persist(ledger)
            noteGauge("HuskLedger.Entries", #ledger.entries)
            return true
        end
    end
    return false
end

local function countForRecord(ledger, npcId)
    local count = 0
    local i
    if not npcId then
        return 0
    end
    for i = 1, #ledger.entries do
        if ledger.entries[i].npcId == npcId then
            count = count + 1
        end
    end
    return count
end

local function evictPerRecord(ledger, npcId, keep)
    local i
    while countForRecord(ledger, npcId) > keep do
        local oldestIndex
        local oldestAt
        for i = 1, #ledger.entries do
            local entry = ledger.entries[i]
            if entry.npcId == npcId
                and (oldestAt == nil or (tonumber(entry.at) or 0) < oldestAt)
            then
                oldestAt = tonumber(entry.at) or 0
                oldestIndex = i
            end
        end
        if not oldestIndex then
            return
        end
        removeEntryAt(ledger, oldestIndex)
    end
end

local function evictExpired(ledger, hours, ttl)
    local i = #ledger.entries
    while i >= 1 do
        local entry = ledger.entries[i]
        local age = hours - (tonumber(entry.at) or 0)
        -- A backwards clock (new save, debug time skip) must not expire every
        -- entry at once; only forward elapsed world hours count.
        if ttl > 0 and age > ttl then
            removeEntryAt(ledger, i)
            ledger.expired = (tonumber(ledger.expired) or 0) + 1
            noteIncrement("HuskLedger.Expired")
        end
        i = i - 1
    end
end

local function evictOverflow(ledger, maxEntries)
    while #ledger.entries > maxEntries do
        removeEntryAt(ledger, 1)
        ledger.expired = (tonumber(ledger.expired) or 0) + 1
        noteIncrement("HuskLedger.Expired")
    end
end

function Lifecycle.PumpHuskLedger(now)
    local ledger = ensureLoaded()
    local hours
    local ttl
    now = tonumber(now) or 0
    if #ledger.entries <= 0 then
        -- Nothing to expire: keep the per-tick cost at a single length check.
        if now >= (tonumber(ledger.nextExpiryAt) or 0) then
            ledger.nextExpiryAt = now
                + (tonumber(Const.HUSK_LEDGER_EXPIRY_INTERVAL_MS) or 1000)
            noteGauge("HuskLedger.Entries", 0)
        end
        return 0
    end
    if now < (tonumber(ledger.nextExpiryAt) or 0) then
        return #ledger.entries
    end
    ledger.nextExpiryAt = now
        + (tonumber(Const.HUSK_LEDGER_EXPIRY_INTERVAL_MS) or 1000)
    hours = worldAgeHours()
    ttl = tonumber(Const.HUSK_LEDGER_TTL_HOURS) or 168
    local maxEntries = tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 256
    evictExpired(ledger, hours, ttl)
    evictOverflow(ledger, maxEntries)
    persist(ledger)
    noteGauge("HuskLedger.Entries", #ledger.entries)
    return #ledger.entries
end

function Lifecycle.HuskLedgerCount()
    local ledger = ensureLoaded()
    return #ledger.entries
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

--[[
    PNC shell outfit identity.

    Every live shell is dressed with the persistent outfit "Naked", and the
    engine stores the persistent outfit id in the anonymous population record
    that a virtualized shell becomes. That id therefore survives where ModData
    does not, which makes it the one durable hint that a body is (or was) a PNC
    shell.

    The ids are LEARNED from shells PNC actually creates and persisted, so this
    never depends on the outfit script name or on a Lua-side outfit lookup.

    This is deliberately NOT used as a global husk rule: vanilla also dresses
    bathroom zombies with the "Naked" outfit, so matching on the outfit alone
    would delete ordinary zombies. It is only trusted in worlds that cannot
    legitimately contain vanilla zombies at all (zombie spawning disabled), plus
    the strict ledger path everywhere else.
]]
function Lifecycle.NoteShellOutfitID(outfitID)
    local ledger
    local key
    if outfitID == nil then
        return false
    end
    ledger = ensureLoaded()
    key = tostring(outfitID)
    if key == "" or ledger.shellOutfitIds[key] == true then
        return false
    end
    if Lifecycle.ShellOutfitCount() >= (tonumber(
        Const.HUSK_LEDGER_MAX_SHELL_OUTFITS) or 32)
    then
        -- Bounded: the engine picks a shell outfit id per call, so an unbounded
        -- set would grow the persisted diagnostics every session.
        return false
    end
    ledger.shellOutfitIds[key] = true
    persist(ledger)
    noteIncrement("HuskLedger.ShellOutfitsLearned")
    return true
end

function Lifecycle.IsShellOutfitID(outfitID)
    local ledger
    if outfitID == nil then
        return false
    end
    ledger = ensureLoaded()
    return ledger.shellOutfitIds[tostring(outfitID)] == true
end

function Lifecycle.ShellOutfitCount()
    local ledger = ensureLoaded()
    local count = 0
    local _ = nil
    for _ in pairs(ledger.shellOutfitIds) do
        count = count + 1
    end
    return count
end

--[[
    Simple orphan rule for worlds that cannot spawn vanilla zombies.

    When `IsoWorld.getZombiesDisabled()` is true the engine creates no zombies
    at all: every gate (IsoChunk, the population manager, addZombiesInOutfit)
    is shut. Any body in such a world that carries no PNC ModData and is not
    owned by a foreign mod can therefore only be a shell PNC lost - the
    population manager handed a virtualized NPC body back without its ModData.

    That makes the reclaim independent of the persistent outfit id (which a
    Lua-created body cannot set in a disabled world) and independent of any
    recorded loss position: it just deletes the orphan.

    In a normal-population world this is false and the strict ledger path stays
    in force, because vanilla dresses bathroom zombies with the same "Naked"
    outfit that PNC uses.
]]
function Lifecycle.IsOrphanedShell(zombie)
    local ownership
    local ok
    local value
    if not zombie then
        return false
    end
    if not (Lifecycle.AreZombieSpawnsDisabled
        and Lifecycle.AreZombieSpawnsDisabled() == true)
    then
        return false
    end
    -- A reanimated player is a vanilla body that may exist in any world.
    if zombie.isReanimatedPlayer then
        ok, value = pcall(zombie.isReanimatedPlayer, zombie)
        if ok and value == true then
            return false
        end
    end
    ownership = PNC.Compatibility and PNC.Compatibility.ActorOwnership
    if ownership and ownership.IsForeignOwned then
        ok, value = pcall(ownership.IsForeignOwned, zombie)
        if ok and value == true then
            return false
        end
    end
    return true
end

--[[
    Bounded husk census for debug surfaces (console report and the World
    Effects debug window).

    Costs one pass over bodies that are already indexed by the shared world
    census - the same list the presence/aggro lanes read - and never walks the
    engine zombie list itself when that census is available. Everything is
    capped so a multiplayer debug request stays a small payload.
]]
local function clampLimit(value, fallback, maximum)
    local number = math.floor(tonumber(value) or fallback)
    if number < 1 then
        number = 1
    end
    if maximum and number > maximum then
        number = maximum
    end
    return number
end

local function censusBodies(now)
    local census = PNC.WorldCensus
    if census and census.GetAll then
        local bodies = census.GetAll(now, false)
        if type(bodies) == "table" then
            return bodies
        end
    end
    if getCell then
        local cell = getCell()
        local list = cell and cell.getZombieList and cell:getZombieList() or nil
        local output = {}
        local index
        if list and list.size and list.get then
            for index = 0, list:size() - 1 do
                output[#output + 1] = list:get(index)
            end
        end
        return output
    end
    return nil
end

local function estimateEntryBytes(entry)
    local bytes = 24
    local index
    for index = 1, #ENTRY_LAYOUT do
        local value = entry[ENTRY_LAYOUT[index]]
        if type(value) == "string" then
            bytes = bytes + #value + 4
        elseif type(value) == "number" then
            bytes = bytes + 10
        elseif value ~= nil then
            bytes = bytes + 4
        end
    end
    return bytes
end

function Lifecycle.BuildHuskDebugSnapshot(options)
    local ledger = ensureLoaded()
    local reaper = Lifecycle.HuskReaper
    local entries = {}
    local outfitRows = {}
    local outfits = {}
    local totals = {
        bodies = 0, marked = 0, unmarked = 0, fingerprint = 0, orphans = 0,
        bytes = 0,
    }
    local entryLimit
    local outfitLimit
    local hours
    local bodies
    local index
    options = type(options) == "table" and options or {}
    entryLimit = clampLimit(options.entryLimit
        or Const.HUSK_DEBUG_MAX_ENTRIES or 12, 12, 64)
    outfitLimit = clampLimit(options.outfitLimit
        or Const.HUSK_DEBUG_MAX_OUTFITS or 8, 8, 24)
    hours = worldAgeHours()
    for index = 1, #ledger.entries do
        local entry = ledger.entries[index]
        totals.bytes = totals.bytes + estimateEntryBytes(entry)
        if #entries < entryLimit then
            entries[#entries + 1] = {
                npcId = entry.npcId,
                x = entry.x,
                y = entry.y,
                z = entry.z,
                outfitId = entry.outfitId,
                ageHours = math.max(0,
                    math.floor((hours - (tonumber(entry.at) or hours)) * 10)
                        / 10),
                attempts = tonumber(entry.attempts) or 0,
                abandoned = entry.abandoned == true,
                reason = entry.reason,
            }
        end
    end
    bodies = censusBodies(Core and Core.Now and Core.Now() or 0)
    if type(bodies) == "table" then
        for index = 1, #bodies do
            local zombie = bodies[index]
            if zombie then
                totals.bodies = totals.bodies + 1
                if isMarkedZombie(zombie) then
                    totals.marked = totals.marked + 1
                else
                    local outfitId = zombie.getPersistentOutfitID
                        and zombie:getPersistentOutfitID() or nil
                    local key = tostring(outfitId)
                    local row = outfits[key]
                    totals.unmarked = totals.unmarked + 1
                    if Lifecycle.IsOrphanedShell(zombie) then
                        totals.orphans = totals.orphans + 1
                    end
                    if not row then
                        row = {
                            id = outfitId,
                            key = key,
                            count = 0,
                            shell = Lifecycle.IsShellOutfitID(outfitId),
                        }
                        outfits[key] = row
                        outfitRows[#outfitRows + 1] = row
                    end
                    row.count = row.count + 1
                    if row.shell then
                        totals.fingerprint = totals.fingerprint + 1
                    end
                end
            end
        end
    end
    table.sort(outfitRows, function(left, right)
        if left.shell ~= right.shell then
            return left.shell == true
        end
        if left.count ~= right.count then
            return left.count > right.count
        end
        return tostring(left.key) < tostring(right.key)
    end)
    while #outfitRows > outfitLimit do
        outfitRows[#outfitRows] = nil
    end
    local outfitIds = {}
    local outfitId = nil
    for outfitId in pairs(ledger.shellOutfitIds) do
        outfitIds[#outfitIds + 1] = tostring(outfitId)
    end
    table.sort(outfitIds)
    while #outfitIds > outfitLimit do
        outfitIds[#outfitIds] = nil
    end
    return {
        available = true,
        ledger = {
            entries = #ledger.entries,
            maxEntries = tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 48,
            writes = tonumber(ledger.writes) or 0,
            refreshes = tonumber(ledger.refreshes) or 0,
            reaped = tonumber(ledger.reaped) or 0,
            expired = tonumber(ledger.expired) or 0,
            skipped = tonumber(ledger.skipped) or 0,
            seeds = tonumber(ledger.seeds) or 0,
            ttlHours = tonumber(Const.HUSK_LEDGER_TTL_HOURS) or 168,
            estimatedBytes = totals.bytes,
        },
        shellOutfits = {
            count = Lifecycle.ShellOutfitCount(),
            ids = table.concat(outfitIds, ","),
        },
        reaper = {
            active = reaper and reaper.loggedActive == true or false,
            reaped = reaper and tonumber(reaper.reaped) or 0,
            pending = reaper and #(reaper.pending or {}) or 0,
            failed = reaper and tonumber(reaper.failed) or 0,
            abandoned = reaper and tonumber(reaper.abandoned) or 0,
            fingerprintReaps = reaper
                and tonumber(reaper.fingerprintReaps) or 0,
        },
        bodies = {
            disabled = Lifecycle.AreZombieSpawnsDisabled
                and Lifecycle.AreZombieSpawnsDisabled() == true or false,
            total = totals.bodies,
            marked = totals.marked,
            unmarked = totals.unmarked,
            fingerprint = totals.fingerprint,
            orphans = totals.orphans,
            outfits = outfitRows,
        },
        entries = entries,
        truncated = #ledger.entries > #entries,
    }
end

--[[
    One-line live diagnosis for the husk lane, for the debug console.
]]
function Lifecycle.DebugHuskReport(limit)
    local snapshot = Lifecycle.BuildHuskDebugSnapshot({
        entryLimit = limit or (Const.HUSK_DEBUG_MAX_ENTRIES or 12),
    })
    local ledger = snapshot.ledger
    local reaper = snapshot.reaper
    local bodies = snapshot.bodies
    local parts = {}
    local index
    for index = 1, #bodies.outfits do
        local row = bodies.outfits[index]
        parts[#parts + 1] = tostring(row.key) .. "x" .. tostring(row.count)
            .. (row.shell and "*" or "")
    end
    return table.concat({
        "ledger=" .. tostring(ledger.entries),
        "writes=" .. tostring(ledger.writes),
        "shellOutfits=" .. tostring(snapshot.shellOutfits.count),
        "shellOutfitIds=" .. tostring(snapshot.shellOutfits.ids),
        "zombiesDisabled=" .. tostring(bodies.disabled),
        "bodies=" .. tostring(bodies.total),
        "marked=" .. tostring(bodies.marked),
        "unmarked=" .. tostring(bodies.unmarked),
        "fingerprint=" .. tostring(bodies.fingerprint),
        "orphans=" .. tostring(bodies.orphans),
        "reaped=" .. tostring(reaper.reaped),
        "abandoned=" .. tostring(reaper.abandoned),
        "estBytes=" .. tostring(ledger.estimatedBytes),
        "unmarkedOutfits=" .. table.concat(parts, ","),
    }, " ")
end

--[[
    Drop every recorded loss and persist the empty ledger. Safe to call at any
    time; the reaper simply has nothing to reclaim until new losses arrive.
]]
function Lifecycle.ClearHuskLedger()
    local ledger = ensureLoaded()
    ledger.entries = {}
    ledger.index = {}
    persist(ledger)
    noteGauge("HuskLedger.Entries", 0)
    return true
end

--[[
    Seed the ledger from persisted body hints.

    A save created before this lifecycle existed already contains husks whose
    losses were never observed, so nothing can arm a reap for them. Every
    deserialized record that still carries a body hint (the engine persistent
    outfit id plus the position its shell last occupied) is exactly a shell that
    the population manager may hand back unmarked. Seeding is authority-only,
    once per session, and bounded by the ledger cap; an entry whose hint no
    longer matches any body simply expires.
]]
function Lifecycle.SeedHuskLedgerFromRecords(now)
    local reg = Internal.registry and Internal.registry() or nil
    local seeded = 0
    local budget = tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 256
    if Lifecycle.HuskLedgerSeeded == true then
        return 0
    end
    if not (Core and Core.IsAuthority and Core.IsAuthority() == true) then
        return 0
    end
    if not reg or not reg.ForEach or not reg.EnsureLoaded then
        return 0
    end
    reg.EnsureLoaded()
    if reg.Loaded ~= true then
        -- Wait for the registry to exist before deciding a record is bodyless.
        return 0
    end
    Lifecycle.HuskLedgerSeeded = true
    reg.ForEach(function(record)
        local hint
        local registry
        local zombie
        if seeded >= budget then
            return
        end
        if not record or record.alive == false then
            return
        end
        if Const.PRESENCE_CORPSE ~= nil
            and record.presenceState == Const.PRESENCE_CORPSE
        then
            return
        end
        hint = record.runtime and record.runtime.startupBodyHint or nil
        if not hint or hint.instanceID == nil then
            return
        end
        registry = Internal.registry and Internal.registry() or nil
        zombie = registry and registry.GetLiveZombie
            and registry.GetLiveZombie(record.id) or nil
        if zombie and Internal.isBodyAttached(zombie) == true then
            return
        end
        if Lifecycle.NoteLostBody(record, nil, "startup_seed") then
            seeded = seeded + 1
        end
    end)
    if seeded > 0 then
        noteIncrement("HuskLedger.Seeds")
        logDebug("PNC husk ledger seeded from persisted body hints count="
            .. tostring(seeded))
    end
    return seeded
end

function Lifecycle.BuildHuskLedgerDiagnostics()
    local ledger = ensureLoaded()
    return {
        entries = #ledger.entries,
        writes = tonumber(ledger.writes) or 0,
        refreshes = tonumber(ledger.refreshes) or 0,
        reaped = tonumber(ledger.reaped) or 0,
        expired = tonumber(ledger.expired) or 0,
        skipped = tonumber(ledger.skipped) or 0,
        lastFactory = Lifecycle.BodyFactory
            and Lifecycle.BodyFactory.lastFactory or nil,
    }
end

Internal.HuskLedgerChunkKey = chunkKey
Internal.HuskLedgerWorldAgeHours = worldAgeHours
