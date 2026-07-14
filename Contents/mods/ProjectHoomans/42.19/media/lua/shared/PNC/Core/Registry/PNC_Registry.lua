PNC = PNC or {}
PNC.Registry = PNC.Registry or {}

local Registry = PNC.Registry
local Core = PNC.Core
local Const = PNC.Const
local Persistence = PNC.Persistence

Registry.Data = Registry.Data or {}
Registry.LiveByID = Registry.LiveByID or {}
Registry.DirtyByID = Registry.DirtyByID or {}
Registry.DirtyDomains = Registry.DirtyDomains or {}
Registry.Loaded = Registry.Loaded or false
Registry.DirectoryDirty = Registry.DirectoryDirty or false
Registry.LastFlushCount = Registry.LastFlushCount or 0

local function storageKeyForID(id)
    return tostring(Const.MODDATA_NPC_PREFIX or "PNC_NPC_") .. tostring(id)
end

Registry.StorageKeyForID = storageKeyForID

local function getDirectory()
    local directory = ModData.getOrCreate(Const.MODDATA_KEY)
    directory.layoutVersion = tonumber(directory.layoutVersion) or 0
    directory.schemaVersion = tonumber(directory.schemaVersion or directory.Version) or 0
    directory.directoryRevision = math.max(0, math.floor(tonumber(directory.directoryRevision) or 0))
    directory.records = type(directory.records) == "table" and directory.records or {}
    return directory
end

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

local function migrateLegacy(directory)
    local legacy = type(directory.NPCs) == "table" and directory.NPCs or nil
    local expected = 0
    local migrated = 0
    local id
    local raw
    local record
    if not legacy then
        return false
    end
    for id, raw in pairs(legacy) do
        expected = expected + 1
        record = deserializeSafely(raw, id, Const.MODDATA_KEY .. ".NPCs")
        if record then
            if PNC.Inventory and PNC.Inventory.EnsureRecordInventory then
                PNC.Inventory.EnsureRecordInventory(record)
            end
            Registry.Data[record.id] = record
            Registry.DirtyByID[record.id] = true
            Registry.DirtyDomains[record.id] = { migration = true }
            putPointer(directory, record, storageKeyForID(record.id))
            migrated = migrated + 1
        end
    end
    directory.migration = {
        fromSchemaVersion = tonumber(directory.Version) or 4,
        migratedCount = migrated,
        expectedCount = expected,
        status = migrated == expected and "pending_commit" or "partial",
    }
    directory.schemaVersion = Const.PERSISTENCE_VERSION
    Registry.DirectoryDirty = true
    Core.LogInfo("PNC prepared legacy registry migration records=" .. tostring(migrated)
        .. "/" .. tostring(expected) .. " status=" .. tostring(directory.migration.status))
    return true
end

local function commitLegacyMigration(directory)
    local legacy = type(directory.NPCs) == "table" and directory.NPCs or nil
    local expected = 0
    local id
    local entry
    local raw
    if not legacy then
        return false
    end
    for id, _ in pairs(legacy) do
        expected = expected + 1
        entry = directory.records[tostring(id)]
        if type(entry) ~= "table" or not entry.storageKey then
            return false
        end
        raw = ModData.get(tostring(entry.storageKey))
        if type(raw) ~= "table"
            or tostring(raw.id or "") ~= tostring(id)
            or tonumber(raw.schemaVersion) ~= Const.PERSISTENCE_VERSION
        then
            return false
        end
    end
    directory.NPCs = nil
    directory.Version = nil
    directory.layoutVersion = Const.STORAGE_LAYOUT_VERSION
    directory.schemaVersion = Const.PERSISTENCE_VERSION
    directory.migration = directory.migration or {}
    directory.migration.expectedCount = expected
    directory.migration.migratedCount = expected
    directory.migration.status = "complete"
    Registry.DirectoryDirty = true
    Core.LogInfo("PNC committed legacy registry migration records=" .. tostring(expected))
    return true
end

local function forEachTableName(callback)
    local names = ModData.getTableNames and ModData.getTableNames() or nil
    local i
    if not names or type(callback) ~= "function" then
        return
    end
    if names.size and names.get then
        for i = 0, names:size() - 1 do
            callback(tostring(names:get(i)))
        end
        return
    end
    for _, i in pairs(names) do
        callback(tostring(i))
    end
end

local function recoverOrphans(directory)
    local referenced = {}
    local id
    local entry
    local recovered = 0
    for id, entry in pairs(directory.records) do
        if type(entry) == "table" and entry.storageKey then
            referenced[tostring(entry.storageKey)] = true
        end
    end
    forEachTableName(function(key)
        if string.sub(key, 1, #(Const.MODDATA_NPC_PREFIX or "PNC_NPC_")) == (Const.MODDATA_NPC_PREFIX or "PNC_NPC_")
            and not referenced[key]
        then
            local record = deserializeSafely(ModData.get(key), nil, key)
            if record and not Registry.Data[record.id] and not directory.records[record.id] then
                Registry.Data[record.id] = record
                putPointer(directory, record, key)
                Registry.DirectoryDirty = true
                recovered = recovered + 1
            end
        end
    end)
    if recovered > 0 then
        directory.directoryRevision = directory.directoryRevision + 1
        Core.LogWarn("PNC recovered orphaned per-NPC tables count=" .. tostring(recovered))
    end
end

function Registry.MarkDirty(recordOrID, domain)
    local id = type(recordOrID) == "table" and recordOrID.id or recordOrID
    local record
    if id == nil then
        return false
    end
    id = tostring(id)
    record = Registry.Data[id] or type(recordOrID) == "table" and recordOrID or nil
    if not record then
        return false
    end
    if not Registry.DirtyByID[id] then
        record.recordRevision = math.max(0, math.floor(tonumber(record.recordRevision) or 0)) + 1
    end
    Registry.DirtyByID[id] = true
    Registry.DirtyDomains[id] = Registry.DirtyDomains[id] or {}
    Registry.DirtyDomains[id][tostring(domain or "record")] = true
    return true
end

function Registry.Load()
    local directory
    local id
    local entry
    local key
    local record
    if not Core.IsAuthority() then
        return
    end
    Registry.Data = {}
    Registry.LiveByID = {}
    Registry.DirtyByID = {}
    Registry.DirtyDomains = {}
    Registry.DirectoryDirty = false
    if PNC.Scheduler then
        PNC.Scheduler.Initialized = false
        PNC.Scheduler.Buckets = {}
        PNC.Scheduler.SlotByID = {}
    end
    if PNC.SpatialIndex then
        PNC.SpatialIndex.NPCInitialized = false
        PNC.SpatialIndex.NPCCells = {}
        PNC.SpatialIndex.NPCMembership = {}
    end
    if PNC.Network and PNC.Network.ResetServerState then
        PNC.Network.ResetServerState()
    end
    directory = getDirectory()
    migrateLegacy(directory)
    for id, entry in pairs(directory.records) do
        key = type(entry) == "table" and entry.storageKey or nil
        if key and not Registry.Data[tostring(id)] then
            record = deserializeSafely(ModData.get(tostring(key)), id, key)
            if record then
                Registry.Data[record.id] = record
            end
        end
    end
    recoverOrphans(directory)
    Registry.Loaded = true
    Core.LogInfo("Registry loaded with " .. tostring(Core.TableSize(Registry.Data)) .. " NPC records.")
end

function Registry.EnsureLoaded()
    if not Registry.Loaded and Core.IsAuthority() then
        Registry.Load()
    end
end

function Registry.FlushDirty()
    local directory
    local id
    local record
    local payload
    local key
    local ok
    local err
    local finished
    local count = 0
    if not Core.IsAuthority() then
        return 0
    end
    Registry.EnsureLoaded()
    Registry.RefreshLivePositions()
    directory = getDirectory()
    for id, _ in pairs(Registry.DirtyByID) do
        record = Registry.Data[id]
        finished = not record or record.persist == false
        if not finished then
            ok, payload = pcall(Persistence.SerializeRecord, record)
            if ok and payload then
                key = directory.records[id] and directory.records[id].storageKey or storageKeyForID(id)
                ok, err = pcall(assignModData, key, payload)
                if ok then
                    putPointer(directory, record, key)
                    count = count + 1
                    finished = true
                else
                    Core.LogWarn("PNC persistence failed writing record id=" .. tostring(id)
                        .. " key=" .. tostring(key) .. " reason=" .. tostring(err))
                end
            elseif not ok then
                Core.LogWarn("PNC persistence failed serializing record id=" .. tostring(id)
                    .. " reason=" .. tostring(payload))
            else
                Core.LogWarn("PNC persistence produced no payload for record id=" .. tostring(id))
            end
        end
        if finished then
            Registry.DirtyByID[id] = nil
            Registry.DirtyDomains[id] = nil
        end
    end
    if count > 0 then
        Registry.DirectoryDirty = true
    end
    commitLegacyMigration(directory)
    if Registry.DirectoryDirty then
        if type(directory.NPCs) ~= "table" then
            directory.layoutVersion = Const.STORAGE_LAYOUT_VERSION
        end
        directory.schemaVersion = Const.PERSISTENCE_VERSION
        directory.directoryRevision = math.max(0, math.floor(tonumber(directory.directoryRevision) or 0)) + 1
        Registry.DirectoryDirty = false
    end
    Registry.LastFlushCount = count
    return count
end

function Registry.Save()
    Registry.FlushDirty()
    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

function Registry.ForEach(callback)
    local id
    local record
    Registry.EnsureLoaded()
    if type(callback) ~= "function" then
        return
    end
    for id, record in pairs(Registry.Data) do
        callback(record, id)
    end
end

function Registry.ForEachLive(callback)
    local id
    local zombie
    local record
    if type(callback) ~= "function" then
        return
    end
    for id, zombie in pairs(Registry.LiveByID) do
        record = Registry.Data[id]
        if record and zombie then
            callback(record, zombie, id)
        end
    end
end

function Registry.AddRecord(record)
    local directory
    if not record or not record.id then
        return false
    end
    Registry.EnsureLoaded()
    record.id = tostring(record.id)
    Registry.Data[record.id] = record
    if record.persist ~= false then
        directory = getDirectory()
        putPointer(directory, record, storageKeyForID(record.id))
        Registry.DirectoryDirty = true
        Registry.MarkDirty(record, "created")
    end
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(record, Core.Now() + (PNC.Scheduler.SLOT_MS or 100))
    end
    if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
        PNC.SpatialIndex.UpdateNPC(record)
    end
    return true
end

function Registry.RemoveRecord(id)
    local directory
    local entry
    Registry.EnsureLoaded()
    id = tostring(id)
    directory = getDirectory()
    entry = directory.records[id]
    Registry.LiveByID[id] = nil
    Registry.Data[id] = nil
    Registry.DirtyByID[id] = nil
    Registry.DirtyDomains[id] = nil
    directory.records[id] = nil
    if ModData.remove then
        ModData.remove(entry and entry.storageKey or storageKeyForID(id))
    end
    if PNC.Scheduler and PNC.Scheduler.Remove then
        PNC.Scheduler.Remove(id)
    end
    if PNC.SpatialIndex and PNC.SpatialIndex.RemoveNPC then
        PNC.SpatialIndex.RemoveNPC(id)
    end
    Registry.DirectoryDirty = true
end

function Registry.Get(id)
    Registry.EnsureLoaded()
    return id ~= nil and Registry.Data[tostring(id)] or nil
end

function Registry.GetLiveZombie(id)
    return id ~= nil and Registry.LiveByID[tostring(id)] or nil
end

function Registry.RegisterLiveZombie(record, zombie)
    if not record or not zombie then
        return
    end
    if not PNC.BodyLifecycle or not PNC.BodyLifecycle.StampLiveBody then
        Core.LogWarn("Cannot register NPC body without PNC.BodyLifecycle id=" .. tostring(record.id))
        return
    end
    Registry.LiveByID[record.id] = zombie
    PNC.BodyLifecycle.StampLiveBody(record, zombie)
    record.liveBodyInstanceID = zombie.getPersistentOutfitID and zombie:getPersistentOutfitID() or nil
    record.liveBodyOnlineID = zombie.getOnlineID and tonumber(zombie:getOnlineID()) or nil
    if record.liveBodyOnlineID and record.liveBodyOnlineID < 0 then
        record.liveBodyOnlineID = nil
    end
    record.presenceRevision = (tonumber(record.presenceRevision) or 0) + 1
end

function Registry.UnregisterLiveZombie(id)
    local record = Registry.Get(id)
    Registry.LiveByID[id] = nil
    if record then
        if record.runtime then
            record.runtime.bodyLease = nil
        end
        record.liveBodyInstanceID = nil
        record.liveBodyOnlineID = nil
        record.presenceRevision = (tonumber(record.presenceRevision) or 0) + 1
    end
end

function Registry.FindRecordByZombie(zombie)
    local modData
    local uuid
    if not zombie then
        return nil
    end
    modData = zombie:getModData()
    uuid = modData and modData.PNC_UUID or nil
    return uuid and Registry.Get(uuid) or nil
end

function Registry.RefreshLivePositions()
    local id
    local zombie
    local record
    local x
    local y
    local z
    for id, zombie in pairs(Registry.LiveByID) do
        record = Registry.Data[id]
        if record and zombie then
            if zombie.isDead and zombie:isDead() then
                Registry.LiveByID[id] = nil
            else
                x = zombie:getX()
                y = zombie:getY()
                z = zombie:getZ()
                if record.x ~= x or record.y ~= y or record.z ~= z then
                    record.x = x
                    record.y = y
                    record.z = z
                    Registry.MarkDirty(record, "position")
                    if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
                        PNC.SpatialIndex.UpdateNPC(record)
                    end
                end
                if zombie.getOnlineID then
                    local onlineID = tonumber(zombie:getOnlineID())
                    if onlineID and onlineID >= 0 and record.liveBodyOnlineID ~= onlineID then
                        record.liveBodyOnlineID = onlineID
                        if isServer and isServer() then
                            record.runtime = record.runtime or {}
                            record.runtime.forceSyncEvent = "body_online_id"
                        end
                    end
                end
            end
        end
    end
end

local function onInitGlobalModData()
    Registry.Load()
end

local function onSave()
    Registry.Save()
end

Events.OnInitGlobalModData.Add(onInitGlobalModData)
Events.OnSave.Add(onSave)
