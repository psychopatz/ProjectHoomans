-- Inventory “got” question registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog inventory spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog inventory spoke requires RegisterPattern")
end

local function capturedItemQuery()
    return {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "INVENTORY",
        inventoryQuery = {
            mode = "LIST",
            item = "$capture.itemQuery",
            text = "$capture.itemQuery.text",
            concept = "$capture.itemQuery.concept",
            category = "$capture.itemQuery.category",
        },
    }
end

function Internal.RegisterInventoryGotQueries()
    registerPattern(
        "pnc.question.inventory_you_got",
        {
            { kind = "literal", value = "you" },
            { kind = "literal", value = "still", optional = true },
            { kind = "literal", value = "got" },
            { kind = "literal", value = "any", optional = true },
            { kind = "literal", value = "kind", optional = true },
            { kind = "literal", value = "of", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            {
                kind = "any_phrase",
                capture = "itemQuery",
                minTokens = 1,
                maxTokens = 4,
                stopWords = {
                    "from", "in", "inside", "on", "under", "near",
                    "with", "for", "at", "please", "now",
                },
            },
            { kind = "literal", value = "please", optional = true },
        },
        capturedItemQuery(),
        0.93,
        117,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.question.inventory_have_you_got",
        {
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "still", optional = true },
            { kind = "literal", value = "got" },
            { kind = "literal", value = "any", optional = true },
            { kind = "literal", value = "kind", optional = true },
            { kind = "literal", value = "of", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            {
                kind = "any_phrase",
                capture = "itemQuery",
                minTokens = 1,
                maxTokens = 4,
                stopWords = {
                    "from", "in", "inside", "on", "under", "near",
                    "with", "for", "at", "please", "now",
                },
            },
            { kind = "literal", value = "please", optional = true },
        },
        capturedItemQuery(),
        0.94,
        118,
        { allowFuzzyCapture = true }
    )
end

return Internal

