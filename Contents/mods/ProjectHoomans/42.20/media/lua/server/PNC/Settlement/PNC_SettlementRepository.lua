if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementRepository = PNC.SettlementRepository or {}

local Repository = PNC.SettlementRepository
local CoreZones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

Repository.SCHEMA_VERSION = 1
Repository.MODDATA_KEY = "PNC_Settlements_V1"
Repository.State = Repository.State or {
    schemaVersion = Repository.SCHEMA_VERSION,
    bases = {}, facilities = {}, components = {}, stockpileNodes = {}, zones = {},
}
Repository.Dirty = Repository.Dirty or false
Repository.Loaded = Repository.Loaded or false
Repository.Migrations = Repository.Migrations or {}

Repository.Migrations[0] = Repository.Migrations[0] or function(raw)
    raw.schemaVersion = 1
    raw.bases = type(raw.bases) == "table" and raw.bases or {}
    raw.facilities = type(raw.facilities) == "table" and raw.facilities or {}
    raw.components = type(raw.components) == "table" and raw.components or {}
    raw.stockpileNodes = type(raw.stockpileNodes) == "table" and raw.stockpileNodes or {}
    raw.zones = type(raw.zones) == "table" and raw.zones or {}
    return raw
end

local function freshState()
    return { schemaVersion = Repository.SCHEMA_VERSION, bases = {}, facilities = {},
        components = {}, stockpileNodes = {}, zones = {} }
end

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function sanitizeMap(source)
    return type(source) == "table" and copy(source) or {}
end

function Repository.Import(raw)
    local source = type(raw) == "table" and copy(raw) or {}
    local version = math.max(0, math.floor(tonumber(source.schemaVersion) or 0))
    while version < Repository.SCHEMA_VERSION do
        local migration = Repository.Migrations[version]
        if not migration then return nil, "MIGRATION_NOT_FOUND" end
        source = migration(source)
        version = math.floor(tonumber(source.schemaVersion) or version + 1)
    end
    if version > Repository.SCHEMA_VERSION then return nil, "SCHEMA_TOO_NEW" end
    local state = freshState()
    state.bases = sanitizeMap(source.bases)
    state.facilities = sanitizeMap(source.facilities)
    state.components = sanitizeMap(source.components)
    state.stockpileNodes = sanitizeMap(source.stockpileNodes)
    state.zones = sanitizeMap(source.zones)
    for _, facility in pairs(state.facilities) do facility.cachedState = nil end
    for _, component in pairs(state.components) do
        if component.kind == "region" and component.region then
            component.region = GridRegion.normalize(component.region)
            component.tileCount = GridRegion.countTiles(component.region)
        else
            component.tileCount = 0
        end
    end
    Repository.State = state
    for _, zone in pairs(state.zones) do CoreZones.register(zone) end
    Repository.Loaded = true
    Repository.Dirty = false
    return state
end

function Repository.Export()
    local state = Repository.State
    local output = freshState()
    output.bases = copy(state.bases)
    output.facilities = copy(state.facilities)
    output.components = copy(state.components)
    for _, facility in pairs(output.facilities) do facility.cachedState = nil end
    for _, component in pairs(output.components) do component.tileCount = nil end
    output.stockpileNodes = copy(state.stockpileNodes)
    for id, zone in pairs(CoreZones.export().byID) do
        if zone.ownerType == "projecthoomans.base"
            or zone.ownerType == "projecthoomans.facility"
        then
            output.zones[id] = zone
        end
    end
    return output
end

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Repository.State end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    return Repository.Import(raw)
end

function Repository.Save()
    Repository.Load()
    if not Repository.Dirty then return true, "unchanged" end
    if ModData and ModData.getOrCreate then
        local target = ModData.getOrCreate(Repository.MODDATA_KEY)
        local payload = Repository.Export()
        for key, _ in pairs(target) do target[key] = nil end
        for key, value in pairs(payload) do target[key] = value end
    else
        return false, "moddata_unavailable"
    end
    Repository.Dirty = false
    return true, "saved"
end

function Repository.MarkDirty()
    Repository.Dirty = true
end

function Repository.GetBase(id)
    Repository.Load()
    return Repository.State.bases[tostring(id or "")]
end

function Repository.GetFacility(id)
    Repository.Load()
    return Repository.State.facilities[tostring(id or "")]
end

function Repository.GetComponent(id)
    Repository.Load()
    return Repository.State.components[tostring(id or "")]
end

function Repository.GetStockpileNode(id)
    Repository.Load()
    return Repository.State.stockpileNodes[tostring(id or "")]
end

function Repository.FindBaseByColony(colonyId)
    Repository.Load()
    for _, base in pairs(Repository.State.bases) do
        if base.colonyId == colonyId then return base end
    end
    return nil
end

function Repository.FindBaseByFaction(factionId)
    Repository.Load()
    factionId = tostring(factionId or "")
    for _, base in pairs(Repository.State.bases) do
        if tostring(base.factionId or "") == factionId then
            return base
        end
    end
    return nil
end

local function onInitGlobalModData()
    Repository.Load(true)
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Repository.LoadHookRegistered = true
end
if Events and Events.OnSave and not Repository.SaveHookRegistered then
    Events.OnSave.Add(Repository.Save)
    Repository.SaveHookRegistered = true
end

return Repository
