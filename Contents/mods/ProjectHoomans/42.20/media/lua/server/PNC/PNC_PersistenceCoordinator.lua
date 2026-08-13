-- One authority-side commit boundary for identity-dependent state.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PersistenceCoordinator = PNC.PersistenceCoordinator or {}

local Coordinator = PNC.PersistenceCoordinator
local Core = PNC.Core

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

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

function Coordinator.Commit(reason)
    local valid, validationReason = validate()
    if not valid then return false, validationReason end

    local results = {}
    local initialDirty = {
        identity = PNC.PlayerCharacters and PNC.PlayerCharacters.Dirty == true,
        knowledge = PNC.NPCKnowledge and PNC.NPCKnowledge.Dirty == true,
        factions = PNC.Factions and PNC.Factions.Dirty == true,
        communities = PNC.Communities and PNC.Communities.Dirty == true,
        colonyStorage = PNC.ColonyStorageRepository
            and PNC.ColonyStorageRepository.Dirty == true,
        settlements = PNC.SettlementRepository
            and PNC.SettlementRepository.Dirty == true,
        abstractWorld = PNC.AbstractWorldStore
            and PNC.AbstractWorldStore.Dirty == true,
        worldDiscovery = PNC.WorldDiscovery
            and PNC.WorldDiscovery.Dirty == true,
        conversationHistory = PNC.Conversation
            and PNC.Conversation.History
            and PNC.Conversation.History.Dirty == true,
        npcByID = copy(PNC.Registry and PNC.Registry.DirtyByID or {}),
        npcDomains = copy(PNC.Registry and PNC.Registry.DirtyDomains or {}),
        npcDirectory = PNC.Registry and PNC.Registry.DirectoryDirty == true,
    }
    local function failure(why)
        if PNC.PlayerCharacters and initialDirty.identity then
            PNC.PlayerCharacters.Dirty = true
        end
        if PNC.NPCKnowledge and initialDirty.knowledge then
            PNC.NPCKnowledge.Dirty = true
        end
        if PNC.Factions and initialDirty.factions then PNC.Factions.Dirty = true end
        if PNC.Communities and initialDirty.communities then
            PNC.Communities.Dirty = true
        end
        if PNC.ColonyStorageRepository and initialDirty.colonyStorage then
            PNC.ColonyStorageRepository.Dirty = true
        end
        if PNC.SettlementRepository and initialDirty.settlements then
            PNC.SettlementRepository.Dirty = true
        end
        if PNC.AbstractWorldStore and initialDirty.abstractWorld then
            PNC.AbstractWorldStore.Dirty = true
        end
        if PNC.WorldDiscovery and initialDirty.worldDiscovery then
            PNC.WorldDiscovery.Dirty = true
        end
        if PNC.Conversation and PNC.Conversation.History
            and initialDirty.conversationHistory
        then
            PNC.Conversation.History.Dirty = true
        end
        if PNC.Registry then
            PNC.Registry.DirtyByID = initialDirty.npcByID
            PNC.Registry.DirtyDomains = initialDirty.npcDomains
            PNC.Registry.DirectoryDirty = initialDirty.npcDirectory
        end
        Coordinator.LastFailure = {
            reason = tostring(why or "commit_failed"),
            operation = reason or "unspecified",
            at = Core and Core.Now and Core.Now() or 0,
        }
        return false, Coordinator.LastFailure.reason
    end
    local function save(name, service)
        if not service or not service.Save then return true end
        local ok, result, why = pcall(service.Save, false)
        if not ok then return false, tostring(result) end
        results[name] = { changed = result == true, reason = why }
        if result == false and why ~= "not_dirty" then
            return false, why or (name .. "_save_failed")
        end
        return true
    end

    local ok, why = save("identity", PNC.PlayerCharacters)
    if not ok then return failure(why) end
    ok, why = save("knowledge", PNC.NPCKnowledge)
    if not ok then return failure(why) end
    ok, why = save("factions", PNC.Factions)
    if not ok then return failure(why) end
    ok, why = save("communities", PNC.Communities)
    if not ok then return failure(why) end
    ok, why = save("colonyStorage", PNC.ColonyStorageRepository)
    if not ok then return failure(why) end
    ok, why = save("settlements", PNC.SettlementRepository)
    if not ok then return failure(why) end
    ok, why = save("abstractWorld", PNC.AbstractWorldStore)
    if not ok then return failure(why) end
    ok, why = save("worldDiscovery", PNC.WorldDiscovery)
    if not ok then return failure(why) end
    ok, why = save("conversationHistory",
        PNC.Conversation and PNC.Conversation.History)
    if not ok then return failure(why) end

    if PNC.Registry and PNC.Registry.FlushDirty then
        local flushed, flushError = pcall(PNC.Registry.FlushDirty)
        if not flushed then return failure(tostring(flushError)) end
        results.npcs = { changed = (tonumber(flushError) or 0) > 0 }
    end
    if GlobalModData and GlobalModData.save then
        local flushed, flushError = pcall(GlobalModData.save)
        if not flushed then return failure(tostring(flushError)) end
    end
    Coordinator.LastCommit = {
        reason = reason or "unspecified",
        at = Core and Core.Now and Core.Now() or 0,
        results = copy(results),
    }
    return true, "committed", copy(Coordinator.LastCommit)
end

local function onSave()
    local ok, reason = Coordinator.Commit("world_save")
    if not ok and Core and Core.LogWarn then
        Core.LogWarn("PNC world-save commit failed reason="
            .. tostring(reason or "unknown"))
    end
end

if Events and Events.OnSave and not Coordinator.SaveHookRegistered then
    Events.OnSave.Add(onSave)
    Coordinator.SaveHookRegistered = true
end

return Coordinator
