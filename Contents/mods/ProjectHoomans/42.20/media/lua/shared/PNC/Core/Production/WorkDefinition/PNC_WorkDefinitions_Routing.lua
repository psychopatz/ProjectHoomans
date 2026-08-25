PNC = PNC or {}
PNC.WorkDefinitions = PNC.WorkDefinitions or {}

local Definitions = PNC.WorkDefinitions

Definitions.STATION_BY_OPERATION = {
    CRAFT = "workshop",
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

function Definitions.GetStationForRecipe(recipe, operation)
    local tags = recipe and recipe.tags or {}
    for index = 1, #tags do
        local tag = string.lower(tostring(tags[index] or ""))
        local compactTag = string.gsub(tag, "[^%w]", "")
        local stationId = Definitions.STATION_BY_TAG[tag]
            or Definitions.STATION_BY_TAG[compactTag]
        if stationId and Definitions.STATIONS[stationId] then
            return Definitions.STATIONS[stationId]
        end
    end
    return Definitions.GetStation(operation)
end

return Definitions
