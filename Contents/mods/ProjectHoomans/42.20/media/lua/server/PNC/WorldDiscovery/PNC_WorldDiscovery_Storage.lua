-- Persistent per-character discovery registry.

if isClient and isClient() and (not isServer or not isServer()) then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

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

local function normalizeRegistry(raw)
    raw = type(raw) == "table" and raw or {}
    local output = {
        schemaVersion = Types.SCHEMA_VERSION,
        revision = math.max(0, math.floor(tonumber(raw.revision) or 0)),
        players = {},
    }
    for uuid, source in pairs(type(raw.players) == "table"
        and raw.players or {})
    do
        if type(uuid) == "string" and uuid ~= ""
            and type(source) == "table"
        then
            local playerRecord = {
                revision = math.max(0,
                    math.floor(tonumber(source.revision) or 0)),
                lastRadioScanAt = math.max(0,
                    tonumber(source.lastRadioScanAt) or 0),
                entities = { settlement = {}, mobile_group = {} },
            }
            for _, kind in ipairs({
                Types.KIND_SETTLEMENT,
                Types.KIND_MOBILE_GROUP,
            }) do
                local entries = source.entities
                    and source.entities[kind] or {}
                for entityID, entry in pairs(entries) do
                    if type(entityID) == "string"
                        and entityID ~= "" and type(entry) == "table"
                    then
                        playerRecord.entities[kind][entityID] = {
                            entityID = entityID,
                            kind = kind,
                            phase = Types.ClampPhase(entry.phase),
                            source = tostring(entry.source or "unknown"),
                            discoveredAt = math.max(0,
                                tonumber(entry.discoveredAt) or 0),
                            updatedAt = math.max(0,
                                tonumber(entry.updatedAt) or 0),
                            x = tonumber(entry.x), y = tonumber(entry.y),
                            z = tonumber(entry.z) or 0,
                        }
                    end
                end
            end
            output.players[uuid] = playerRecord
        end
    end
    return output
end

function Discovery.Load()
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Types.MODDATA_KEY) or {}
    Discovery.Registry = normalizeRegistry(raw)
    Discovery.Loaded = true
    Discovery.Dirty = tonumber(raw.schemaVersion) ~= Types.SCHEMA_VERSION
    return true
end

function Discovery.EnsureLoaded()
    if not Discovery.Loaded then return Discovery.Load() end
    return true
end

function Discovery.Save()
    Discovery.EnsureLoaded()
    if not Discovery.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Types.MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    assign(target, Discovery.Registry)
    Discovery.Dirty = false
    return true, "saved"
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
            entities = { settlement = {}, mobile_group = {} },
        }
        Discovery.Registry.players[uuid] = record
        Discovery.Dirty = true
    end
    return record, uuid
end

local function onInitGlobalModData() Discovery.Load() end
local function onSave() Discovery.Save() end

if Events and Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
end
if Events and Events.OnSave then Events.OnSave.Add(onSave) end

return Discovery
