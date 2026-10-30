-- Server-authoritative sparse semantic interaction lifecycle persistence.
--
-- The shared lifecycle owns meaning, bounds and compaction.  This spoke owns
-- only the server store and its ModData boundary; clients and the worker do
-- not write this state.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Lifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle
    or require "PNC/Semantics/PNC_SemanticInteractionLifecycle"
local Reset = PNC.ModDataStore
    or require "PNC/Core/Persistence/PNC_ModDataStore"

local Persistence = PNC.Conversation.InteractionLifecyclePersistence
    or {}
PNC.Conversation.InteractionLifecyclePersistence = Persistence

Persistence.MODDATA_KEY = "PNC_InteractionLifecycle_V1"
Persistence.VERSION = Lifecycle.VERSION
Persistence.Store = Persistence.Store
    or Lifecycle.New({ authoritative = true })
Persistence.Loaded = Persistence.Loaded == true
Persistence.Dirty = Persistence.Dirty == true

local function copy(value)
    if PNC.Core and type(PNC.Core.DeepCopy) == "function" then
        return PNC.Core.DeepCopy(value)
    end
    return value
end

local function validSnapshot(value)
    return type(value) == "table"
        and value.schema == Lifecycle.SCHEMA
        and type(value.pairs) == "table"
        and type(value.sharedEvents) == "table"
end

function Persistence.Load(force)
    if Persistence.Loaded and force ~= true then
        return Persistence.Store
    end
    local raw = Reset.Read(Persistence.MODDATA_KEY)
    local reason = Reset.Check(raw, Persistence.VERSION, "schemaVersion",
        validSnapshot)
    Persistence.Store = Lifecycle.New({ authoritative = true })
    if reason == nil then
        local imported, importReason = Lifecycle.Import(
            Persistence.Store, raw
        )
        if imported ~= true then reason = importReason or "invalid_state" end
    end
    Persistence.Loaded = true
    Persistence.Dirty = reason ~= nil and reason ~= "empty_state"
    if reason ~= nil and reason ~= "empty_state" then
        Reset.Mark(
            Persistence,
            raw,
            Persistence.VERSION,
            reason,
            "interaction_lifecycle",
            "schemaVersion"
        )
    end
    return Persistence.Store
end

function Persistence.EnsureLoaded()
    if not Persistence.Loaded then Persistence.Load() end
    return Persistence.Store
end

function Persistence.MarkDirty()
    Persistence.Dirty = true
end

function Persistence.RegisterSharedEvent(event)
    local store = Persistence.EnsureLoaded()
    local eventID = event and (event.eventRef or event.eventID or event.id)
    local already = eventID and store.sharedEvents[tostring(eventID)]
    local value, reason = Lifecycle.RegisterSharedEvent(store, event)
    if value and not already then Persistence.MarkDirty() end
    return value, reason
end

function Persistence.Apply(envelope, options)
    local store = Persistence.EnsureLoaded()
    local result, reason = Lifecycle.Apply(store, envelope, options)
    if result and (result.persisted or result.reason == "trivial_resolved") then
        Persistence.MarkDirty()
    end
    return result, reason
end

function Persistence.RecordNPCSpeech(spec)
    local store = Persistence.EnsureLoaded()
    local result, reason = Lifecycle.RecordNPCSpeech(store, spec)
    if result and result.persisted then Persistence.MarkDirty() end
    return result, reason
end

function Persistence.Close(playerUUID, npcID, options)
    local store = Persistence.EnsureLoaded()
    local result, reason = Lifecycle.Close(store, playerUUID, npcID, options)
    if result and result.reason ~= "no_thread" then
        Persistence.MarkDirty()
    end
    return result, reason
end

function Persistence.Resume(playerUUID, npcID, options)
    local store = Persistence.EnsureLoaded()
    local result, reason = Lifecycle.Resume(
        store, playerUUID, npcID, options
    )
    if result and result.persisted then Persistence.MarkDirty() end
    return result, reason
end

function Persistence.Compact(playerUUID, npcID, options)
    local store = Persistence.EnsureLoaded()
    local result, reason = Lifecycle.Compact(store, playerUUID, npcID, options)
    if result and result.reason ~= "no_thread" then
        Persistence.MarkDirty()
    end
    return result, reason
end

function Persistence.Project(playerUUID, npcID)
    return Lifecycle.Project(
        Persistence.EnsureLoaded(), playerUUID, npcID
    )
end

function Persistence.Metrics()
    return Lifecycle.Metrics(Persistence.EnsureLoaded())
end

function Persistence.Save(flush)
    Persistence.EnsureLoaded()
    if not Persistence.Dirty then return false, "not_dirty" end
    local written = Reset.Write(
        Persistence.MODDATA_KEY,
        copy(Lifecycle.Export(Persistence.Store))
    )
    if not written then return false, "moddata_unavailable" end
    if flush ~= false and GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
    Persistence.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData
    and not Persistence.InitHookRegistered
then
    Events.OnInitGlobalModData.Add(function() Persistence.Load(true) end)
    Persistence.InitHookRegistered = true
end

return Persistence
