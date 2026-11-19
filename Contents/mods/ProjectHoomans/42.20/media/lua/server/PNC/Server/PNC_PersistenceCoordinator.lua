-- One authority-side commit boundary for identity-dependent and domain state.
-- Separates logical commits (Enqueue/Coalesce) from physical persistence flush
-- (bounded Pump + complete drain on OnSave / shutdown / explicit immediate).

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PersistenceCoordinator = PNC.PersistenceCoordinator or {}

local Coordinator = PNC.PersistenceCoordinator
local Core = PNC.Core

Coordinator.PendingDomains = Coordinator.PendingDomains or {}
Coordinator.PendingCommits = tonumber(Coordinator.PendingCommits) or 0
Coordinator.LastPumpAt = tonumber(Coordinator.LastPumpAt) or 0
Coordinator.Metrics = Coordinator.Metrics or {
    logicalCommits = 0,
    dirtyDomainMarks = 0,
    pumpRuns = 0,
    immediateFlushes = 0,
    coalescedCommits = 0,
    domainSavesAttempted = 0,
    domainSavesWritten = 0,
    globalSaveCalls = 0,
}

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function hasEntries(tbl)
    if type(tbl) ~= "table" then return false end
    for _ in pairs(tbl) do
        return true
    end
    return false
end

local function nowMs()
    return Core and Core.Now and Core.Now() or 0
end

local function isSurvivorWorldDirty()
    local extensions = PNC.SurvivorWorldExtensions
    if extensions and extensions.Dirty == true then return true end
    if PNC.Factions and PNC.Factions.Dirty == true then return true end
    if PNC.Communities and PNC.Communities.Dirty == true then return true end
    if PNC.HoomansWorldView and PNC.HoomansWorldView.Dirty == true then return true end
    return Coordinator.PendingDomains.survivorWorld == true
        or Coordinator.PendingDomains.factions == true
        or Coordinator.PendingDomains.communities == true
        or Coordinator.PendingDomains.abstractWorld == true
end

local function getRegistryDirtyFlag()
    local reg = PNC.Registry
    if not reg then return false end
    return hasEntries(reg.DirtyByID)
        or reg.DirectoryDirty == true
        or reg.CoreStoreDirty == true
end

-- Ordered domain descriptors: "work" must precede "colonyStorage" so work
-- construction input checkpoints commit into storage in one coordinated transaction.
local DOMAINS = {
    {
        name = "identity",
        getService = function() return PNC.PlayerCharacters end,
    },
    {
        name = "knowledge",
        getService = function() return PNC.NPCKnowledge end,
    },
    {
        name = "survivorWorld",
        isDirty = isSurvivorWorldDirty,
        snapshotDirty = function()
            return {
                survivorWorld = isSurvivorWorldDirty(),
                factions = PNC.Factions and PNC.Factions.Dirty == true,
                communities = PNC.Communities and PNC.Communities.Dirty == true,
                abstractWorld = PNC.HoomansWorldView and PNC.HoomansWorldView.Dirty == true,
            }
        end,
        restoreDirty = function(snap)
            if type(snap) ~= "table" then return end
            if PNC.SurvivorWorldExtensions and snap.survivorWorld then
                PNC.SurvivorWorldExtensions.Dirty = true
            end
            if PNC.Factions and snap.factions then
                PNC.Factions.Dirty = true
            end
            if PNC.Communities and snap.communities then
                PNC.Communities.Dirty = true
            end
            if PNC.HoomansWorldView and snap.abstractWorld then
                PNC.HoomansWorldView.Dirty = true
            end
        end,
        save = function(results, saveFn, dirty, reason)
            local extensions = PNC.SurvivorWorldExtensions
            if not extensions or type(extensions.Save) ~= "function" then
                if dirty or reason == "world_save" or reason == "server_shutdown" then
                    return false, "survivor_world_cutover_unavailable"
                end
                return true
            end
            if not dirty then return true end
            local ok, why = saveFn("survivorWorld", extensions)
            if not ok then return false, why end
            -- Preserve diagnostic/result keys without re-running retired generic
            -- persistence authorities. These aliases describe the same Core +
            -- Hoomans-extension commit.
            local result = copy(results.survivorWorld)
            results.factions = copy(result)
            results.communities = copy(result)
            results.abstractWorld = copy(result)
            return true
        end,
    },
    {
        name = "projectALifeRelations",
        getService = function()
            return PNC.Compatibility and PNC.Compatibility.ProjectALifePolicy
        end,
    },
    {
        name = "recipeKnowledge",
        getService = function() return PNC.KnowledgeRepository end,
    },
    {
        name = "research",
        getService = function() return PNC.ResearchRepository end,
    },
    {
        name = "needs",
        getService = function() return PNC.NeedsRepository end,
    },
    {
        name = "work",
        getService = function() return PNC.WorkRepository end,
    },
    {
        name = "fishing",
        getService = function() return PNC.FishingService end,
    },
    {
        name = "lumber",
        getService = function() return PNC.LumberService end,
    },
    {
        name = "medicalCare",
        getService = function() return PNC.MedicalCareRepository end,
    },
    {
        name = "colonyStorage",
        getService = function() return PNC.ColonyStorageRepository end,
    },
    {
        name = "settlements",
        getService = function() return PNC.SettlementRepository end,
    },
    {
        name = "worldDiscovery",
        getService = function() return PNC.WorldDiscovery end,
    },
    {
        name = "conversationHistory",
        getService = function()
            return PNC.Conversation and PNC.Conversation.History
        end,
    },
    {
        name = "interactionLifecycle",
        getService = function()
            return PNC.Conversation
                and PNC.Conversation.InteractionLifecyclePersistence
        end,
    },
    {
        name = "scavengePolicy",
        getService = function() return PNC.ScavengePolicy end,
    },
}

local function validate()
    local characters = PNC.PlayerCharacters
    if not characters or not characters.Registry then
        return false, "identity_registry_unavailable"
    end
    local normalized = PNC.PlayerCharacterTypes.NormalizeRegistry(
        characters.Registry
    )
    if not normalized or type(normalized.byUUID) ~= "table" then
        return false, "identity_registry_invalid"
    end
    for oldUUID, canonicalUUID in pairs(normalized.uuidAliases or {}) do
        if not normalized.byUUID[oldUUID]
            or not normalized.byUUID[canonicalUUID]
        then
            return false, "identity_alias_invalid"
        end
    end
    return true
end

local function isDomainDirty(spec)
    if spec.isDirty then
        return spec.isDirty() == true
    end
    local service = spec.getService and spec.getService() or nil
    if service and service.Dirty == true then
        return true
    end
    return Coordinator.PendingDomains[spec.name] == true
end

local function collectDirtyDomainList()
    local dirtyList = {}
    for i = 1, #DOMAINS do
        local spec = DOMAINS[i]
        if isDomainDirty(spec) then
            dirtyList[#dirtyList + 1] = spec.name
        end
    end
    if getRegistryDirtyFlag() or Coordinator.PendingDomains.npcs == true then
        dirtyList[#dirtyList + 1] = "npcs"
    end
    return dirtyList
end

local function snapshotInitialDirty()
    local snap = {
        domains = {},
        pendingDomains = copy(Coordinator.PendingDomains),
        pendingCommits = Coordinator.PendingCommits,
        npcByID = copy(PNC.Registry and PNC.Registry.DirtyByID or {}),
        npcDomains = copy(PNC.Registry and PNC.Registry.DirtyDomains or {}),
        npcDirectory = PNC.Registry and PNC.Registry.DirectoryDirty == true,
        npcCoreStoreDirty = PNC.Registry and PNC.Registry.CoreStoreDirty == true,
    }
    for i = 1, #DOMAINS do
        local spec = DOMAINS[i]
        if spec.snapshotDirty then
            snap.domains[spec.name] = spec.snapshotDirty()
        elseif spec.getService then
            local service = spec.getService()
            snap.domains[spec.name] = service and service.Dirty == true or false
        end
    end
    return snap
end

local function restoreInitialDirty(snap)
    for i = 1, #DOMAINS do
        local spec = DOMAINS[i]
        if spec.restoreDirty then
            spec.restoreDirty(snap.domains[spec.name])
        elseif spec.getService then
            local service = spec.getService()
            if service and snap.domains[spec.name] then
                service.Dirty = true
            end
        end
    end
    Coordinator.PendingDomains = type(snap.pendingDomains) == "table"
        and snap.pendingDomains or {}
    Coordinator.PendingCommits = tonumber(snap.pendingCommits) or 0
    if PNC.Registry then
        PNC.Registry.DirtyByID = snap.npcByID
        PNC.Registry.DirtyDomains = snap.npcDomains
        PNC.Registry.DirectoryDirty = snap.npcDirectory
        PNC.Registry.CoreStoreDirty = snap.npcCoreStoreDirty == true
    end
end

local function saveOneService(results, name, service)
    if not service or not service.Save then return true end
    Coordinator.Metrics.domainSavesAttempted =
        (tonumber(Coordinator.Metrics.domainSavesAttempted) or 0) + 1
    -- Fault-containment boundary around external/ModData domain writers.
    local ok, result, why = pcall(service.Save, false)
    if not ok then return false, tostring(result) end
    results[name] = { changed = result == true, reason = why }
    if result == true then
        Coordinator.Metrics.domainSavesWritten =
            (tonumber(Coordinator.Metrics.domainSavesWritten) or 0) + 1
    elseif result == false and why ~= "not_dirty" then
        return false, why or (name .. "_save_failed")
    end
    return true
end

local function runDirtyDomainSaves(results, reason, onlyDirty)
    local function saveFn(name, service)
        return saveOneService(results, name, service)
    end
    for i = 1, #DOMAINS do
        local spec = DOMAINS[i]
        local dirty = isDomainDirty(spec)
        if spec.save then
            local ok, why = spec.save(results, saveFn, dirty, reason)
            if not ok then return false, why end
        elseif not onlyDirty or dirty then
            local service = spec.getService and spec.getService() or nil
            if service and service.Dirty == true then
                local ok, why = saveFn(spec.name, service)
                if not ok then return false, why end
            elseif service and Coordinator.PendingDomains[spec.name] == true then
                local ok, why = saveFn(spec.name, service)
                if not ok then return false, why end
            end
        end
    end
    return true
end

function Coordinator.MarkDomainDirty(domainName, _reason)
    if domainName == nil or tostring(domainName) == "" then
        return false
    end
    local key = tostring(domainName)
    Coordinator.PendingDomains[key] = true
    Coordinator.Metrics.dirtyDomainMarks =
        (tonumber(Coordinator.Metrics.dirtyDomainMarks) or 0) + 1
    return true
end

function Coordinator.HasPendingWork()
    if (tonumber(Coordinator.PendingCommits) or 0) > 0 then
        return true
    end
    if hasEntries(Coordinator.PendingDomains) then
        return true
    end
    if getRegistryDirtyFlag() then
        return true
    end
    for i = 1, #DOMAINS do
        if isDomainDirty(DOMAINS[i]) then
            return true
        end
    end
    return false
end

function Coordinator.FlushNow(reason, options)
    options = type(options) == "table" and options or {}
    local valid, validationReason = validate()
    if not valid then return false, validationReason end

    local results = {}
    local initialDirty = snapshotInitialDirty()
    local function failure(why)
        restoreInitialDirty(initialDirty)
        Coordinator.LastFailure = {
            reason = tostring(why or "commit_failed"),
            operation = reason or "unspecified",
            at = nowMs(),
        }
        return false, Coordinator.LastFailure.reason
    end

    Coordinator.Metrics.immediateFlushes =
        (tonumber(Coordinator.Metrics.immediateFlushes) or 0) + 1

    local ok, why = runDirtyDomainSaves(results, reason or "immediate", false)
    if not ok then return failure(why) end

    if PNC.Registry and PNC.Registry.FlushDirty then
        -- Fault-containment boundary for full registry drain at save/shutdown.
        local flushed, flushCount = pcall(PNC.Registry.FlushDirty, {
            mode = "drain",
            now = nowMs(),
            includeSnapshotScan = true,
            flushCoreStore = true,
        })
        if not flushed then return failure(tostring(flushCount)) end
        results.npcs = { changed = (tonumber(flushCount) or 0) > 0 }
    end

    if PNC.Registry
        and PNC.Registry.CoreStoreDirty == true
        and PsychopatzCore
        and PsychopatzCore.Actors
        and PsychopatzCore.Actors.RuntimeStore
        and PsychopatzCore.Actors.RuntimeStore.Registry
        and type(PsychopatzCore.Actors.RuntimeStore.Save) == "function"
    then
        local storeSaved = PsychopatzCore.Actors.RuntimeStore.Save()
        if storeSaved then
            PNC.Registry.CoreStoreDirty = false
        end
    end

    if options.flushGlobal ~= false and GlobalModData and GlobalModData.save then
        local flushed, flushError = pcall(GlobalModData.save)
        if not flushed then return failure(tostring(flushError)) end
        Coordinator.Metrics.globalSaveCalls =
            (tonumber(Coordinator.Metrics.globalSaveCalls) or 0) + 1
    end

    local coalesced = tonumber(Coordinator.PendingCommits) or 0
    if coalesced > 0 then
        Coordinator.Metrics.coalescedCommits =
            (tonumber(Coordinator.Metrics.coalescedCommits) or 0) + coalesced
    end
    Coordinator.PendingDomains = {}
    Coordinator.PendingCommits = 0
    Coordinator.LastCommit = {
        reason = reason or "unspecified",
        at = nowMs(),
        queued = false,
        immediate = true,
        results = copy(results),
    }
    return true, "committed", copy(Coordinator.LastCommit)
end

function Coordinator.Pump(now, options)
    options = type(options) == "table" and options or {}
    now = tonumber(now) or nowMs()

    if PNC.Registry and type(PNC.Registry.PumpPhysicalCheckpoints) == "function" then
        PNC.Registry.PumpPhysicalCheckpoints(now)
    end

    if not Coordinator.HasPendingWork() then
        return false, "clean"
    end

    local intervalMs = math.max(1, tonumber(
        options.intervalMs
            or (PNC.Const and PNC.Const.PERSISTENCE_PUMP_INTERVAL_MS)
            or 2000
    ))
    if options.force ~= true
        and (now - (tonumber(Coordinator.LastPumpAt) or 0)) < intervalMs
    then
        return false, "throttled"
    end

    local valid, validationReason = validate()
    if not valid then
        Coordinator.LastFailure = {
            reason = tostring(validationReason or "validation_failed"),
            operation = "persistence_pump",
            at = now,
        }
        return false, Coordinator.LastFailure.reason
    end

    local results = {}
    local ok, why = runDirtyDomainSaves(results, "persistence_pump", true)
    if not ok then
        Coordinator.LastFailure = {
            reason = tostring(why or "pump_domain_save_failed"),
            operation = "persistence_pump",
            at = now,
        }
        return false, Coordinator.LastFailure.reason
    end

    if PNC.Registry
        and PNC.Registry.FlushDirty
        and (hasEntries(PNC.Registry.DirtyByID)
            or PNC.Registry.DirectoryDirty == true)
    then
        local maxRecords = tonumber(options.maxRecords)
            or (PNC.Const and PNC.Const.PERSISTENCE_PUMP_MAX_RECORDS)
            or 8
        local flushed, flushCount = pcall(PNC.Registry.FlushDirty, {
            mode = "pump",
            now = now,
            maxRecords = maxRecords,
            includeSnapshotScan = false,
            flushCoreStore = false,
        })
        if not flushed then
            Coordinator.LastFailure = {
                reason = tostring(flushCount),
                operation = "persistence_pump",
                at = now,
            }
            return false, Coordinator.LastFailure.reason
        end
        results.npcs = { changed = (tonumber(flushCount) or 0) > 0 }
    end

    Coordinator.LastPumpAt = now
    Coordinator.Metrics.pumpRuns =
        (tonumber(Coordinator.Metrics.pumpRuns) or 0) + 1
    local coalesced = tonumber(Coordinator.PendingCommits) or 0
    if coalesced > 0 then
        Coordinator.Metrics.coalescedCommits =
            (tonumber(Coordinator.Metrics.coalescedCommits) or 0) + coalesced
    end
    Coordinator.PendingCommits = 0

    local remainingPending = {}
    if PNC.Registry
        and (hasEntries(PNC.Registry.DirtyByID)
            or PNC.Registry.DirectoryDirty == true
            or PNC.Registry.CoreStoreDirty == true)
    then
        remainingPending.npcs = true
    end
    Coordinator.PendingDomains = remainingPending

    local summary = {
        at = now,
        pumped = true,
        coalesced = coalesced,
        results = results,
    }
    Coordinator.LastPumpSummary = summary
    return true, "pumped", copy(summary)
end

function Coordinator.Commit(reason, options)
    options = type(options) == "table" and options or {}
    local immediate = reason == "world_save"
        or reason == "server_shutdown"
        or options.immediate == true
        or options.flushGlobal == true
    if immediate then
        Coordinator.Metrics.logicalCommits =
            (tonumber(Coordinator.Metrics.logicalCommits) or 0) + 1
        return Coordinator.FlushNow(reason, options)
    end

    local valid, validationReason = validate()
    if not valid then return false, validationReason end

    Coordinator.Metrics.logicalCommits =
        (tonumber(Coordinator.Metrics.logicalCommits) or 0) + 1

    local dirtyDomains = collectDirtyDomainList()
    for i = 1, #dirtyDomains do
        Coordinator.MarkDomainDirty(dirtyDomains[i], reason)
    end
    Coordinator.PendingCommits = (tonumber(Coordinator.PendingCommits) or 0) + 1
    Coordinator.LastCommit = {
        reason = reason or "unspecified",
        at = nowMs(),
        queued = true,
        immediate = false,
        dirtyDomains = dirtyDomains,
    }
    return true, "queued", copy(Coordinator.LastCommit)
end

local function onSave()
    local retired = 0
    local deferred = 0
    local retireReason = "unavailable"
    local presence = PNC.Presence

    -- GameWindow fires OnSave before cell/PopMan persistence. Remove the
    -- physical PNC carriers first so the durable registry is what survives
    -- restart, not a second native zombie-population copy.
    if presence and presence.RetireLiveBodiesForWorldSave then
        local callOK
        callOK, retired, deferred, retireReason = pcall(
            presence.RetireLiveBodiesForWorldSave,
            "world_save_retire"
        )
        if not callOK then
            retireReason = tostring(retired)
            retired = 0
            deferred = 0
            if Core and Core.LogWarn then
                Core.LogWarn("PNC pre-save body retirement failed reason="
                    .. tostring(retireReason))
            end
        elseif (tonumber(deferred) or 0) > 0
            and Core and Core.LogWarn
        then
            Core.LogWarn("PNC pre-save body retirement deferred="
                .. tostring(deferred)
                .. " retired=" .. tostring(retired)
                .. " reason=" .. tostring(retireReason))
        end
    end

    Coordinator.LastPreSaveRetirement = {
        retired = tonumber(retired) or 0,
        deferred = tonumber(deferred) or 0,
        reason = tostring(retireReason or "unknown"),
        at = nowMs(),
    }

    local ok, reason = Coordinator.Commit("world_save")
    if not ok and Core and Core.LogWarn then
        Core.LogWarn("PNC world-save commit failed reason="
            .. tostring(reason or "unknown"))
    end
end

local function onShutdown()
    if not Coordinator.HasPendingWork() then return end
    local ok, reason = Coordinator.Commit("server_shutdown")
    if not ok and Core and Core.LogWarn then
        Core.LogWarn("PNC shutdown drain failed reason="
            .. tostring(reason or "unknown"))
    end
end

if Events and Events.OnSave and not Coordinator.SaveHookRegistered then
    Events.OnSave.Add(onSave)
    Coordinator.SaveHookRegistered = true
end

if Events and not Coordinator.ShutdownHookRegistered then
    local registered = false
    if Events.OnServerShutdown and Events.OnServerShutdown.Add then
        Events.OnServerShutdown.Add(onShutdown)
        registered = true
    end
    if Events.OnGameEnd and Events.OnGameEnd.Add then
        Events.OnGameEnd.Add(onShutdown)
        registered = true
    end
    if registered then
        Coordinator.ShutdownHookRegistered = true
    end
end

return Coordinator
