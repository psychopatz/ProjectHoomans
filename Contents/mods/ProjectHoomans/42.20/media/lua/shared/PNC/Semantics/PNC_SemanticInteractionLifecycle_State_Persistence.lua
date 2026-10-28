PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle
local Internal = Lifecycle.Internal or {}
Lifecycle.Internal = Internal

local boundedCopy = Internal.BoundedCopy
local finite = Internal.Finite
local copyThread = Internal.CopyThread
local capThread = Internal.CapThread

function Lifecycle.Export(store)
    local pairCapsules = {}
    local sharedEventCapsules = {}
    local pairCount = 0
    local sharedEventCount = 0
    for key, thread in pairs(store.pairs) do
        if pairCount >= store.limits.pairs then break end
        pairCapsules[key] = copyThread(thread)
        pairCount = pairCount + 1
    end
    for key, event in pairs(store.sharedEvents) do
        if sharedEventCount >= store.limits.sharedEvents then break end
        sharedEventCapsules[key] = boundedCopy(event, 0, { count = 0 })
        sharedEventCount = sharedEventCount + 1
    end
    return {
        schema = Lifecycle.SCHEMA,
        schemaVersion = Lifecycle.VERSION,
        worldHour = store.worldHour,
        pairs = pairCapsules,
        sharedEvents = sharedEventCapsules,
        metrics = Lifecycle.Metrics(store),
    }
end

function Lifecycle.Import(store, payload)
    if type(store) ~= "table" then
        return false, "lifecycle_store_required"
    end
    if store.authoritative ~= true then
        return false, "lifecycle_not_authoritative"
    end
    if type(payload) ~= "table" or payload.schema ~= Lifecycle.SCHEMA then
        return false, "lifecycle_snapshot_invalid"
    end
    if type(payload.pairs) == "table" then
        store.pairs = {}
        local pairCount = 0
        for key, thread in pairs(payload.pairs) do
            if pairCount >= store.limits.pairs then break end
            if type(thread) == "table"
                and type(thread.playerUUID) == "string"
                and type(thread.npcID) == "string"
            then
                local imported = copyThread(thread)
                capThread(imported, store)
                store.pairs[key] = imported
                pairCount = pairCount + 1
            end
        end
    end
    if type(payload.sharedEvents) == "table" then
        store.sharedEvents = {}
        local eventCount = 0
        for key, event in pairs(payload.sharedEvents) do
            if eventCount >= store.limits.sharedEvents then break end
            if type(event) == "table" then
                store.sharedEvents[key] = boundedCopy(event, 0)
                eventCount = eventCount + 1
            end
        end
    end
    store.worldHour = finite(payload.worldHour) or store.worldHour
    store.active = {}
    store.transient = {}
    for key, thread in pairs(store.pairs) do
        if thread.status ~= "ARCHIVED" then store.active[key] = thread end
    end
    return true
end

Lifecycle.Internal = Lifecycle.Internal or {}
Lifecycle.Internal.PairKey = pairKey
Lifecycle.Internal.HasDurableMeaning = hasDurableMeaning
Lifecycle.Internal.ApproximateSize = approximateSize


return Lifecycle
