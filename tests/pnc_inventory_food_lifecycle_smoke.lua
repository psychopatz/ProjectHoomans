local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Const = {
        INVENTORY_ITEM_STATE_MAX_STRING_LENGTH = 1024,
        INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS = 64,
        INVENTORY_OPLOG_MAX = 16,
    },
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, entry in pairs(value) do
                output[key] = PNC.Core.DeepCopy(entry)
            end
            return output
        end,
        LogWarn = function() end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Model.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_FoodLifecycle.lua")

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"

Inventory.EnsureRecordInventory = function(record)
    return record.inventory
end
Inventory.SyncEquipmentFromInventory = function() end
Inventory.RebuildCaches = function() end
Inventory.GetFoodProfile = function(fullType)
    if fullType == "Base.ReplacementFood" then
        return {
            food = true, offAge = 10, offAgeMax = 20,
            foodRotSpeed = 1,
        }
    end
    return {
        food = true, offAge = 1, offAgeMax = 2,
        foodRotSpeed = 1,
    }
end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/PNC_Inventory_Mutations_Delta.lua")
T.load("ProjectHoomans", "server", "PNC/Supply/PNC_ItemUtility.lua")

local function record(item)
    return {
        inventory = {
            revision = 0, persistenceMode = "FULL",
            equipped = { primary = nil, secondary = nil, bag = nil },
            worn = {}, attached = {},
            items = { [item.id] = item },
            containers = { root = { items = { item.id } } },
        },
        runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
    }
end

local stale = record({
    id = "stale", type = "Base.Apple", stack = 1,
    cond = 7, uses = 0.5, itemState = { age = 0, frozen = false },
})
T.truthy(Inventory.AdvanceFoodLifecycle(stale, 0,
    { foodRotSpeed = 1, removalDays = -1 }),
    "first food touch initializes checkpoint")
T.equal(stale.inventory.items.stale.itemState.foodLastAgedHours, 0,
    "food checkpoint persisted")
T.truthy(Inventory.AdvanceFoodLifecycle(stale, 24,
    { foodRotSpeed = 1, removalDays = -1 }),
    "food ages on demand")
T.equal(stale.inventory.items.stale.itemState.age, 1,
    "food age advances in days")
T.truthy(Inventory.AdvanceFoodLifecycle(stale, 48,
    { foodRotSpeed = 1, removalDays = -1 }),
    "food crosses rotten threshold")
T.equal(Inventory.GetFoodProfile("Base.Apple").offAgeMax, 2,
    "food profile remains available")

local frozen = record({
    id = "frozen", type = "Base.Apple", stack = 1,
    itemState = { age = 0.25, frozen = true },
})
T.truthy(Inventory.AdvanceFoodLifecycle(frozen, 0,
    { foodRotSpeed = 1, removalDays = -1 }),
    "frozen food initializes checkpoint")
T.truthy(Inventory.AdvanceFoodLifecycle(frozen, 240,
    { foodRotSpeed = 1, removalDays = -1 }),
    "frozen food checkpoint advances")
T.equal(frozen.inventory.items.frozen.itemState.age, 0.25,
    "frozen food does not rot")

local fertilized = record({
    id = "fertilized", type = "Base.Apple", stack = 1,
    itemState = { age = 3, fertilized = true },
})
T.truthy(Inventory.AdvanceFoodLifecycle(fertilized, 0,
    { foodRotSpeed = 1, removalDays = -1 }),
    "fertilized food initializes checkpoint")
T.equal(fertilized.inventory.items.fertilized.itemState.fertilized, true,
    "fertilized flag preserved")
T.equal(Inventory.GetFoodProfile("Base.Apple").offAgeMax, 2,
    "fertilized test uses food profile")

local replacement = record({
    id = "replacement", type = "Base.Apple", stack = 1,
    cond = 4, uses = 0.25,
    itemState = { age = 2, cooked = true, foodLastAgedHours = 0 },
})
Inventory.GetFoodProfile = function(fullType)
    if fullType == "Base.Apple" then
        return {
            food = true, offAge = 1, offAgeMax = 2,
            replaceOnRotten = "ReplacementFood", foodRotSpeed = 1,
        }
    end
    return { food = true, offAge = 10, offAgeMax = 20, foodRotSpeed = 1 }
end
T.truthy(Inventory.AdvanceFoodLifecycle(replacement, 0,
    { foodRotSpeed = 1, removalDays = -1 }),
    "rotten replacement applies")
T.equal(replacement.inventory.items.replacement.type,
    "Base.ReplacementFood", "replaceOnRotten keeps item identity")
T.equal(replacement.inventory.items.replacement.cond, 4,
    "replacement keeps condition")
T.equal(replacement.inventory.items.replacement.uses, 0.25,
    "replacement keeps drain state")
T.equal(replacement.inventory.items.replacement.itemState.cooked, true,
    "replacement keeps mutable food state")

local removable = record({
    id = "removable", type = "Base.Apple", stack = 1,
    itemState = { age = 2, foodLastAgedHours = 0 },
})
Inventory.GetFoodProfile = function()
    return { food = true, offAge = 1, offAgeMax = 2, foodRotSpeed = 1 }
end
T.truthy(Inventory.AdvanceFoodLifecycle(removable, 24,
    { foodRotSpeed = 1, removalDays = 0 }),
    "rotten removal applies")
T.equal(removable.inventory.items.removable, nil,
    "rotten food is removed after configured grace")

local descriptor = PNC.ItemUtility.Internal.Describe({
    food = true, hunger = 1, thirst = 0.5, negativeThirst = 0,
    offAge = 1, offAgeMax = 2, useDelta = 0,
}, { age = 0, hungChange = -0.25, thirstChange = -0.1 }, 1)
T.equal(descriptor.hunger, 0.25,
    "half-eaten food uses mutable hunger state")
T.equal(descriptor.thirst, 0.1,
    "mutable thirst state is preserved")

local generated = { age = 0, foodCreatedAtHours = 12 }
local generatedChanged = Portable.AdvanceFoodState(
    generated, { food = true, offAge = 10, offAgeMax = 20 }, 36,
    { foodRotSpeed = 1 }
)
T.truthy(generatedChanged, "generated food uses its creation anchor")
T.equal(generated.age, 1, "generated food ages from creation time")
T.equal(generated.foodCreatedAtHours, nil,
    "creation anchor is compacted after first aging")
T.equal(generated.foodLastAgedHours, 36,
    "generated food stores the new aging checkpoint")

T.finish("pnc_inventory_food_lifecycle_smoke")
