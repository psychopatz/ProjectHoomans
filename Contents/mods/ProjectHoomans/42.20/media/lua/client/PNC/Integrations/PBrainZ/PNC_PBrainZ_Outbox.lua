-- Shared bounded durable outbox mechanics for PBrainZ handoffs.
--
-- Domain modules own their event/message validation and wire shape. This
-- module owns only persistence validation, fallback storage, indexing, and
-- retry-safe append/peek/acknowledge operations.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Internal = PNC.PBrainZ.Internal
local Outbox = Internal.Outbox or {}
Internal.Outbox = Outbox

local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"

function Outbox.New(config)
    config = config or {}
    local owner = config.owner or {}
    local hasExplicitStorageKey = config.storageKey ~= nil
    local storageKey = tostring(config.storageKey or "PNC_PBrainZOutbox")
    local legacyStorageKeys = config.legacyStorageKeys or {}
    if type(legacyStorageKeys) == "string" then
        legacyStorageKeys = { legacyStorageKeys }
    end
    if not hasExplicitStorageKey then
        -- Compatibility boundary for callers of the old default key. Legacy
        -- roots are read once only when the canonical root is empty.
        legacyStorageKeys = { "PNC_HoomansLLMOutbox" }
    end
    local version = tonumber(config.version) or 1
    local idField = tostring(config.idField or "id")
    local resetOwner = tostring(config.resetOwner or storageKey)
    local fallbackRoot = owner.memoryRoot or {}
    owner.memoryRoot = fallbackRoot
    local storageValidated = false
    local store = {}

    local function clearFallback()
        for key, _ in pairs(fallbackRoot) do fallbackRoot[key] = nil end
    end

    local function copyFallback(source)
        clearFallback()
        for key, value in pairs(source or {}) do
            fallbackRoot[key] = value
        end
    end

    local function validateStorage()
        if storageValidated then return end
        local raw = Reset.Read(storageKey)
        local reason = Reset.Check(raw, version, "version",
            function(value) return type(value.records) == "table" end)
        if reason == "empty_state" then
            for _, legacyKey in ipairs(legacyStorageKeys) do
                local candidate = tostring(legacyKey or "")
                if candidate ~= "" and candidate ~= storageKey then
                    local legacyRaw = Reset.Read(candidate)
                    local legacyReason = Reset.Check(
                        legacyRaw,
                        version,
                        "version",
                        function(value) return type(value.records) == "table" end
                    )
                    if legacyReason == nil then
                        local migrated = false
                        if ModData and ModData.getOrCreate then
                            local written = Reset.Write(storageKey, legacyRaw)
                            migrated = written == true
                        else
                            copyFallback(legacyRaw)
                            migrated = true
                        end
                        if migrated then
                            owner.LastMigration = {
                                from = candidate,
                                to = storageKey,
                            }
                            reason = nil
                            break
                        end
                    end
                end
            end
        end
        if reason ~= nil and reason ~= "empty_state" then
            owner.LastReset = Reset.Info(raw, version, reason,
                resetOwner, "version")
            if ModData and ModData.getOrCreate then
                Reset.Write(storageKey, {
                    version = version, records = {}, index = {},
                    indexReady = true,
                })
            else
                clearFallback()
            end
            if PNC.Core and PNC.Core.LogWarn then
                PNC.Core.LogWarn("PNC persistence reset owner=" .. resetOwner
                    .. " reason=" .. tostring(reason))
            end
        end
        storageValidated = true
    end

    local function storage()
        validateStorage()
        local root = ModData and ModData.getOrCreate
            and ModData.getOrCreate(storageKey) or fallbackRoot
        root.version = version
        root.records = root.records or {}
        root.index = root.index or {}
        if root.indexReady ~= true then
            root.index = {}
            for _, record in ipairs(root.records) do
                local id = record and record[idField]
                if id ~= nil and tostring(id) ~= "" then
                    root.index[tostring(id)] = true
                end
            end
            root.indexReady = true
        end
        return root
    end

    function store.Storage()
        return storage()
    end

    function store.Contains(id)
        id = tostring(id or "")
        return id ~= "" and storage().index[id] == true
    end

    function store.Append(record, id, maxPending)
        id = tostring(id or "")
        if id == "" then return false, "missing_id" end
        local root = storage()
        if root.index[id] then return true, "duplicate" end
        if maxPending and #root.records >= maxPending then
            return false, "outbox_full"
        end
        root.records[#root.records + 1] = record
        root.index[id] = true
        return true, "queued"
    end

    function store.Peek(maxBatch)
        local root = storage()
        local records = {}
        local limit = math.min(#root.records, tonumber(maxBatch) or #root.records)
        for index = 1, limit do records[#records + 1] = root.records[index] end
        return records, #root.records, tonumber(root.overflow) or 0
    end

    function store.Acknowledge(ids, maxIDs, normalizeID)
        local acknowledged = {}
        if type(ids) ~= "table" then return 0 end
        local limit = math.min(#ids, tonumber(maxIDs) or #ids)
        for index = 1, limit do
            local id = normalizeID and normalizeID(ids[index]) or ids[index]
            id = tostring(id or "")
            if id ~= "" then acknowledged[id] = true end
        end
        local root = storage()
        local kept = {}
        local removed = 0
        for _, record in ipairs(root.records) do
            local id = record and record[idField]
            id = tostring(id or "")
            if id ~= "" and acknowledged[id] then
                root.index[id] = nil
                removed = removed + 1
            elseif record then
                kept[#kept + 1] = record
            end
        end
        root.records = kept
        return removed
    end

    function store.PendingCount()
        return #(storage().records or {})
    end

    return store
end

return Outbox
