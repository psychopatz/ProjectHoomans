-- Whole-plot clearing, watering, growth, and harvesting.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}
local Adapter = PNC.PZFarmingAdapter
local Internal = Adapter.Internal
local call = Internal.Call
local farmingSystem = Internal.FarmingSystem
local squareAt = Internal.SquareAt
local eachTile = Internal.EachTile
local cropState = Internal.CropState

local function validateLoadedPlot(component)
    local ok, reason = eachTile(component, function(x, y, z)
        return squareAt(x, y, z) ~= nil, "WORLD_SQUARE_UNLOADED"
    end)
    return ok, reason
end

function Adapter.ClearPlot(component)
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local ready, reason = validateLoadedPlot(component)
    if not ready then return false, reason end
    local removed = 0
    local ok, failure = eachTile(component, function(x, y, z)
        local square = squareAt(x, y, z)
        local plant = Adapter.GetPlantAt(x, y, z)
        if plant and cropState(plant) ~= "plow" then
            system:removePlant(plant)
            system:plow(square)
            removed = removed + 1
        end
        return true
    end)
    if not ok then return false, failure end
    return true, "PLOT_CLEARED", { removed = removed }
end

function Adapter.ForceWaterPlot(component)
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local ready, reason = validateLoadedPlot(component)
    if not ready then return false, reason end
    local watered = 0
    local ok, failure = eachTile(component, function(x, y, z)
        local plant = Adapter.GetPlantAt(x, y, z)
        if plant and cropState(plant) == "seeded" then
            if type(plant.water) ~= "function" then
                return false, "VANILLA_WATER_UNAVAILABLE"
            end
            plant:water(nil, 10)
            watered = watered + 1
        end
        return true
    end)
    if not ok then return false, failure end
    return true, "PLOT_WATERED", { watered = watered }
end

function Adapter.ForceGrowPlot(component)
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local ready, reason = validateLoadedPlot(component)
    if not ready then return false, reason end
    local grown = 0
    local ok, failure = eachTile(component, function(x, y, z)
        local plant = Adapter.GetPlantAt(x, y, z)
        local props = plant and farming_vegetableconf
            and farming_vegetableconf.props[plant.typeOfSeed] or nil
        if plant and props and cropState(plant) == "seeded" then
            local target = tonumber(props.harvestLevel or props.fullGrown) or 1
            local guard = 0
            while plant:isAlive() and (tonumber(plant.nbOfGrow) or -1) <= target
                and guard < 12
            do
                plant:water(nil, 10)
                system:growPlant(plant, nil, true)
                guard = guard + 1
            end
            if plant:isAlive() then grown = grown + 1 end
        end
        return true
    end)
    if not ok then return false, failure end
    return true, "PLOT_GROWN", { grown = grown }
end

function Adapter.HarvestPlot(component, player)
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local ready, reason = validateLoadedPlot(component)
    if not ready then return false, reason end
    local harvested = 0
    local ok, failure = eachTile(component, function(x, y, z)
        local plant = Adapter.GetPlantAt(x, y, z)
        if plant and plant.canHarvest and call(plant, "canHarvest") == true then
            if type(system.harvest) ~= "function" then
                return false, "VANILLA_HARVEST_UNAVAILABLE"
            end
            system:harvest(plant, player)
            harvested = harvested + 1
        end
        return true
    end)
    if not ok then return false, failure end
    return true, "PLOT_HARVESTED", { harvested = harvested }
end

Internal.ValidateLoadedPlot = validateLoadedPlot

return Adapter
