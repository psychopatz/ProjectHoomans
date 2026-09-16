local T = require "tests/support/test"
T.addPackagePaths()

MarketSense = {
    GetTags = function(fullType)
        if fullType == "Base.Apple" then
            return {
                primary = "FOOD",
                category = "FRUIT",
                tags = { "APPLE", "EDIBLE" },
                expandedTags = { "Food.Fruit" },
                themes = { "survival" },
            }
        end
        return { primary = "TOOL", category = "HAND" }
    end,
    GetItemCapabilities = function(fullType)
        return {
            fullType = fullType,
            capabilities = {
                edible = fullType == "Base.Apple",
                sharp = fullType == "Base.Knife",
            },
        }
    end,
}

PNC = { Semantics = {} }
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/Inventory/PNC_SemanticItemSelector.lua"
)
local Selector = PNC.Semantics.ItemSelector
local record = {
    inventory = {
        items = {
            appleB = { id = "appleB", type = "Base.Apple", stack = 1 },
            knifeA = { id = "knifeA", type = "Base.Knife", stack = 1 },
            locked = {
                id = "locked", type = "Base.Apple", stack = 1,
                interactionLocked = true,
            },
        },
    },
}

local selected, reason = Selector.Find(record, {
    tags = { "apple" },
    capabilities = { "edible" },
    quantity = 1,
})
T.truthy(selected, "MarketSense tags select the apple")
T.equal(reason, "matched", "tag selection returns a stable result")
T.equal(selected.itemID, "appleB", "locked items are not selected")
T.equal(selected.fullType, "Base.Apple", "fullType is primitive")
T.equal(record.inventory.items.appleB.stack, 1,
    "selection does not mutate inventory")

local exact, exactReason = Selector.Find(record, {
    fullType = "Base.Knife",
})
T.equal(exactReason, "matched", "exact selection does not need a tag")
T.equal(exact.itemID, "knifeA", "exact fullType selects the knife")

local named, namedReason = Selector.Find(record, {
    text = "apples",
})
T.equal(namedReason, "matched", "item text matching accepts plurals")
T.equal(named.itemID, "appleB",
    "item text matching uses the authoritative full type")

local typo, typoReason = Selector.Find(record, {
    text = "aple",
})
T.equal(typoReason, "matched", "bounded item typo matching is local")
T.equal(typo.itemID, "appleB",
    "item typo matching resolves against the full type")

MarketSense.GetItemCapabilities = nil
Selector.ClearCache()
local tagsWithoutCapabilities, tagsWithoutCapabilitiesReason = Selector.Find(
    record, { tags = { "apple" } })
T.equal(tagsWithoutCapabilitiesReason, "matched",
    "MarketSense tag queries do not require capability classification")
T.equal(tagsWithoutCapabilities.itemID, "appleB",
    "tag queries remain usable with the optional capability API absent")

MarketSense = nil
Selector.ClearCache()
local unavailable, unavailableReason = Selector.Find(record, {
    tags = { "apple" },
})
T.falsy(unavailable, "tag selection is not guessed without MarketSense")
T.equal(unavailableReason, "classification_unavailable",
    "missing classification is observable to the caller")
local exactWithoutMarketSense, exactWithoutReason = Selector.Find(record, {
    fullType = "Base.Apple",
})
T.equal(exactWithoutReason, "matched",
    "exact selection remains local without MarketSense")
T.equal(exactWithoutMarketSense.itemID, "appleB",
    "exact selection still identifies the item")

T.finish("pnc_semantic_item_selector_smoke")
