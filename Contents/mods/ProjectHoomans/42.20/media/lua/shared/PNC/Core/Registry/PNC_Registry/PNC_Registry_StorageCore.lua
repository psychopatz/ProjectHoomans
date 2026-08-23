PNC = PNC or {}
PNC.Registry = PNC.Registry or {}

local Registry = PNC.Registry
local Internal = Registry.Internal
local Core = PNC.Core
local Const = PNC.Const
local Persistence = PNC.Persistence

Registry.Data = Registry.Data or {}
Registry.LiveByID = Registry.LiveByID or {}
Registry.DirtyByID = Registry.DirtyByID or {}
Registry.DirtyDomains = Registry.DirtyDomains or {}
Registry.SavedSnapshots = Registry.SavedSnapshots or {}
Registry.Loaded = Registry.Loaded or false
Registry.DirectoryDirty = Registry.DirectoryDirty or false
Registry.LastFlushCount = Registry.LastFlushCount or 0

local function storageKeyForID(id)
    return tostring(Const.MODDATA_NPC_PREFIX or "PNC_NPC_") .. tostring(id)
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

Registry.StorageKeyForID = storageKeyForID

local function getDirectory()
    local directory = ModData.getOrCreate(Const.MODDATA_KEY)
    directory.layoutVersion = tonumber(directory.layoutVersion) or 0
    directory.schemaVersion = tonumber(directory.schemaVersion or directory.Version) or 0
    directory.directoryRevision = math.max(0, math.floor(tonumber(directory.directoryRevision) or 0))
    directory.records = type(directory.records) == "table" and directory.records or {}
    directory.deathMarkers = type(directory.deathMarkers) == "table"
        and directory.deathMarkers or {}
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

Internal.StorageKeyForID = storageKeyForID
Internal.CaptureSnapshot = captureSnapshot
Internal.NumberChanged = numberChanged
Internal.SnapshotChanged = snapshotChanged
Internal.MarkSnapshotChanges = markSnapshotChanges
Internal.GetDirectory = getDirectory
Internal.AssignModData = assignModData
Internal.DeserializeSafely = deserializeSafely
Internal.PutPointer = putPointer
