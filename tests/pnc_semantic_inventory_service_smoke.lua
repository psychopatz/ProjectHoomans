local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
MarketSense = {
    GetTags = function(fullType)
        if fullType == "Base.Sardines" then
            return {
                primary = "FoodSeafoodPerishable",
                category = "Food",
                tags = { "FoodSeafoodPerishable" },
                expandedTags = { "FoodSeafoodPerishable", "FoodSeafood", "Food" },
            }
        end
        return {
            primary = "FoodStaple",
            category = "Food",
            tags = { "FoodStaple" },
            expandedTags = { "FoodStaple", "Food" },
        }
    end,
    GetItemCapabilities = function(fullType)
        return { fullType = fullType, capabilities = {} }
    end,
}
PNC = {
    Semantics = {},
    Core = { IsAuthority = function() return true end },
}

local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService.lua"
)

local result, reason = Service.Query({
    id = "npc-test",
    inventory = {
        revision = 4,
        items = {
            fish = { id = "fish", type = "Base.Sardines", stack = 2 },
            soup = { id = "soup", type = "Base.Soup", stack = 1 },
        },
    },
}, {
    concept = "SEAFOOD",
    text = "seafoods",
})
T.equal(reason, "found", "MarketSense seafood query resolves")
T.equal(result.status, "found", "query reports found")
T.equal(result.totalCount, 2, "query aggregates matching stack quantity")
T.equal(result.distinctItems, 1, "query returns matching item count")
T.equal(result.items[1].fullType, "Base.Sardines",
    "query returns the concrete matching inventory item")
T.equal(result.items[1].classification.category, "food",
    "query preserves normalized MarketSense classification")

local empty, emptyReason = Service.Query({
    inventory = {
        revision = 5,
        items = { soup = { id = "soup", type = "Base.Soup", stack = 1 } },
    },
}, { concept = "SEAFOOD", text = "seafood" })
T.equal(emptyReason, "empty", "query distinguishes an empty category")
T.equal(empty.status, "empty", "empty query is safe and deterministic")

local authoritativeRecord = {
    id = "npc-authoritative",
    alive = true,
    inventory = {
        revision = 9,
        items = {
            fish = { id = "fish", type = "Base.Sardines", stack = 2 },
        },
    },
}
PNC.Registry = {
    Get = function(id)
        return tostring(id or "") == authoritativeRecord.id
            and authoritativeRecord or nil
    end,
}
local rejected = Service.HandleRequest({
    requestID = "inventory:unauthorized",
    npcID = authoritativeRecord.id,
    rawText = "Do you have seafood?",
    normalizedText = "do you have seafood",
    confidence = 0.93,
    query = { concept = "SEAFOOD", text = "seafood" },
}, { player = {}, npcID = authoritativeRecord.id })
T.equal(rejected.status, "failed",
    "network players cannot query without a conversation lease")
T.equal(rejected.reason, "conversation_token_required",
    "missing authorization stays explicit")

local payload = Service.HandleRequest({
    requestID = "inventory:1",
    npcID = authoritativeRecord.id,
    rawText = "Do you have seafood?",
    normalizedText = "do you have seafood",
    confidence = 0.93,
    query = { concept = "SEAFOOD", text = "seafood" },
}, { internal = true })
T.equal(payload.status, "found",
    "authoritative inventory ingress returns a bounded result")
T.equal(payload.requestID, "inventory:1",
    "authoritative ingress preserves request correlation")
T.equal(payload.npcID, authoritativeRecord.id,
    "authoritative ingress preserves the addressed NPC")
T.equal(payload.inventoryRevision, 9,
    "authoritative ingress includes the inventory revision")

T.finish("pnc_semantic_inventory_service_smoke")
