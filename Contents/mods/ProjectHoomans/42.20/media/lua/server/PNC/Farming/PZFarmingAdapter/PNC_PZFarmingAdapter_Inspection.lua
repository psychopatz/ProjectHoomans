-- Farming plot validation and inspection.

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

function Adapter.ValidatePlotRegion(component)
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local foundFurrow = false
    local ok, reason = eachTile(component, function(x, y, z)
        if not squareAt(x, y, z) then
            return false, "WORLD_SQUARE_UNLOADED"
        end
        local plant = Adapter.GetPlantAt(x, y, z)
        if plant and tostring(plant.state or "") == "plow" then
            foundFurrow = true
        end
        return true
    end)
    if not ok then return false, reason end
    return foundFurrow, foundFurrow and nil or "FARMING_FURROW_REQUIRED"
end

local function cropState(plant)
    return tostring(plant and plant.state or "")
end

function Adapter.InspectPlot(component)
    local result = {
        available = true, status = "WAITING_FOR_CROP_STATE", tileCount = 0,
        furrows = 0, empty = 0, planted = 0, harvestable = 0,
        needsWater = 0, blocked = 0, tiles = {},
    }
    if not farmingSystem() then
        result.available, result.status = false, "WAITING_FOR_WORLD"
        return result
    end
    local ok, reason = eachTile(component, function(x, y, z)
        local square = squareAt(x, y, z)
        if not square then
            result.available, result.status = false, "WAITING_FOR_WORLD"
            return false, reason or "WORLD_SQUARE_UNLOADED"
        end
        local plant = Adapter.GetPlantAt(x, y, z)
        local state = cropState(plant)
        local tile = { x = x, y = y, z = z, state = state,
            typeOfSeed = plant and plant.typeOfSeed or nil }
        result.tileCount = result.tileCount + 1
        if not plant then
            result.blocked = result.blocked + 1
            tile.status = "NOT_FURROW"
        elseif state == "plow" then
            result.furrows, result.empty = result.furrows + 1, result.empty + 1
            tile.status = "EMPTY_FURROW"
        else
            result.planted = result.planted + 1
            local alive = plant.isAlive and call(plant, "isAlive") ~= false
            if alive and plant.canHarvest and call(plant, "canHarvest") == true then
                result.harvestable = result.harvestable + 1
                tile.status = "HARVESTABLE"
            elseif alive and state == "seeded"
                and (tonumber(plant.waterLvl) or 0) < 100
            then
                result.needsWater = result.needsWater + 1
                tile.status = "NEEDS_WATER"
            else
                tile.status = "GROWING"
            end
        end
        result.tiles[#result.tiles + 1] = tile
        return true
    end)
    if not ok and result.available then
        result.available, result.status = false, reason or "WAITING_FOR_WORLD"
    end
    if result.available and result.harvestable > 0 then result.status = "HARVESTABLE"
    elseif result.available and result.needsWater > 0 then result.status = "NEEDS_WATER"
    elseif result.available and result.empty > 0 then result.status = "EMPTY_FURROW"
    elseif result.available and result.planted > 0 then result.status = "GROWING"
    end
    return result
end

Internal.CropState = cropState

return Adapter
