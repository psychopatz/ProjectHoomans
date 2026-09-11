local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Inventory = { Internal = {} },
}
PNC.Inventory.Internal.countMapEntries = function(value)
    local count = 0
    for _, _ in pairs(value or {}) do count = count + 1 end
    return count
end

local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Query = require
    "PNC/Core/Colony/Storage/PNC_ColonyStorageQuery"

local foodRecord = {
    [C.TYPE_ID] = 1001,
    [C.QUANTITY] = 2,
    [C.FLAGS] = C.FLAG_CONDITION + C.FLAG_FOOD,
    [C.CODEC_ID] = C.CODEC_FOOD,
    [C.STATE] = {
        3,
        { 1, false, false, false, 24, -0.2, -0.1 },
    },
    [C.UNIT_WEIGHT] = 0.2,
}
local fluidRecord = {
    [C.TYPE_ID] = 1002,
    [C.QUANTITY] = 1,
    [C.FLAGS] = C.FLAG_FLUID,
    [C.CODEC_ID] = C.CODEC_FLUID,
    [C.STATE] = {
        {
            fluidAmount = 0.75,
            fluidCapacity = 1,
            fluidPrimaryType = "Water",
            fluids = {
                { type = "Water", amount = 0.5 },
                { type = "Bleach", amount = 0.25 },
            },
        },
    },
    [C.UNIT_WEIGHT] = 1.1,
}

local rows = Query.GetVisibleRows({ inventory = {
    records = { foodRecord, fluidRecord },
} }, {})
local foodRow
local fluidRow
for _, row in ipairs(rows) do
    if row.recordIndex == 1 then foodRow = row end
    if row.recordIndex == 2 then fluidRow = row end
end

T.truthy(foodRow and foodRow.tooltipState,
    "food storage state projection missing")
T.equal(foodRow.tooltipState.age, 1,
    "food storage age was not decoded")
T.equal(foodRow.tooltipState.condition, 3,
    "compact condition was not normalized for the tooltip")
T.equal(foodRow.tooltipState.hungChange, -0.2,
    "food storage hunger state was not decoded")
T.equal(foodRow.tooltipState.foodLastAgedHours, nil,
    "server aging checkpoint leaked into tooltip projection")

T.truthy(fluidRow and fluidRow.tooltipState,
    "fluid storage state projection missing")
T.equal(fluidRow.tooltipState.fluidAmount, 0.75,
    "fluid amount was not projected")
T.equal(#fluidRow.tooltipState.fluids, 2,
    "fluid mixture components were not projected")
T.equal(fluidRow.tooltipState.fluids[2].type, "Bleach",
    "fluid mixture component type was not preserved")

T.finish("pnc_storage_tooltip_projection_smoke")
