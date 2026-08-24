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

function Sectors.RefreshPlayers()
    Sectors.PlayerPositions = {}
    local changed = false
    local previouslyActive = {}
    for _, runtime in pairs(Sectors.Runtime) do
        previouslyActive[runtime.id] = runtime.active == true
        runtime.active, runtime.nearbyPlayers = false, 0
    end
    Core.ForEachPlayer(function(player)
        local position = { x = player:getX(), y = player:getY(), z = player:getZ() }
        Sectors.PlayerPositions[#Sectors.PlayerPositions + 1] = position
        local id, sx, sy = Sectors.IDForPosition(position.x, position.y)
        local state, runtime = Sectors.Ensure(id)
        if not state.discovered then changed = true end
        state.discovered, runtime.active, runtime.relevant = true, true, true
        if not previouslyActive[id] then
            Store.Emit("POPULATION_SECTOR_ACTIVATED", { sectorId = id })
            previouslyActive[id] = true
        end
        runtime.nearbyPlayers = runtime.nearbyPlayers + 1
        for dx = -Config.ACTIVE_NEIGHBOR_RADIUS, Config.ACTIVE_NEIGHBOR_RADIUS do
            for dy = -Config.ACTIVE_NEIGHBOR_RADIUS, Config.ACTIVE_NEIGHBOR_RADIUS do
                local neighborID = "psector_" .. tostring(sx + dx)
                    .. "_" .. tostring(sy + dy)
                local neighborState, neighbor = Sectors.Ensure(neighborID)
                if not neighborState.discovered then changed = true end
                neighborState.discovered, neighbor.relevant = true, true
            end
        end
    end)
    if changed then Store.Touch("population_player_footprint_discovered") end
    return #Sectors.PlayerPositions
end

function Sectors.PlayerDistance(x, y)
    local best = math.huge
    for _, player in ipairs(Sectors.PlayerPositions) do
        local distance = Core.Distance(x, y, player.x, player.y)
        if distance < best then best = distance end
    end
    return best
end

function Sectors.LivePlayerDistance(x, y)
    local best = math.huge
    Core.ForEachPlayer(function(player)
        local distance = Core.Distance(x, y, player:getX(), player:getY())
        if distance < best then best = distance end
    end)
    return best
end

