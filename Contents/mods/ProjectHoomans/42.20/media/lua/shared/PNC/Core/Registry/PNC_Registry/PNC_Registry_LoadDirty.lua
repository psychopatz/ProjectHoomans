local Registry = PNC.Registry
local Internal = Registry.Internal
local Core = PNC.Core
local Const = PNC.Const
local Persistence = PNC.Persistence or {}
PNC.Persistence = Persistence
local Reset = Persistence.Reset
    or require "PNC/Core/Persistence/PNC_ModDataStore"

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
    record = Registry.Data[id]
        or Registry.RuntimeViews and Registry.RuntimeViews[id]
        or type(recordOrID) == "table" and recordOrID or nil
    if not record then
        return false
    end
    -- Runtime Core-actor views are intentionally non-persistent. Services may
    -- mutate their projected social/context state, but durable changes are
    -- synchronized back to Core by the owning adapters rather than written as
    -- a second Hoomans NPC record.
    if record.persist == false
        and record.runtimeView == true
        and not Registry.Data[id]
    then
        return true
    end
    if record.persist == false then
        if record.runtimeView == true or not Registry.DirtyByID[id] then
            return true
        end
    end
    -- Native visual capture persists through this specific dirty domain.
    if domain == "equipment_visuals" and PNC.Network
        and PNC.Network.RefreshPortraitEquipment
    then
        PNC.Network.RefreshPortraitEquipment(record)
    end
    if not Registry.DirtyByID[id] then
        record.recordRevision = math.max(0, math.floor(tonumber(record.recordRevision) or 0)) + 1
    end
    if Registry.RetryState then
        Registry.RetryState[id] = nil
    end
    Registry.DirtyByID[id] = true
    Registry.DirtyDomains[id] = Registry.DirtyDomains[id] or {}
    Registry.DirtyDomains[id][tostring(domain or "record")] = true
    if PNC.PersistenceCoordinator
        and type(PNC.PersistenceCoordinator.MarkDomainDirty) == "function"
    then
        PNC.PersistenceCoordinator.MarkDomainDirty("npcs", domain)
    end
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
    Registry.RuntimeViews = {}
    Registry.LiveByID = {}
    Registry.DirtyByID = {}
    Registry.DirtyDomains = {}
    Registry.SavedSnapshots = {}
    Registry.RetryState = {}
    Registry.DirectoryDirty = false
    Registry.CoreStoreDirty = false
    Registry.LastCheckpointAt = 0
    Registry._checkpointCursor = 0
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

local function remainingDirtyCount()
    local total = 0
    for _ in pairs(Registry.DirtyByID or {}) do
        total = total + 1
    end
    return total
end

function Registry.FlushDirty(options)
    local directory
    local count = 0
    local legacyWriteCount = 0
    local coreSyncedCount = 0
    local writtenCount = 0
    local terminalCount = 0
    local retryableCount = 0
    local deferredCount = 0
    local coreProvider = PNC.Persistence and PNC.Persistence.CoreProvider or nil
    local outcomeWritten = Persistence.OUTCOME_WRITTEN or "WRITTEN"
    local outcomeTerminal =
        Persistence.OUTCOME_TERMINAL or "TERMINAL_OR_NOT_APPLICABLE"
    local outcomeRetryable =
        Persistence.OUTCOME_RETRYABLE or "RETRYABLE_FAILURE"

    if not Core.IsAuthority() then
        return 0
    end
    options = type(options) == "table" and options or {}
    local isPump = options.mode == "pump"
    local now = tonumber(options.now)
        or (Core and Core.Now and Core.Now())
        or 0
    local maxRecords = isPump and math.max(1, math.floor(tonumber(
        options.maxRecords or (Const and Const.PERSISTENCE_PUMP_MAX_RECORDS) or 8
    ))) or nil
    local includeSnapshotScan = options.includeSnapshotScan ~= nil
        and (options.includeSnapshotScan == true)
        or (not isPump)
    local flushCoreStore = options.flushCoreStore ~= nil
        and (options.flushCoreStore == true)
        or (not isPump)
    local ignoreBackoff = not isPump or options.ignoreBackoff == true

    Registry.EnsureLoaded()
    if includeSnapshotScan then
        if type(Registry.RefreshLivePositions) == "function" then
            Registry.RefreshLivePositions(false)
        end
        if type(Internal.MarkSnapshotChanges) == "function" then
            Internal.MarkSnapshotChanges()
        end
    end

    directory = Internal.GetDirectory()
    Registry.RetryState = Registry.RetryState or {}
    local metrics = Registry.PersistenceMetrics

    local function clearDirty(id)
        Registry.DirtyByID[id] = nil
        Registry.DirtyDomains[id] = nil
        Registry.RetryState[id] = nil
    end

    local function handleTerminal(id, reason)
        clearDirty(id)
        terminalCount = terminalCount + 1
        if metrics then
            metrics.terminal = (tonumber(metrics.terminal) or 0) + 1
        end
        if type(Internal.RecordPersistenceEvent) == "function" then
            Internal.RecordPersistenceEvent("terminalEvents", {
                id = id,
                outcome = outcomeTerminal,
                reason = tostring(reason or "terminal"),
                at = now,
            })
        end
        Core.LogWarn(
            "PNC persistence outcome=" .. tostring(outcomeTerminal)
                .. " id=" .. tostring(id)
                .. " reason=" .. tostring(reason or "terminal")
        )
    end

    local function handleRetryable(id, reason)
        local prev = Registry.RetryState[id]
        local attempts = (prev and tonumber(prev.attempts) or 0) + 1
        local baseMs = math.max(
            1,
            tonumber(Const and Const.PERSISTENCE_RETRY_BASE_MS) or 1000
        )
        local maxMs = math.max(
            baseMs,
            tonumber(Const and Const.PERSISTENCE_RETRY_MAX_MS) or 30000
        )
        local maxAttempts = math.max(
            1,
            math.floor(tonumber(
                Const and Const.PERSISTENCE_RETRY_MAX_ATTEMPTS
            ) or 5)
        )
        local backoffMs = math.min(
            maxMs,
            baseMs * (2 ^ math.min(10, attempts - 1))
        )
        local reasonText = tostring(reason or "retryable_failure")
        retryableCount = retryableCount + 1
        if metrics then
            metrics.retryable = (tonumber(metrics.retryable) or 0) + 1
            metrics.retriesScheduled =
                (tonumber(metrics.retriesScheduled) or 0) + 1
        end
        local exhausted = attempts >= maxAttempts
        Registry.RetryState[id] = {
            attempts = attempts,
            lastReason = reasonText,
            lastAt = now,
            nextRetryAt = now + backoffMs,
            exhausted = exhausted,
        }
        if type(Internal.RecordPersistenceEvent) == "function" then
            Internal.RecordPersistenceEvent("retryEvents", {
                id = id,
                outcome = outcomeRetryable,
                attempts = attempts,
                exhausted = exhausted,
                nextRetryAt = now + backoffMs,
                reason = reasonText,
                at = now,
            })
        end
        if exhausted then
            Registry.DirtyByID[id] = nil
            Registry.DirtyDomains[id] = nil
            if metrics then
                metrics.retriesExhausted =
                    (tonumber(metrics.retriesExhausted) or 0) + 1
            end
            Core.LogWarn(
                "PNC persistence outcome=RETRYABLE_EXHAUSTED id="
                    .. tostring(id)
                    .. " attempts=" .. tostring(attempts)
                    .. " reason=" .. reasonText
            )
        elseif attempts == 1 then
            Core.LogWarn(
                "PNC persistence outcome=" .. tostring(outcomeRetryable)
                    .. " id=" .. tostring(id)
                    .. " attempts=" .. tostring(attempts)
                    .. " nextRetryInMs=" .. tostring(backoffMs)
                    .. " reason=" .. reasonText
            )
        end
    end

    local dirtyIDs = {}
    for id, _ in pairs(Registry.DirtyByID) do
        dirtyIDs[#dirtyIDs + 1] = tostring(id)
    end
    table.sort(dirtyIDs)

    local attempted = 0
    for index = 1, #dirtyIDs do
        if maxRecords and attempted >= maxRecords then
            break
        end
        local id = dirtyIDs[index]
        local retryEntry = Registry.RetryState[id]
        if not ignoreBackoff
            and retryEntry
            and now < (tonumber(retryEntry.nextRetryAt) or 0)
        then
            deferredCount = deferredCount + 1
        else
            attempted = attempted + 1
            local record = Registry.Data[id]
            if not record or record.persist == false or record.runtimeView == true then
                handleTerminal(id, not record and "record_missing" or "non_persistent")
            elseif record.coreBacked == true then
                if coreProvider
                    and type(coreProvider.SyncPromotedCoreActorToCore) == "function"
                then
                    -- Fault-containment boundary around external/serialization sync.
                    local callOK, synced, syncResult, syncOutcome = pcall(
                        coreProvider.SyncPromotedCoreActorToCore,
                        record,
                        PsychopatzCore
                    )
                    if not callOK then
                        handleRetryable(id, tostring(synced))
                    elseif synced == true then
                        Registry.SavedSnapshots[id] =
                            Internal.CaptureSnapshot(record)
                        if directory.records[id] then
                            local legacyKey = directory.records[id].storageKey
                                or Internal.StorageKeyForID(id)
                            directory.records[id] = nil
                            if ModData and ModData.remove then
                                ModData.remove(legacyKey)
                            end
                            Registry.DirectoryDirty = true
                        end
                        if type(syncResult) == "table"
                            and syncResult.committed == true
                        then
                            coreSyncedCount = coreSyncedCount + 1
                            Registry.CoreStoreDirty = true
                        end
                        clearDirty(id)
                        count = count + 1
                        writtenCount = writtenCount + 1
                        if metrics then
                            metrics.written = (tonumber(metrics.written) or 0) + 1
                        end
                    elseif syncOutcome == outcomeTerminal then
                        handleTerminal(
                            id,
                            tostring(syncResult or "core_sync_terminal")
                        )
                    else
                        handleRetryable(
                            id,
                            tostring(syncResult or "core_sync_failed")
                        )
                    end
                else
                    handleRetryable(id, "core_provider_unavailable")
                end
            else
                -- Fault-containment boundary around legacy serializer and ModData write.
                local callOK, payload, serOutcome, serReason = pcall(
                    Persistence.SerializeRecord,
                    record
                )
                if not callOK then
                    handleRetryable(id, tostring(payload))
                elseif payload ~= nil then
                    local key = directory.records[id]
                        and directory.records[id].storageKey
                        or Internal.StorageKeyForID(id)
                    local writeOK, writeErr = pcall(
                        Internal.AssignModData,
                        key,
                        payload
                    )
                    if writeOK then
                        Internal.PutPointer(directory, record, key)
                        record.persistenceSourceVersion =
                            tonumber(Const.PERSISTENCE_VERSION)
                        Registry.SavedSnapshots[id] =
                            Internal.CaptureSnapshot(record)
                        legacyWriteCount = legacyWriteCount + 1
                        clearDirty(id)
                        count = count + 1
                        writtenCount = writtenCount + 1
                        if metrics then
                            metrics.written = (tonumber(metrics.written) or 0) + 1
                        end
                    else
                        handleRetryable(id, tostring(writeErr))
                    end
                elseif serOutcome == outcomeRetryable then
                    handleRetryable(
                        id,
                        tostring(serReason or "serializer_retryable")
                    )
                else
                    handleTerminal(
                        id,
                        tostring(serReason or "serializer_no_payload")
                    )
                end
            end
        end
    end

    if flushCoreStore
        and (coreSyncedCount > 0
            or Registry.CoreStoreDirty == true
            or options.forceCoreStore == true)
        and PsychopatzCore
        and PsychopatzCore.Actors
        and PsychopatzCore.Actors.RuntimeStore
        and PsychopatzCore.Actors.RuntimeStore.Registry
        and type(PsychopatzCore.Actors.RuntimeStore.Save) == "function"
    then
        local storeSaved = PsychopatzCore.Actors.RuntimeStore.Save()
        if storeSaved then
            Registry.CoreStoreDirty = false
        end
    end

    if legacyWriteCount > 0 then
        Registry.DirectoryDirty = true
    end
    if Registry.DirectoryDirty then
        directory.layoutVersion = Const.STORAGE_LAYOUT_VERSION
        directory.schemaVersion = Const.PERSISTENCE_VERSION
        directory.directoryRevision = math.max(
            0,
            math.floor(tonumber(directory.directoryRevision) or 0)
        ) + 1
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
            Core.LogWarn(
                "PNC registry directory write failed reason="
                    .. tostring(writeReason)
            )
        end
    end

    if metrics then
        metrics.flushCalls = (tonumber(metrics.flushCalls) or 0) + 1
    end
    Registry.LastFlushCount = count
    Registry.LastCoreSyncCount = coreSyncedCount
    Registry.LastFlushSummary = {
        mode = isPump and "pump" or "drain",
        flushed = count,
        written = writtenCount,
        terminal = terminalCount,
        retryable = retryableCount,
        deferred = deferredCount,
        legacyWrites = legacyWriteCount,
        coreSynced = coreSyncedCount,
        remainingDirty = remainingDirtyCount(),
        outcomeWritten = outcomeWritten,
    }
    return count, Registry.LastFlushSummary
end

function Registry.Save()
    Registry.FlushDirty({
        mode = "drain",
        includeSnapshotScan = true,
        flushCoreStore = true,
    })
    local coreProvider = PNC.Persistence and PNC.Persistence.CoreProvider or nil
    if coreProvider
        and type(coreProvider.SyncAllPromotedCoreActors) == "function"
    then
        local extraSynced = tonumber(
            coreProvider.SyncAllPromotedCoreActors(PsychopatzCore)
        ) or 0
        if extraSynced > 0 then
            Registry.CoreStoreDirty = true
        end
    end
    if Registry.CoreStoreDirty == true
        and PsychopatzCore
        and PsychopatzCore.Actors
        and PsychopatzCore.Actors.RuntimeStore
        and PsychopatzCore.Actors.RuntimeStore.Registry
        and type(PsychopatzCore.Actors.RuntimeStore.Save) == "function"
    then
        local storeSaved = PsychopatzCore.Actors.RuntimeStore.Save()
        if storeSaved then
            Registry.CoreStoreDirty = false
        end
    end
    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end
