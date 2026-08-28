local Registry = PNC.Registry
local Internal = Registry.Internal
local Core = PNC.Core
local Const = PNC.Const
local Persistence = PNC.Persistence

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
    Registry.SavedSnapshots = {}
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
        PNC.SpatialIndex.LastRebuildAt = nil
    end
    if PNC.Network and PNC.Network.ResetServerState then
        PNC.Network.ResetServerState()
    end
    directory = Internal.GetDirectory()
    if PNC.Persistence and PNC.Persistence.Repairs
        and PNC.Persistence.Repairs.Apply
    then
        local _, applied, failures = PNC.Persistence.Repairs.Apply(
            "registry_directory", directory, {
                objectId = Const.MODDATA_KEY,
            })
        if applied > 0 or failures > 0 then
            Registry.DirectoryDirty = true
        end
    end
    if Registry.LoadDeathMarkers then
        Registry.LoadDeathMarkers(directory)
    end
    Internal.MigrateLegacy(directory)
    for id, entry in pairs(directory.records) do
        key = type(entry) == "table" and entry.storageKey or nil
        if key and not Registry.Data[tostring(id)] then
            local raw = ModData.get(tostring(key))
            record = Internal.DeserializeSafely(raw, id, key)
            if record then
                Registry.Data[record.id] = record
                Registry.SavedSnapshots[record.id] = Internal.CaptureSnapshot(record)
                if record.persistenceRepairApplied == true
                    or record.persistenceRepairPending == true
                then
                    Registry.MarkDirty(record, "persistence_repair")
                end
                if tonumber(raw and raw.schemaVersion)
                    ~= tonumber(Const.PERSISTENCE_VERSION)
                then
                    Registry.MarkDirty(record, "schema_migration")
                end
            end
        end
    end
    Internal.RecoverOrphans(directory)
    Registry.Loaded = true
    if Registry.MigrateDeadRecords then
        Registry.MigrateDeadRecords()
    end
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
    Registry.RefreshLivePositions(false)
    Internal.MarkSnapshotChanges()
    directory = Internal.GetDirectory()
    for id, _ in pairs(Registry.DirtyByID) do
        record = Registry.Data[id]
        finished = not record or record.persist == false
        if not finished then
            ok, payload = pcall(Persistence.SerializeRecord, record)
            if ok and payload then
                key = directory.records[id] and directory.records[id].storageKey or Internal.StorageKeyForID(id)
                ok, err = pcall(Internal.AssignModData, key, payload)
                if ok then
                    Internal.PutPointer(directory, record, key)
                    record.persistenceSourceVersion =
                        tonumber(Const.PERSISTENCE_VERSION)
                    Registry.SavedSnapshots[id] = Internal.CaptureSnapshot(record)
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
    Internal.CommitLegacyMigration(directory)
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
