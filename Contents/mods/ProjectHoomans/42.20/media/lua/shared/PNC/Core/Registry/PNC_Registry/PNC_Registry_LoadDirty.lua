local Registry = PNC.Registry
local Internal = Registry.Internal
local Core = PNC.Core
local Const = PNC.Const
local Persistence = PNC.Persistence or {}
PNC.Persistence = Persistence
local Reset = Persistence.Reset
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"

local function directoryReason(raw)
    return Reset.Check(raw, Const.PERSISTENCE_VERSION, nil,
        function(value)
            return tonumber(value.layoutVersion)
                    == tonumber(Const.STORAGE_LAYOUT_VERSION)
                and type(value.records) == "table"
                and type(value.deathMarkers) == "table"
        end)
end

local function freshDirectory()
    return {
        layoutVersion = Const.STORAGE_LAYOUT_VERSION,
        schemaVersion = Const.PERSISTENCE_VERSION,
        directoryRevision = 0,
        records = {},
        deathMarkers = {},
        repairVersions = {},
    }
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
    local rawDirectory = Reset.Read(Const.MODDATA_KEY)
    local directoryResetReason = directoryReason(rawDirectory)
    if directoryResetReason ~= nil
        and directoryResetReason ~= "empty_state"
    then
        local written = Reset.Write(Const.MODDATA_KEY, freshDirectory())
        if not written then
            Core.LogWarn("PNC persistence could not reset registry directory")
            return
        end
        Internal.ClearPersistedNPCNamespace()
        Registry.LastReset = Reset.Info(rawDirectory,
            Const.PERSISTENCE_VERSION, directoryResetReason,
            "npc_registry")
        Registry.DirectoryDirty = true
        Core.LogWarn("PNC persistence reset npc_registry reason="
            .. tostring(directoryResetReason))
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
    for id, entry in pairs(directory.records) do
        key = type(entry) == "table" and entry.storageKey or nil
        if not key then
            directory.records[tostring(id)] = nil
            Registry.DirectoryDirty = true
        elseif not Registry.Data[tostring(id)] then
            local raw = ModData.get(tostring(key))
            local recordReason = Reset.Check(raw, Const.PERSISTENCE_VERSION,
                nil, function(value)
                    return tostring(value.id or "") == tostring(id)
                end)
            record = recordReason == nil
                and Internal.DeserializeSafely(raw, id, key) or nil
            if record then
                Registry.Data[record.id] = record
                Registry.SavedSnapshots[record.id] = Internal.CaptureSnapshot(record)
                if record.persistenceRepairApplied == true
                    or record.persistenceRepairPending == true
                then
                    Registry.MarkDirty(record, "persistence_repair")
                end
            elseif recordReason ~= nil then
                directory.records[tostring(id)] = nil
                Registry.DirectoryDirty = true
                if ModData.remove then ModData.remove(tostring(key)) end
            end
        end
    end
    Internal.ClearUnreferencedPersistedNPCRecords(directory)
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
    if Registry.DirectoryDirty then
        directory.layoutVersion = Const.STORAGE_LAYOUT_VERSION
        directory.schemaVersion = Const.PERSISTENCE_VERSION
        directory.directoryRevision = math.max(0, math.floor(tonumber(directory.directoryRevision) or 0)) + 1
        local written, writeReason = Reset.Write(Const.MODDATA_KEY, {
            layoutVersion = directory.layoutVersion,
            schemaVersion = directory.schemaVersion,
            directoryRevision = directory.directoryRevision,
            records = directory.records,
            deathMarkers = directory.deathMarkers,
            repairVersions = directory.repairVersions,
        })
        if written then
            Registry.DirectoryDirty = false
        else
            Registry.DirectoryDirty = true
            Core.LogWarn("PNC registry directory write failed reason=" .. tostring(writeReason))
        end
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
