local Registry = PNC.Registry
local Internal = Registry.Internal
local Core = PNC.Core

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
        directory = Internal.GetDirectory()
        Internal.PutPointer(directory, record, Internal.StorageKeyForID(record.id))
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
    if PNC.NeedsRepository and PNC.NeedsRepository.Remove then
        PNC.NeedsRepository.Remove(id)
    end
    directory = Internal.GetDirectory()
    entry = directory.records[id]
    Registry.LiveByID[id] = nil
    Registry.Data[id] = nil
    Registry.DirtyByID[id] = nil
    Registry.DirtyDomains[id] = nil
    Registry.SavedSnapshots[id] = nil
    directory.records[id] = nil
    if ModData.remove then
        ModData.remove(entry and entry.storageKey or Internal.StorageKeyForID(id))
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
    local previousZombie
    local previousInstanceID
    local previousPopulationID
    if not record or not zombie then
        return
    end
    if not PNC.BodyLifecycle or not PNC.BodyLifecycle.StampLiveBody then
        Core.LogWarn("Cannot register NPC body without PNC.BodyLifecycle id=" .. tostring(record.id))
        return
    end
    previousZombie = Registry.LiveByID[record.id]
    previousInstanceID = record.liveBodyInstanceID
    previousPopulationID = record.liveBodyPopulationID
    Registry.LiveByID[record.id] = zombie
    PNC.BodyLifecycle.StampLiveBody(record, zombie)
    -- StampLiveBody captures the identity after validating the engine result.
    -- During restore the raw getter may still return nil/0; never overwrite a
    -- valid stamped hint with that transient value or the later husk loss
    -- cannot be correlated safely.
    if PNC.BodyLifecycle.RefreshLiveBodyIdentity then
        PNC.BodyLifecycle.RefreshLiveBodyIdentity(
            record,
            zombie,
            "registry_register"
        )
    end
    if previousZombie == zombie then
        -- StampLiveBody deliberately clears the current hint before recapture.
        -- If this is an audit/rebind of the same attached object and the Java
        -- getter is still in its transient zero window, retain the last valid
        -- identity instead of replacing it with nil.
        if record.liveBodyInstanceID == nil
            and previousInstanceID ~= nil
        then
            record.liveBodyInstanceID = previousInstanceID
        end
        if record.liveBodyPopulationID == nil
            and previousPopulationID ~= nil
        then
            record.liveBodyPopulationID = previousPopulationID
        end
    end
    record.liveBodyOnlineID = zombie.getOnlineID and tonumber(zombie:getOnlineID()) or nil
    if record.liveBodyOnlineID and record.liveBodyOnlineID < 0 then
        record.liveBodyOnlineID = nil
    end
    record.presenceRevision = (tonumber(record.presenceRevision) or 0) + 1
    Registry.MarkDirty(record, "live_body_hint")
end

function Registry.UnregisterLiveZombie(id)
    local record = Registry.Get(id)
    Registry.LiveByID[id] = nil
    if record then
        if record.runtime then
            record.runtime.bodyLease = nil
        end
        record.liveBodyInstanceID = nil
        record.liveBodyPopulationID = nil
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
