if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}

local Adapter = PNC.PZFarmingAdapter
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function farmingSystem()
    return SFarmingSystem and SFarmingSystem.instance or nil
end

local function squareAt(x, y, z)
    local cell = getCell and getCell() or nil
    return cell and cell.getGridSquare
        and cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
        or nil
end

function Adapter.GetPlantAt(x, y, z)
    local system = farmingSystem()
    if not system or type(system.getLuaObjectAt) ~= "function" then
        return nil, "FARMING_SYSTEM_UNAVAILABLE"
    end
    local ok, plant = pcall(system.getLuaObjectAt, system,
        math.floor(x), math.floor(y), math.floor(z))
    if not ok then return nil, "FARMING_LOOKUP_FAILED" end
    return plant
end

local function eachTile(component, visitor)
    local valid, reason, info = Farming.RectangleInfo(component and component.region)
    if not valid then return false, reason end
    for y = info.minY, info.maxY do
        for x = info.minX, info.maxX do
            local ok, value = visitor(x, y, info.z)
            if ok == false then return false, value end
        end
    end
    return true
end

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

local function visitNativeInventory(container, visitor, visited)
    if not container or (visited and visited[container]) then return nil end
    visited = visited or {}
    visited[container] = true
    local items = call(container, "getItems")
    if not items or not items.size or not items.get then return nil end
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local value = visitor(item, container)
        if value ~= nil then return value end
        local nested = call(item, "getItemContainer")
        value = visitNativeInventory(nested, visitor, visited)
        if value ~= nil then return value end
    end
    return nil
end

local function nativeBody(record, body)
    return body or PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record and record.id) or nil
end

function Adapter.FindSeed(record, body, entry)
    body = nativeBody(record, body)
    if body and PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    local inv = PNC.Inventory and PNC.Inventory.EnsureRecordInventory
        and PNC.Inventory.EnsureRecordInventory(record) or nil
    for id, item in pairs(inv and inv.items or {}) do
        for _, seedType in ipairs(entry and entry.seedTypes or {}) do
            if tostring(item.type or "") == tostring(seedType)
                and (tonumber(item.stack) or 0) > 0
            then
                return tostring(id), item
            end
        end
    end
    return nil, "SEED_MATERIAL_MISSING"
end

local function isWaterNative(item)
    if not item then return false end
    if call(item, "isWaterSource") == true then return true end
    local container = call(item, "getFluidContainer")
    if not container or call(container, "isEmpty") == true then return false end
    local primary = call(container, "getPrimaryFluid")
    local fluidType = tostring(call(primary, "getFluidTypeString") or "")
    return (fluidType == "Water" or fluidType == "TaintedWater")
        and (tonumber(call(container, "getAmount")) or 0) > 0
end

Adapter.IsWaterItem = isWaterNative

function Adapter.FindWater(record, body)
    body = nativeBody(record, body)
    local inventory = body and call(body, "getInventory") or nil
    return visitNativeInventory(inventory, function(item, container)
        if isWaterNative(item) then return { item = item, container = container } end
    end)
end

local function farmingSkill(body)
    if not body or not body.getPerkLevel or not Perks or not Perks.Farming then return 0 end
    return tonumber(call(body, "getPerkLevel", Perks.Farming)) or 0
end

function Adapter.Plant(record, body, component, tile, desiredCrop)
    body = nativeBody(record, body)
    if not body then return false, "WAITING_FOR_WORLD" end
    local plant = Adapter.GetPlantAt(tile.x, tile.y, tile.z)
    if not plant or cropState(plant) ~= "plow" then return false, "FURROW_NOT_PLANTABLE" end
    local entry, reason = Catalog.Resolve(desiredCrop)
    if not entry then return false, reason end
    if PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    local itemID = Adapter.FindSeed(record, body, entry)
    if not itemID then return false, "SEED_MATERIAL_MISSING" end
    local seedType = entry.seedTypes[1]
    if not PNC.SupplyInventory or not PNC.SupplyInventory.RemoveCoreItemIds
        or not PNC.SupplyInventory.RemoveCoreItemIds(record, { itemID },
            "farming_seed")
    then return false, "SEED_MATERIAL_REMOVE_FAILED" end
    local ok = pcall(plant.seed, plant, seedType, farmingSkill(body))
    if not ok then return false, "VANILLA_PLANT_FAILED" end
    if PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    return true, "PLANTED"
end

function Adapter.Water(record, body, tile)
    body = nativeBody(record, body)
    if not body then return false, "WAITING_FOR_WORLD" end
    local plant = Adapter.GetPlantAt(tile.x, tile.y, tile.z)
    if not plant or cropState(plant) ~= "seeded"
        or (tonumber(plant.waterLvl) or 0) >= 100
    then return false, "PLANT_DOES_NOT_NEED_WATER" end
    local water = Adapter.FindWater(record, body)
    if not water then return false, "WATER_MATERIAL_MISSING" end
    local item, container = water.item, water.container
    local used = false
    local fluid = call(item, "getFluidContainer")
    if fluid and (tonumber(call(fluid, "getAmount")) or 0) > 0
        and type(fluid.adjustAmount) == "function"
    then
        local perUse = ZomboidGlobals
            and tonumber(ZomboidGlobals.farmingFluidContainerMillilitresPerUse)
            or 250
        local amount = tonumber(call(fluid, "getAmount")) or 0
        if amount >= perUse / 1000 then
            pcall(fluid.adjustAmount, fluid, amount - perUse / 1000)
            if type(item.syncItemFields) == "function" then
                pcall(item.syncItemFields, item)
            end
            used = true
        end
    elseif type(item.UseAndSync) == "function" then
        used = pcall(item.UseAndSync, item)
    elseif type(item.Use) == "function" then
        used = pcall(item.Use, item)
    end
    if not used then return false, "WATER_MATERIAL_CONSUME_FAILED" end
    local ok = pcall(plant.water, plant, nil, 1)
    if not ok then return false, "VANILLA_WATER_FAILED" end
    if PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    return true, "WATERED"
end

function Adapter.Harvest(record, body, tile)
    body = nativeBody(record, body)
    if not body then return false, "WAITING_FOR_WORLD" end
    local plant = Adapter.GetPlantAt(tile.x, tile.y, tile.z)
    if not plant or not plant.canHarvest or call(plant, "canHarvest") ~= true then
        return false, "PLANT_NOT_HARVESTABLE"
    end
    local system = farmingSystem()
    if not system or type(system.harvest) ~= "function" then
        return false, "FARMING_SYSTEM_UNAVAILABLE"
    end
    local ok = pcall(system.harvest, system, plant, body)
    if not ok then return false, "VANILLA_HARVEST_FAILED" end
    if PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    return true, "HARVESTED"
end

return Adapter
