-- Per-tile planting, watering, and harvesting.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}
local Adapter = PNC.PZFarmingAdapter
local Internal = Adapter.Internal
local Catalog = PNC.FarmingCatalog
local call = Internal.Call
local farmingSystem = Internal.FarmingSystem
local cropState = Internal.CropState
local nativeBody = Internal.NativeBody
local farmingSkill = Internal.FarmingSkill

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

return Adapter
