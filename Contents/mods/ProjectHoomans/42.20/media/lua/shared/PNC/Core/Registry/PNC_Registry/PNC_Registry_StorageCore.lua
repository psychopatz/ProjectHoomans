PNC = PNC or {}
PNC.Registry = PNC.Registry or {}

local Registry = PNC.Registry
local Internal = Registry.Internal
local Core = PNC.Core
local Const = PNC.Const
local Persistence = PNC.Persistence or {}
PNC.Persistence = Persistence
local Reset = Persistence.Reset
    or require "PNC/Core/Persistence/PNC_ModDataStore"

Registry.Data = Registry.Data or {}
-- Non-persistent logical views of canonical Core actors. These entries are
-- addressable by runtime services (conversation/social/etc.) but are never
-- enumerated as Hoomans-owned NPCs and never enter ModData/scheduler/spatial
-- persistence.
Registry.RuntimeViews = Registry.RuntimeViews or {}
Registry.LiveByID = Registry.LiveByID or {}
Registry.DirtyByID = Registry.DirtyByID or {}
Registry.DirtyDomains = Registry.DirtyDomains or {}
Registry.SavedSnapshots = Registry.SavedSnapshots or {}
Registry.RetryState = Registry.RetryState or {}
Registry.Loaded = Registry.Loaded or false
Registry.DirectoryDirty = Registry.DirectoryDirty or false
Registry.CoreStoreDirty = Registry.CoreStoreDirty == true
Registry.LastFlushCount = Registry.LastFlushCount or 0
Registry.LastCheckpointAt = tonumber(Registry.LastCheckpointAt) or 0
Registry._checkpointCursor = tonumber(Registry._checkpointCursor) or 0
Registry.PersistenceMetrics = Registry.PersistenceMetrics or {
    written = 0,
    terminal = 0,
    retryable = 0,
    retriesScheduled = 0,
    retriesExhausted = 0,
    checkpointScans = 0,
    checkpointDirtyMarks = 0,
    flushCalls = 0,
}
Registry.PersistenceDiagnostics = Registry.PersistenceDiagnostics or {
    terminalEvents = {},
    retryEvents = {},
    maxEntries = 32,
}

local function hasEntries(tbl)
    if type(tbl) ~= "table" then return false end
    for _ in pairs(tbl) do
        return true
    end
    return false
end

local function recordPersistenceEvent(bucket, entry)
    local diag = Registry.PersistenceDiagnostics
    if type(diag) ~= "table" then return end
    local list = diag[bucket]
    if type(list) ~= "table" then
        list = {}
        diag[bucket] = list
    end
    list[#list + 1] = entry
    local limit = tonumber(diag.maxEntries) or 32
    while #list > limit do
        table.remove(list, 1)
    end
end

local function storageKeyForID(id)
    local prefix = tostring(Const.MODDATA_NPC_PREFIX or "PNC_npc")
    local value = tostring(id)
    if string.sub(value, 1, 3) == "npc" then
        return "PNC_" .. value
    end
    return prefix .. "_" .. value
end

local function captureSnapshot(record)
    local stamina = record and record.stamina or nil
    local staminaCurrent = stamina and tonumber(stamina.current) or nil
    local staminaMax = stamina and tonumber(stamina.max) or nil
    if type(record) ~= "table" then return nil end
    if staminaCurrent ~= nil and staminaMax ~= nil
        and math.abs(staminaCurrent - staminaMax) < 0.01
    then
        staminaCurrent = nil
    end
    return {
        x = tonumber(record.x) or 0,
        y = tonumber(record.y) or 0,
        z = tonumber(record.z) or 0,
        staminaCurrent = staminaCurrent,
    }
end

local function numberChanged(left, right, epsilon)
    if left == nil or right == nil then return left ~= right end
    return math.abs((tonumber(left) or 0) - (tonumber(right) or 0))
        > (tonumber(epsilon) or 0)
end

local function snapshotChanged(previous, current)
    if not previous or not current then return previous ~= current end
    return numberChanged(previous.x, current.x, 0.001)
        or numberChanged(previous.y, current.y, 0.001)
        or numberChanged(previous.z, current.z, 0.001)
        or numberChanged(
            previous.staminaCurrent,
            current.staminaCurrent,
            0.01
        )
end

local function markSnapshotChanges()
    local id
    local record
    local current
    for id, record in pairs(Registry.Data) do
        if record and record.persist ~= false then
            current = captureSnapshot(record)
            if snapshotChanged(Registry.SavedSnapshots[id], current) then
                Registry.MarkDirty(record, "save_snapshot")
            end
        end
    end
end

function Registry.PumpPhysicalCheckpoints(now, options)
    if not Core or not Core.IsAuthority or not Core.IsAuthority() then
        return 0, 0
    end
    options = type(options) == "table" and options or {}
    now = tonumber(now) or (Core.Now and Core.Now()) or 0
    local intervalMs = tonumber(
        Const and Const.PERSISTENCE_CHECKPOINT_INTERVAL_MS
    ) or 5000
    if options.force ~= true
        and (now - (tonumber(Registry.LastCheckpointAt) or 0)) < intervalMs
    then
        return 0, 0
    end
    Registry.LastCheckpointAt = now

    if type(Registry.RefreshLivePositions) == "function" then
        Registry.RefreshLivePositions(false)
    end

    local ids = {}
    for id, record in pairs(Registry.Data or {}) do
        if record and record.persist ~= false then
            ids[#ids + 1] = tostring(id)
        end
    end
    local total = #ids
    local metrics = Registry.PersistenceMetrics
    if total == 0 then
        if metrics then
            metrics.checkpointScans = (tonumber(metrics.checkpointScans) or 0) + 1
        end
        return 0, 0
    end
    table.sort(ids)

    local budget = math.max(1, math.floor(tonumber(
        options.maxRecords
            or (Const and Const.PERSISTENCE_CHECKPOINT_MAX_RECORDS)
            or 8
    )))
    local scanLimit = math.min(total, budget)
    local startCursor = (tonumber(Registry._checkpointCursor) or 0) % total
    local scanned = 0
    local dirtyMarked = 0

    for offset = 0, scanLimit - 1 do
        local idx = ((startCursor + offset) % total) + 1
        local id = ids[idx]
        local record = Registry.Data[id]
        scanned = scanned + 1
        if record and record.persist ~= false
            and not (Registry.DirtyByID and Registry.DirtyByID[id])
        then
            local current = captureSnapshot(record)
            if snapshotChanged(Registry.SavedSnapshots[id], current) then
                Registry.MarkDirty(record, "physical_checkpoint")
                dirtyMarked = dirtyMarked + 1
            end
        end
    end

    Registry._checkpointCursor = (startCursor + scanned) % total
    if metrics then
        metrics.checkpointScans = (tonumber(metrics.checkpointScans) or 0) + 1
        metrics.checkpointDirtyMarks =
            (tonumber(metrics.checkpointDirtyMarks) or 0) + dirtyMarked
    end
    return dirtyMarked, scanned
end

Registry.StorageKeyForID = storageKeyForID

local function getDirectory()
    local directory = ModData.getOrCreate(Const.MODDATA_KEY)
    directory.layoutVersion = tonumber(directory.layoutVersion) or 0
    directory.schemaVersion = tonumber(directory.schemaVersion) or 0
    directory.directoryRevision = math.max(0, math.floor(tonumber(directory.directoryRevision) or 0))
    directory.records = type(directory.records) == "table" and directory.records or {}
    directory.deathMarkers = type(directory.deathMarkers) == "table"
        and directory.deathMarkers or {}
    directory.repairVersions = Persistence.Repairs
        and Persistence.Repairs.NormalizeVersions(directory.repairVersions)
        or {}
    return directory
end

Registry.GetStorageDirectory = getDirectory

local function assignModData(key, payload)
    local target = ModData.getOrCreate(key)
    local oldKey
    for oldKey, _ in pairs(target) do
        target[oldKey] = nil
    end
    for oldKey, _ in pairs(payload or {}) do
        target[oldKey] = payload[oldKey]
    end
end

local function deserializeSafely(raw, fallbackID, sourceKey)
    local ok
    local record
    if type(raw) ~= "table" then
        Core.LogWarn("PNC persistence missing record table key=" .. tostring(sourceKey))
        return nil
    end
    ok, record = pcall(Persistence.DeserializeRecord, raw, fallbackID)
    if not ok or not record or not record.id then
        Core.LogWarn("PNC persistence rejected record key=" .. tostring(sourceKey)
            .. " reason=" .. tostring(ok and "invalid_record" or record))
        return nil
    end
    if fallbackID and tostring(record.id) ~= tostring(fallbackID) then
        Core.LogWarn("PNC persistence id mismatch pointer=" .. tostring(fallbackID)
            .. " record=" .. tostring(record.id) .. " key=" .. tostring(sourceKey))
        return nil
    end
    return record
end

local function putPointer(directory, record, key)
    local id = tostring(record.id)
    directory.records[id] = {
        storageKey = tostring(key or storageKeyForID(id)),
        schemaVersion = Const.PERSISTENCE_VERSION,
        recordRevision = math.max(0, math.floor(tonumber(record.recordRevision) or 0)),
    }
end

Internal.HasEntries = hasEntries
Internal.RecordPersistenceEvent = recordPersistenceEvent
Internal.StorageKeyForID = storageKeyForID
Internal.CaptureSnapshot = captureSnapshot
Internal.NumberChanged = numberChanged
Internal.SnapshotChanged = snapshotChanged
Internal.MarkSnapshotChanges = markSnapshotChanges
Internal.GetDirectory = getDirectory
Internal.AssignModData = assignModData
Internal.DeserializeSafely = deserializeSafely
Internal.PutPointer = putPointer
