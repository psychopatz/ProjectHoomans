-- Strict, migration-free ModData reset contract.
--
-- Canonical roots deliberately accept only the exact shape version owned by
-- their store. A missing root is a normal first-run state; an existing root
-- with an unsupported or malformed version is discarded and rewritten on the
-- next coordinated save. Reset diagnostics stay runtime-only.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Reset = PNC.Persistence.Reset or {}
PNC.Persistence.Reset = Reset

local function empty(value)
    if type(value) ~= "table" then return true end
    for _, _ in pairs(value) do return false end
    return true
end

local function read(key)
    if not ModData then return nil end
    if type(ModData.get) == "function" then
        return ModData.get(key)
    end
    -- Test harnesses and older isolated compositions may expose only
    -- getOrCreate. This fallback keeps those compositions functional.
    if type(ModData.getOrCreate) == "function" then
        return ModData.getOrCreate(key)
    end
    return nil
end

local function versionOf(raw, field)
    if type(raw) ~= "table" then return nil end
    return tonumber(raw[field or "schemaVersion"])
end

function Reset.Read(key)
    return read(key)
end

function Reset.IsEmpty(value)
    return empty(value)
end

function Reset.Check(raw, expectedVersion, field, validator)
    if raw == nil then return "empty_state" end
    if type(raw) == "table" and empty(raw) then return "empty_state" end
    if type(raw) ~= "table" then return "invalid_state" end
    if versionOf(raw, field) ~= tonumber(expectedVersion) then
        return "version_mismatch"
    end
    if validator and validator(raw) ~= true then return "invalid_state" end
    return nil
end

function Reset.Info(raw, expectedVersion, reason, owner, field)
    local core = PNC.Core
    return {
        owner = tostring(owner or "unknown"),
        reason = tostring(reason or "invalid_state"),
        fromVersion = versionOf(raw, field),
        toVersion = tonumber(expectedVersion),
        at = core and type(core.Now) == "function" and core.Now() or 0,
    }
end

function Reset.Mark(store, raw, expectedVersion, reason, owner, field)
    if not store then return end
    store.LastReset = Reset.Info(raw, expectedVersion, reason, owner, field)
    store.Dirty = true
    local core = PNC.Core
    if core and type(core.LogWarn) == "function" then
        core.LogWarn("PNC persistence reset owner="
            .. tostring(store.LastReset.owner)
            .. " reason=" .. tostring(store.LastReset.reason)
            .. " from=" .. tostring(store.LastReset.fromVersion)
            .. " to=" .. tostring(store.LastReset.toVersion))
    end
end

function Reset.Write(key, payload)
    if not ModData or type(ModData.getOrCreate) ~= "function" then
        return false, "moddata_unavailable"
    end
    local target = ModData.getOrCreate(key)
    if type(target) ~= "table" then return false, "moddata_unavailable" end
    for existingKey, _ in pairs(target) do target[existingKey] = nil end
    for payloadKey, value in pairs(payload or {}) do
        target[payloadKey] = value
    end
    return true, "written"
end

return Reset
