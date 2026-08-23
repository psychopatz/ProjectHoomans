local Registry = PNC.Registry
local Internal = Registry.Internal
local Core = PNC.Core
local Const = PNC.Const

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
        record = Internal.DeserializeSafely(raw, id, Const.MODDATA_KEY .. ".NPCs")
        if record then
            if PNC.Inventory and PNC.Inventory.EnsureRecordInventory then
                PNC.Inventory.EnsureRecordInventory(record)
            end
            Registry.Data[record.id] = record
            Registry.SavedSnapshots[record.id] = Internal.CaptureSnapshot(record)
            Registry.DirtyByID[record.id] = true
            Registry.DirtyDomains[record.id] = { migration = true }
            Internal.PutPointer(directory, record, Internal.StorageKeyForID(record.id))
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
            local raw = ModData.get(key)
            local record = Internal.DeserializeSafely(raw, nil, key)
            if record and not Registry.Data[record.id] and not directory.records[record.id] then
                Registry.Data[record.id] = record
                Registry.SavedSnapshots[record.id] = Internal.CaptureSnapshot(record)
                Internal.PutPointer(directory, record, key)
                Registry.DirectoryDirty = true
                if tonumber(raw and raw.schemaVersion)
                    ~= tonumber(Const.PERSISTENCE_VERSION)
                then
                    Registry.MarkDirty(record, "schema_migration")
                end
                recovered = recovered + 1
            end
        end
    end)
    if recovered > 0 then
        directory.directoryRevision = directory.directoryRevision + 1
        Core.LogWarn("PNC recovered orphaned per-NPC tables count=" .. tostring(recovered))
    end
end

Internal.MigrateLegacy = migrateLegacy
Internal.CommitLegacyMigration = commitLegacyMigration
Internal.ForEachTableName = forEachTableName
Internal.RecoverOrphans = recoverOrphans
