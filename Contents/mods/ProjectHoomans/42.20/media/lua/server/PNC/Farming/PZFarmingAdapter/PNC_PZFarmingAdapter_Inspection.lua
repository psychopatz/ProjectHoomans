-- Farming plot/zone validation, arable tile checks, and inspection.

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

local function isArableFloor(floor)
    if not floor then return false, "FLOOR_MISSING" end
    local sprite = call(floor, "getSprite")
    local props = sprite and call(sprite, "getProperties") or nil
    if props and type(props.Is) == "function" then
        if call(props, "Is", "GrassFloor") == true
            or call(props, "Is", "Dirt") == true
            or call(props, "Is", "Soil") == true
            or call(props, "Is", "Sand") == true
        then
            return true, "CAN_PLOW"
        end
    end
    local name = tostring(
        (sprite and call(sprite, "getName"))
        or call(floor, "getSpriteName")
        or call(floor, "getTextureName")
        or ""
    )
    if name == "" then return true, "CAN_PLOW" end
    local lower = string.lower(name)
    if string.find(lower, "blends_natural", 1, true)
        or string.find(lower, "natural", 1, true)
        or string.find(lower, "dirt", 1, true)
        or string.find(lower, "grass", 1, true)
        or string.find(lower, "soil", 1, true)
        or string.find(lower, "mud", 1, true)
    then
        return true, "CAN_PLOW"
    end
    return false, "SQUARE_NOT_ARABLE"
end

---Returns true when an unloaded/unplanted square can be plowed into a furrow.
function Adapter.CanPlowSquare(square)
    if not square then return false, "WORLD_SQUARE_UNLOADED" end
    if square.canPlow ~= nil then
        return square.canPlow == true,
            square.canPlow == true and "CAN_PLOW" or "SQUARE_NOT_ARABLE"
    end
    if square.blocked == true then return false, "SQUARE_BLOCKED" end
    if type(square.getX) == "function" then
        local existing = Adapter.GetPlantAt(
            square:getX(), square:getY(), square:getZ())
        if existing then return false, "ALREADY_FURROW" end
    end
    if type(square.Is) == "function" and IsoFlagType then
        if IsoFlagType.water and call(square, "Is", IsoFlagType.water) == true then
            return false, "SQUARE_WATER"
        end
        if (IsoFlagType.solid and call(square, "Is", IsoFlagType.solid) == true)
            or (IsoFlagType.solidtrans
                and call(square, "Is", IsoFlagType.solidtrans) == true)
        then
            return false, "SQUARE_BLOCKED"
        end
    end
    if type(square.getFloor) == "function" then
        return isArableFloor(call(square, "getFloor"))
    end
    return true, "CAN_PLOW"
end

---Validates that a farming plot or zone has loaded tiles with at least one furrow or plowable tile.
function Adapter.ValidatePlotRegion(component)
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local foundWorkable = false
    local ok, reason = eachTile(component, function(x, y, z)
        local square = squareAt(x, y, z)
        if not square then return false, "WORLD_SQUARE_UNLOADED" end
        local plant = Adapter.GetPlantAt(x, y, z)
        if plant and tostring(plant.state or "") == "plow" then
            foundWorkable = true
        elseif not plant and Adapter.CanPlowSquare(square) then
            foundWorkable = true
        end
        return true
    end)
    if not ok then return false, reason end
    return foundWorkable, foundWorkable and nil or "FARMING_FURROW_REQUIRED"
end

local function cropState(plant)
    return tostring(plant and plant.state or "")
end

---Inspects a farming plot or zone, classifying NEEDS_PLOW, EMPTY_FURROW, NEEDS_WATER, HARVESTABLE, and GROWING tiles.
function Adapter.InspectPlot(component, opts)
    local policy = PNC.Farming and PNC.Farming.NormalizePolicy
        and PNC.Farming.NormalizePolicy(
            (opts and opts.policy) or (component and component.policy))
        or { autoPlow = true }
    local result = {
        available = true, status = "WAITING_FOR_CROP_STATE", tileCount = 0,
        furrows = 0, empty = 0, needsSeed = 0, needsPlow = 0,
        planted = 0, harvestable = 0, needsWater = 0, blocked = 0, tiles = {},
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
            local canPlow, plowReason = Adapter.CanPlowSquare(square)
            if canPlow and policy.autoPlow ~= false then
                result.needsPlow = result.needsPlow + 1
                tile.status = "NEEDS_PLOW"
            else
                result.blocked = result.blocked + 1
                tile.status = "NOT_FURROW"
                tile.reason = plowReason
            end
        elseif state == "plow" then
            result.furrows = result.furrows + 1
            result.empty = result.empty + 1
            result.needsSeed = result.needsSeed + 1
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
    result.hasActionable = result.available and (
        result.harvestable > 0 or result.needsWater > 0
        or result.empty > 0 or result.needsPlow > 0
    ) or false
    if result.available and result.harvestable > 0 then result.status = "HARVESTABLE"
    elseif result.available and result.needsWater > 0 then result.status = "NEEDS_WATER"
    elseif result.available and result.empty > 0 then result.status = "EMPTY_FURROW"
    elseif result.available and result.needsPlow > 0 then result.status = "NEEDS_PLOW"
    elseif result.available and result.planted > 0 then result.status = "GROWING"
    end
    return result
end

---Inspects a designated farming zone using InspectPlot rules.
function Adapter.InspectZone(zone, opts)
    return Adapter.InspectPlot(zone, opts)
end

Internal.CropState = cropState

return Adapter
