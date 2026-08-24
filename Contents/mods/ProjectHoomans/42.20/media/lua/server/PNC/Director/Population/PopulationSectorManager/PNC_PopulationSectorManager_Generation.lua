if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationSectors = PNC.PopulationSectors or {}
PNC.PopulationSectorInternal = PNC.PopulationSectorInternal or {}

local Sectors = PNC.PopulationSectors
local H = PNC.PopulationSectorInternal
local Config = PNC.DirectorConfig.Population
local Store = PNC.AbstractWorldStore
local Core = PNC.Core

function Sectors.NextGenerationID(kind)
    local data = H.Persistent()
    local serial = data.nextGenerationSerial
    data.nextGenerationSerial = serial + 1
    Store.Touch("population_generation_sequence")
    return "POP_" .. tostring(kind or "ENTITY") .. "_"
        .. string.format("%07d", serial), serial
end

function Sectors.Seed(text)
    local value = 5381
    text = tostring(text or "")
    for index = 1, #text do
        value = (value * 33 + string.byte(text, index)) % 2147483647
    end
    return value
end

function H.EngineSeedString()
    local instance = WorldGenParams and WorldGenParams.INSTANCE or nil
    if not instance or not instance.getSeedString then return nil end
    local ok, value = pcall(instance.getSeedString, instance)
    value = ok and tostring(value or "") or ""
    return value ~= "" and value or nil
end

function Sectors.WorldSeed()
    local data = H.Persistent()
    if (tonumber(data.worldSeed) or 0) > 0 then
        return data.worldSeed, data.worldSeedString
    end
    local seedString = H.EngineSeedString()
    local seed
    if seedString then
        seed = Sectors.Seed("PZ_WORLD:" .. seedString)
    elseif ZombRand then
        local ok, value = pcall(ZombRand, 2147483646)
        seed = ok and tonumber(value) and math.floor(value) + 1 or nil
    end
    seed = math.max(1, math.min(2147483647,
        tonumber(seed) or Sectors.Seed("PNC_POPULATION_WORLD")))
    data.worldSeed = seed
    data.worldSeedString = seedString or ("PNC-" .. tostring(seed))
    Store.Touch("population_world_seed")
    return data.worldSeed, data.worldSeedString
end

function Sectors.GenerationSeed(kind, sectorID, serial, qualifier)
    local worldSeed = Sectors.WorldSeed()
    return Sectors.Seed(table.concat({ tostring(worldSeed),
        tostring(kind or "ENTITY"), tostring(sectorID or ""),
        tostring(serial or 0), tostring(qualifier or "") }, ":"))
end

function Sectors.WeightedChoice(weights, seed)
    local keys, total = {}, 0
    for key, value in pairs(type(weights) == "table" and weights or {}) do
        value = math.max(0, tonumber(value) or 0)
        if value > 0 then
            keys[#keys + 1] = tostring(key)
            total = total + value
        end
    end
    if total <= 0 then return nil end
    table.sort(keys)
    local roll = (Sectors.Seed(tostring(seed) .. ":WEIGHTED_ROLL")
        % 1000000) / 1000000 * total
    for _, key in ipairs(keys) do
        roll = roll - math.max(0, tonumber(weights[key]) or 0)
        if roll <= 0 then return key end
    end
    return keys[#keys]
end

function Sectors.IsCommitted(generationID)
    return H.Persistent().committedGenerationIds[tostring(generationID or "")] == true
end

function Sectors.MarkCommitted(generationID)
    local data = H.Persistent()
    generationID = tostring(generationID or "")
    if data.committedGenerationIds[generationID] then return false end
    data.committedGenerationIds[generationID] = true
    data.committedOrder[#data.committedOrder + 1] = generationID
    while #data.committedOrder > Config.COMMITTED_GENERATION_HISTORY_LIMIT do
        local expired = table.H.Remove(data.committedOrder, 1)
        data.committedGenerationIds[expired] = nil
    end
    Store.Touch("population_generation_committed")
    return true
end

function Sectors.SetProvenance(entityID, generation)
    if not entityID or type(generation) ~= "table" then return false end
    H.Persistent().provenance[tostring(entityID)] = Core.DeepCopy(generation)
    Store.Touch("population_provenance")
    return true
end

function Sectors.AddHistory(eventName, details, now)
    local entry = Core.DeepCopy(details or {})
    entry.event = tostring(eventName or "POPULATION_EVENT")
    entry.at = tonumber(now) or Store.WorldAgeHours()
    Sectors.History[#Sectors.History + 1] = entry
    while #Sectors.History > Config.GENERATION_HISTORY_LIMIT do
        table.H.Remove(Sectors.History, 1)
    end
    return entry
end

return Sectors

