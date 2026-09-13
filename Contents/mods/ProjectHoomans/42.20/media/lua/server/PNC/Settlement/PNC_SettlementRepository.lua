if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementRepository = PNC.SettlementRepository or {}

local Repository = PNC.SettlementRepository
local CoreZones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"

Repository.SCHEMA_VERSION = 1
Repository.MODDATA_KEY = "PNC_Settlements_V1"
Repository.State = Repository.State or {
    schemaVersion = Repository.SCHEMA_VERSION,
    bases = {}, facilities = {}, components = {}, stockpileNodes = {}, zones = {},
}
Repository.Dirty = Repository.Dirty or false
Repository.Loaded = Repository.Loaded or false

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
    local raw = Reset.Read(Repository.MODDATA_KEY)
    local reason = Reset.Check(raw, Repository.SCHEMA_VERSION, nil,
        function(value)
            return type(value.bases) == "table"
                and type(value.facilities) == "table"
                and type(value.components) == "table"
                and type(value.stockpileNodes) == "table"
                and type(value.zones) == "table"
        end)
    local oldZones = Repository.State and Repository.State.zones or {}
    if reason ~= nil and reason ~= "empty_state" then
        for id, _ in pairs(oldZones) do
            if CoreZones.remove then CoreZones.remove(id) end
        end
    end
    local state = Repository.Import(reason == nil and raw or nil)
    if reason ~= nil and reason ~= "empty_state" then
        Reset.Mark(Repository, raw, Repository.SCHEMA_VERSION, reason,
            "settlements")
    else
        Repository.Dirty = false
    end
    return state
end

function Repository.Save()
    Repository.Load()
    if not Repository.Dirty then return true, "unchanged" end
    if ModData and ModData.getOrCreate then
        local payload = Repository.Export()
        local written = Reset.Write(Repository.MODDATA_KEY, payload)
        if not written then return false, "moddata_unavailable" end
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
