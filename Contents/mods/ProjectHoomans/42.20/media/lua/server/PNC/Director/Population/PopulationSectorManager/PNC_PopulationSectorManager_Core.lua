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

Sectors.Runtime = Sectors.Runtime or {}
Sectors.GroupIDs = Sectors.GroupIDs or {}
Sectors.CommunityIDs = Sectors.CommunityIDs or {}
Sectors.GroupSector = Sectors.GroupSector or {}
Sectors.CommunitySector = Sectors.CommunitySector or {}
Sectors.PlayerPositions = Sectors.PlayerPositions or {}
Sectors.Metrics = Sectors.Metrics or { rebuilds = 0, repairs = 0, mismatches = 0 }
Sectors.History = Sectors.History or {}
Sectors.RepairCursor = Sectors.RepairCursor or 1

function H.Persistent()
    Store.EnsureLoaded()
    -- Store.Load/Save own normalization. Replacing this table on every read
    -- invalidates references held by bootstrap and reconciliation transactions,
    -- causing otherwise valid mutations (starter attempts/completion) to vanish.
    if type(Store.Registry.population) ~= "table" then
        Store.Registry.population = PNC.AbstractWorldTypes.NormalizePopulation(nil)
    end
    return Store.Registry.population
end

function H.Coords(x, y)
    local size = Config.SECTOR_SIZE
    return math.floor((tonumber(x) or 0) / size),
        math.floor((tonumber(y) or 0) / size)
end

function Sectors.IDForPosition(x, y)
    local sx, sy = H.Coords(x, y)
    return "psector_" .. tostring(sx) .. "_" .. tostring(sy), sx, sy
end

function Sectors.ParseID(id)
    local sx, sy = string.match(tostring(id or ""),
        "^psector_([%-]?%d+)_([%-]?%d+)$")
    return tonumber(sx), tonumber(sy)
end

function Sectors.Center(id)
    local sx, sy = Sectors.ParseID(id)
    if not sx then return nil end
    return { x = (sx + 0.5) * Config.SECTOR_SIZE,
        y = (sy + 0.5) * Config.SECTOR_SIZE, z = 0 }
end

function Sectors.Ensure(id)
    local data = H.Persistent()
    local state = data.sectors[tostring(id or "")]
    if not state then
        local sx = Sectors.ParseID(id)
        if sx == nil then return nil end
        state = { id = id, discovered = false, hadGroups = false,
            hadSettlements = false,
            groupGenerationCooldownUntil = 0,
            settlementGenerationCooldownUntil = 0,
            lastReconciledAt = 0 }
        data.sectors[id] = state
        Store.Touch("population_sector_created")
    end
    local runtime = Sectors.Runtime[id]
    if not runtime then
        runtime = { id = id, active = false, relevant = false,
            nearbyPlayers = 0, desiredGroups = 0, desiredSettlements = 0,
            groupPressure = 1, settlementPressure = 1 }
        Sectors.Runtime[id] = runtime
    end
    return state, runtime
end

function Sectors.MarkRelevant(id, discovered)
    local state, runtime = Sectors.Ensure(id)
    if not state then return false, "invalid_sector" end
    runtime.relevant = true
    if discovered == true and not state.discovered then
        state.discovered = true
        Store.Touch("population_sector_discovered")
    end
    return true, "relevant"
end

function H.Add(index, id, entityID)
    index[id] = index[id] or {}
    index[id][entityID] = true
end

function H.Remove(index, id, entityID)
    if index[id] then index[id][entityID] = nil end
end

