local T = require "tests/support/test"

T.addPackagePaths()

local function number(value, fallback)
    local converted = tonumber(value)
    if converted ~= nil then return converted end
    return tonumber(fallback)
end

PNC = {
    Inventory = {
        ResolveItemState = function(item)
            return item.itemState or {}
        end,
        DescribeLiquidContainer = function(item)
            if item.id == "near_empty" then
                return {
                    amount = 0.02,
                    capacity = 1,
                    primaryType = "Water",
                    safeWater = true,
                    canFill = true,
                    canDrink = true,
                    state = item.itemState,
                }
            end
            return {
                amount = 0,
                capacity = 1,
                primaryType = nil,
                safeWater = true,
                canFill = true,
                canDrink = false,
                state = item.itemState,
            }
        end,
    },
    ItemUtility = {
        Internal = {
            CoreInventory = {
                getItemTypeId = function() return 101 end,
            },
            Constants = { TYPE_ID = 1, QUANTITY = 2 },
            StateCodec = {},
            Number = number,
        },
        GetStatic = function(typeID, fullType)
            return {
                typeId = typeID,
                fullType = fullType,
                hunger = 0,
                thirst = 0,
                negativeThirst = 0,
                calories = 0,
                hydrationYieldPerLiter = 0.50,
                fluidHydration = false,
                fluidContainer = false,
                hydration = false,
                food = false,
                bandage = false,
                unsafe = false,
                burnt = false,
                useDelta = 0,
                maxUsedDelta = 1,
            }
        end,
    },
}

T.load("ProjectHoomans", "server",
    "PNC/Supply/ItemUtility/PNC_ItemUtility_Descriptors.lua")

local Utility = PNC.ItemUtility
local request = {
    resourceKind = "HYDRATION",
    required = { thirst = 0.01 },
}

local nearEmpty = {
    id = "near_empty",
    type = "Base.WaterBottle",
    stack = 1,
    itemState = { fluidAmount = 0.02, fluidCapacity = 1,
        fluidPrimaryType = "Water" },
}
local descriptor = Utility.DescribeNPCItem(nearEmpty)
T.truthy(descriptor, "near-empty bottle receives a descriptor")
T.truthy(descriptor.fluidHydration,
    "canonical liquid state marks a bottle as a hydration item")
T.truthy(descriptor.hydration,
    "a safe near-empty bottle remains drinkable")
T.near(descriptor.fluidAmount, 0.02, 0.000001,
    "canonical liquid amount overrides stale static state")
T.near(descriptor.thirst, 0.01, 0.000001,
    "hydration yield uses the canonical live amount")
T.truthy(Utility.Supports(descriptor, request),
    "consumption accepts the same near-empty bottle selected by planning")

local empty = {
    id = "empty",
    type = "Base.WaterBottle",
    stack = 1,
    itemState = { fluidAmount = 0, fluidCapacity = 1 },
}
local emptyDescriptor = Utility.DescribeNPCItem(empty)
T.falsy(emptyDescriptor.hydration,
    "empty bottle is not accepted as a drink")
T.falsy(Utility.Supports(emptyDescriptor, request),
    "empty bottle is rejected so refill can be selected")

T.finish("pnc_item_utility_hydration_smoke")
