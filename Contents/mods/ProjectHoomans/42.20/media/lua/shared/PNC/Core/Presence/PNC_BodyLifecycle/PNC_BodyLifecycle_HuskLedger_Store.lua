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



-- Shared storage dependencies for the ordered ledger providers.
Internal.HuskLedgerStorage = {
    noteIncrement = noteIncrement,
    noteGauge = noteGauge,
    logDebug = logDebug,
    persist = persist,
    worldAgeHours = worldAgeHours,
    ensureLoaded = ensureLoaded,
    chunkKey = chunkKey,
    indexEntry = indexEntry,
    evictPerRecord = evictPerRecord,
    evictOverflow = evictOverflow,
}
Internal.HuskLedgerDebug = {
    noteIncrement = noteIncrement,
    noteGauge = noteGauge,
    logDebug = logDebug,
    worldAgeHours = worldAgeHours,
    persist = persist,
    ensureLoaded = ensureLoaded,
    isMarkedZombie = isMarkedZombie,
    ENTRY_LAYOUT = ENTRY_LAYOUT,
}
Internal.HuskLedgerChunkKey = chunkKey
Internal.HuskLedgerWorldAgeHours = worldAgeHours

return Lifecycle
