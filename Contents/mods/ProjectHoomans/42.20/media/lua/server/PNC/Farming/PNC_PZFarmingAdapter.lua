if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}

local Adapter = PNC.PZFarmingAdapter
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local Research = PNC.FarmingResearch

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    return fn(object, ...)
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
    return system:getLuaObjectAt(math.floor(x), math.floor(y), math.floor(z))
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
    local cropType = tostring(entry.typeOfSeed or "")
    local props = farming_vegetableconf and farming_vegetableconf.props or nil
    if cropType == "" or type(props) ~= "table"
        or type(props[cropType]) ~= "table"
    then
        return false, "VANILLA_CROP_DEFINITION_MISSING"
    end
    if type(plant.seed) ~= "function" then
        return false, "VANILLA_PLANT_UNAVAILABLE"
    end
    if PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    local itemID = Adapter.FindSeed(record, body, entry)
    if not itemID then return false, "SEED_MATERIAL_MISSING" end
    if not PNC.SupplyInventory or not PNC.SupplyInventory.RemoveCoreItemIds
        or not PNC.SupplyInventory.RemoveCoreItemIds(record, { itemID },
            "farming_seed")
    then return false, "SEED_MATERIAL_REMOVE_FAILED" end
    -- Vanilla expects the farming_vegetableconf key here ("Cabbages"),
    -- while entry.seedTypes contains the inventory item ("Base.CabbageSeed").
    plant:seed(cropType, farmingSkill(body))
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
    if type(plant.water) ~= "function" then
        return false, "VANILLA_WATER_UNAVAILABLE"
    end
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
            fluid:adjustAmount(amount - perUse / 1000)
            if type(item.syncItemFields) == "function" then
                item:syncItemFields()
            end
            used = true
        end
    elseif type(item.UseAndSync) == "function" then
        item:UseAndSync()
        used = true
    elseif type(item.Use) == "function" then
        item:Use()
        used = true
    end
    if not used then return false, "WATER_MATERIAL_CONSUME_FAILED" end
    plant:water(nil, 1)
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
    system:harvest(plant, body)
    if PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        PNC.Inventory.CaptureLooseInventory(record, body)
    end
    return true, "HARVESTED"
end

local function savePlant(plant)
    if type(plant.saveData) ~= "function" then
        return false, "VANILLA_PLANT_SAVE_UNAVAILABLE"
    end
    plant:saveData()
    return true
end

local function alivePlant(plant)
    return plant and type(plant.isAlive) == "function"
        and plant:isAlive() ~= false
end

local function applyPlantEffect(plant, effect, body)
    if not alivePlant(plant) then return false, "PLANT_NOT_READY" end
    if effect == "boost_yield" then
        plant.bonusYield = true
        return savePlant(plant)
    elseif effect == "fertilize" then
        if type(plant.fertilize) ~= "function" then
            return false, "VANILLA_FERTILIZER_UNAVAILABLE"
        end
        -- Compost uses vanilla's safe fertilizer path and is persistent in
        -- SPlantGlobalObject, making this a good debug stand-in for future
        -- fertilizer items and research modifiers.
        plant:fertilize({ skill = farmingSkill(body), compost = true })
        return true
    elseif effect == "gmo_upgrade" then
        -- These are all vanilla persisted fields.  Keeping the debug upgrade
        -- on vanilla state means later research can replace this with a
        -- calculated modifier without inventing a second plant authority.
        plant.bonusYield = true
        plant.cursed = false
        plant.hasWeeds = false
        plant.compost = true
        plant.health = math.max(tonumber(plant.health) or 0, 100)
        return savePlant(plant)
    end
    return false, "UNKNOWN_FARMING_RESEARCH_EFFECT"
end

function Adapter.ApplyResearchEffect(component, effect, body)
    local normalized = Research and Research.NormalizeEffect
        and Research.NormalizeEffect(effect) or nil
    if not normalized then return false, "UNKNOWN_FARMING_RESEARCH_EFFECT" end
    if normalized == "fast_growth" then
        return Adapter.ForceGrowPlot(component)
    end
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local ready, reason = validateLoadedPlot(component)
    if not ready then return false, reason end
    local applied = 0
    local ok, failure = eachTile(component, function(x, y, z)
        local plant = Adapter.GetPlantAt(x, y, z)
        if plant and cropState(plant) ~= "plow" then
            local changed, changeReason = applyPlantEffect(plant, normalized, body)
            if not changed then
                if changeReason ~= "PLANT_NOT_READY" then
                    return false, changeReason
                end
            else
                applied = applied + 1
            end
        end
        return true
    end)
    if not ok then return false, failure end
    if applied <= 0 then return false, "NO_PLANTS_AVAILABLE" end
    local resultReason = {
        boost_yield = "YIELD_BOOSTED",
        fertilize = "FERTILIZER_APPLIED",
        gmo_upgrade = "GMO_UPGRADE_APPLIED",
    }
    return true, resultReason[normalized], {
        applied = applied, effect = normalized,
    }
end

return Adapter
