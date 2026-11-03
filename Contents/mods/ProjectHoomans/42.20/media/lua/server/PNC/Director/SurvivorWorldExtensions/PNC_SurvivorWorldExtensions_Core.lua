if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.SurvivorWorldExtensions =
    PNC.SurvivorWorldExtensions or {}

local Extensions = PNC.SurvivorWorldExtensions
local Reset = PNC.ModDataStore
    or require "PNC/Core/Persistence/PNC_ModDataStore"

Extensions.STORAGE_KEY = "PNC_SurvivorWorldExtensions_v1"
Extensions.SCHEMA_VERSION = 1
Extensions.Active = Extensions.Active == true
Extensions.Dirty = Extensions.Dirty == true

local function copy(value, seen)
    if PNC.Core and PNC.Core.DeepCopy then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[copy(key, seen)] = copy(child, seen)
    end
    return output
end

local function setFromArray(value)
    local output = {}
    for _, id in ipairs(type(value) == "table" and value or {}) do
        if type(id) == "string" and id ~= "" then
            output[id] = true
        end
    end
    return output
end

local function newRegistry()
    return {
        schemaVersion = Extensions.SCHEMA_VERSION,
        revision = 0,
        factions = {},
        communities = {},
        sitesByID = {},
        groups = {},
        locations = {},
        abstract = {
            encounters = {},
            encounterCooldowns = {},
            nextEncounterSerial = 1,
            uniqueNPCsByID = {},
        },
    }
end

local function valid(raw)
    return type(raw) == "table"
        and tonumber(raw.schemaVersion)
            == Extensions.SCHEMA_VERSION
        and type(raw.factions) == "table"
        and type(raw.communities) == "table"
        and type(raw.sitesByID) == "table"
        and type(raw.groups) == "table"
        and type(raw.locations) == "table"
        and type(raw.abstract) == "table"
end

function Extensions.NewRegistry()
    return newRegistry()
end

function Extensions.Copy(value)
    return copy(value)
end

function Extensions.SetFromArray(value)
    return setFromArray(value)
end

function Extensions.Load()
    local raw = Reset.Read(Extensions.STORAGE_KEY)
    if valid(raw) then
        Extensions.Registry = copy(raw)
        Extensions.Dirty = false
        return true, "loaded"
    end
    Extensions.Registry = newRegistry()
    Extensions.Dirty = false
    if raw ~= nil and not Reset.IsEmpty(raw) then
        Extensions.LastReset = Reset.Info(
            raw,
            Extensions.SCHEMA_VERSION,
            "version_or_shape_mismatch",
            "survivor_world_extensions"
        )
    end
    return false, raw == nil or Reset.IsEmpty(raw)
        and "empty_state" or "invalid_state"
end

function Extensions.MarkDirty(reason)
    Extensions.Dirty = true
    Extensions.LastDirtyReason = tostring(reason or "unspecified")
    return true
end

function Extensions.LegacyRootHasData(key)
    local raw = Reset.Read(key)
    return type(raw) == "table" and not Reset.IsEmpty(raw)
end

function Extensions.RetireLegacyRoot(key)
    if not Extensions.LegacyRootHasData(key) then
        return false, "already_empty"
    end
    return Reset.Write(key, {})
end

function Extensions.FlushCore()
    local authority = PNC.CoreSurvivorWorldAuthority
    local world = authority and authority.World
    local store = world and world.RuntimeStore
    if not store or not store.Active then
        return false, "core_survivor_world_unavailable"
    end
    local saved, reason = store.Save()
    if saved == false and reason ~= "not_dirty" then
        return false, reason
    end
    return true, reason or "saved"
end

function Extensions.Save()
    if not Extensions.Active then
        return false, "extensions_not_active"
    end
    if not Extensions.Dirty
        and not (PNC.Factions and PNC.Factions.Dirty)
        and not (PNC.Communities and PNC.Communities.Dirty)
        and not (PNC.AbstractWorldStore
            and PNC.AbstractWorldStore.Dirty)
    then
        return false, "not_dirty"
    end

    local coreOK, coreReason = Extensions.FlushCore()
    if not coreOK then return false, coreReason end

    local captured, captureReason = Extensions.CaptureAll()
    if not captured then return false, captureReason end
    captured.schemaVersion = Extensions.SCHEMA_VERSION
    captured.revision = math.max(
        0,
        tonumber(Extensions.Registry
            and Extensions.Registry.revision) or 0
    ) + 1

    local written, reason = Reset.Write(
        Extensions.STORAGE_KEY,
        copy(captured)
    )
    if not written then return false, reason end

    Extensions.Registry = captured
    Extensions.Dirty = false
    if PNC.Factions then PNC.Factions.Dirty = false end
    if PNC.Communities then PNC.Communities.Dirty = false end
    if PNC.AbstractWorldStore then
        PNC.AbstractWorldStore.Dirty = false
    end
    return true, "saved"
end

Extensions.Registry = Extensions.Registry or newRegistry()
Extensions.Internal = Extensions.Internal or {}
Extensions.Internal.Copy = copy
Extensions.Internal.SetFromArray = setFromArray
Extensions.Internal.Reset = Reset

return Extensions
