PNC = PNC or {}
PNC.WorkDefinitions = PNC.WorkDefinitions or {}

local Definitions = PNC.WorkDefinitions

Definitions.STATION_BY_OPERATION = {
    -- Crafting recipes must identify a direct workstation through their
    -- native CraftRecipe tags. The generic Workshop is retained only for
    -- disassembly data from older saves.
    DISASSEMBLE = "workshop",
}

Definitions.STATION_BY_TAG = {
    primitiveforge = "primitive_forge", forge = "forge",
    advancedforge = "advanced_forge", primitivefurnace = "primitive_furnace",
    furnace = "furnace", advancedfurnace = "advanced_furnace",
    handpress = "hand_press", potterybench = "pottery_bench",
    potterywheel = "pottery_wheel", kilnsmall = "kiln_small",
    kilnlarge = "kiln_large", domekiln = "dome_kiln",
    grindstone = "grindstone", metalbandsaw = "metal_bandsaw",
    spinningwheel = "spinning_wheel", weaving = "loom",
    loom = "loom", simpleloom = "simple_loom",
    stone_mill = "stone_mill", stonemill = "stone_mill",
    stone_quern = "stone_quern", stonequern = "stone_quern",
    churnbucket = "churn_bucket", dryingrack = "drying_rack",
    dryingrackherb = "herb_drying_rack",
    simpleherbdryingrack = "herb_drying_rack",
    dryingleathersmall = "simple_drying_rack",
}

function Definitions.GetStation(operation)
    local id = Definitions.STATION_BY_OPERATION[tostring(operation or "")]
    return id and Definitions.STATIONS[id] or nil
end

local function compact(value)
    return string.gsub(string.lower(tostring(value or "")), "[^%w]", "")
end

local function stationIdFromValue(value)
    if type(value) ~= "string" then return nil end
    local raw = string.lower(value)
    local normalized = compact(raw)
    if Definitions.STATIONS[raw] then return raw end
    if Definitions.STATIONS[normalized] then return normalized end
    local id = Definitions.STATION_BY_TAG[raw]
        or Definitions.STATION_BY_TAG[normalized]
    if id and Definitions.STATIONS[id] then return id end

    -- Base and modded recipes commonly express the workstation as a tagged
    -- value such as workstation:forge or crafting_station=kiln. Strip the
    -- transport prefix, then run the same canonical alias table.
    for _, prefix in ipairs({ "craftingstation", "workstation", "station" }) do
        if string.sub(normalized, 1, #prefix) == prefix then
            local suffix = string.sub(normalized, #prefix + 1)
            id = Definitions.STATION_BY_TAG[suffix]
            if id and Definitions.STATIONS[id] then return id end
        end
    end
    return nil
end

function Definitions.GetStationIdForTags(tags)
    for index = 1, #(tags or {}) do
        local stationId = stationIdFromValue(tags[index])
        if stationId then return stationId end
    end
    return nil
end

local function explicitStationId(recipe)
    if type(recipe) ~= "table" then return nil end
    for _, field in ipairs({ "requiredStationId", "stationId",
        "workstationId", "craftingStationId", "requiredWorkstation" }) do
        local stationId = stationIdFromValue(recipe[field])
        if stationId then return stationId end
    end
    local station = recipe.requiredStation
    if type(station) == "table" then
        for _, field in ipairs({ "definitionId", "facilityId", "id" }) do
            local stationId = stationIdFromValue(station[field])
            if stationId then return stationId end
        end
    end
    return nil
end

function Definitions.GetStationIdForRecipe(recipe, operation)
    local stationId = explicitStationId(recipe)
        or Definitions.GetStationIdForTags(recipe and recipe.tags or {})
    if stationId then return stationId end
    return Definitions.STATION_BY_OPERATION[tostring(operation or "")]
end

function Definitions.GetStationForRecipe(recipe, operation)
    local stationId = Definitions.GetStationIdForRecipe(recipe, operation)
    if stationId then return Definitions.STATIONS[stationId] end
    return Definitions.GetStation(operation)
end

return Definitions
