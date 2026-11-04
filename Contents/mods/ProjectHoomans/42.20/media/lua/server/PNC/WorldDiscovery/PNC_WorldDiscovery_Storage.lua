-- Persistent per-character discovery registry.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes
local Reset = PNC.ModDataStore
    or require "PNC/Core/Persistence/PNC_ModDataStore"
local ImportSource = PNC.SurvivorWorldImportSource
    or require "PNC/Director/PNC_SurvivorWorldImportSource"

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local output = {}
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, seen)
        end
    end
    seen[value] = nil
    return output
end

local function assign(target, source)
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(source) do target[key] = copy(value) end
end

function Internal.WorldHour()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

function Internal.CharacterUUID(player)
    return PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetCharacterUUID
        and PNC.PlayerCharacters.GetCharacterUUID(player) or nil
end

function Discovery.Load()
    local adapter = PNC.CoreWorldDiscoveryAdapter
    if adapter and adapter.Active
        and adapter.SyncFromCore
    then
        return adapter.SyncFromCore()
    end
    local raw, reason, sourceRaw = ImportSource.Read("discovery")
    Discovery.Registry = Types.NormalizeRegistry(raw)
    Discovery.Loaded = true
    Discovery.Dirty = reason ~= nil and reason ~= "empty_state"
    if Discovery.Dirty then
        Reset.Mark(Discovery, sourceRaw, Types.SCHEMA_VERSION, reason,
            "world_discovery")
    end
    return true
end

function Discovery.EnsureLoaded()
    if not Discovery.Loaded then return Discovery.Load() end
    return true
end

function Discovery.Save()
    Discovery.EnsureLoaded()
    if not Discovery.Dirty then return false, "not_dirty" end
    local adapter = PNC.CoreWorldDiscoveryAdapter
    if not adapter or type(adapter.Save) ~= "function" then
        return false, "survivor_world_discovery_cutover_unavailable"
    end
    if adapter.Active ~= true then
        return false, "survivor_world_discovery_cutover_inactive"
    end
    return adapter.Save("pnc_world_discovery_save")
end

function Internal.PlayerRecord(player, create)
    Discovery.EnsureLoaded()
    local uuid = Internal.CharacterUUID(player)
    if not uuid then return nil, "player_identity_unavailable" end
    local record = Discovery.Registry.players[uuid]
    if not record and create == true then
        record = {
            revision = 0,
            lastRadioScanAt = 0,
            radioScanCount = 0,
            entities = { settlement = {}, mobile_group = {} },
        }
        Discovery.Registry.players[uuid] = record
        Discovery.Dirty = true
    end
    return record, uuid
end

function Discovery.ResetPlayer(player)
    local record, uuid = Internal.PlayerRecord(player, false)
    if not record then return false, uuid end
    record.entities = { settlement = {}, mobile_group = {} }
    record.lastRadioScanAt = 0
    record.radioScanCount = 0
    record.revision = (tonumber(record.revision) or 0) + 1
    Discovery.Registry.revision =
        (tonumber(Discovery.Registry.revision) or 0) + 1
    Discovery.Dirty = true
    Discovery.Save()
    return true, "reset"
end

local function onInitGlobalModData() Discovery.Load() end
if Events and Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
end
return Discovery
