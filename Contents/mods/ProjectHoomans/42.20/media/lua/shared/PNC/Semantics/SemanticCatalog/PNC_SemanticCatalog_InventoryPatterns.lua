-- Inventory questions produce read-only semantic item queries.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
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

local function allItemsQuery()
    return {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "INVENTORY",
        inventoryQuery = {
            mode = "LIST",
            concept = "ANY_ITEM",
            text = "items",
        },
    }
end

function Internal.RegisterInventoryQueries()
    registerPattern(
        "pnc.question.inventory_have",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "still", optional = true },
            { kind = "concept", id = "HAVE" },
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
                stopWords = { "yet", "please", "now" },
            },
            { kind = "literal", value = "yet", optional = true },
            { kind = "literal", value = "please", optional = true },
        },
        {
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
        },
        0.92,
        115,
        { allowFuzzyCapture = true }
    )

    registerPattern(
        "pnc.question.inventory_what_have",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "kind", optional = true },
            { kind = "literal", value = "of", optional = true },
            {
                kind = "any_phrase",
                capture = "itemQuery",
                minTokens = 1,
                maxTokens = 4,
                stopWords = {
                    "do", "you", "still", "have", "please", "now",
                },
            },
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "still", optional = true },
            { kind = "concept", id = "HAVE" },
        },
        {
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
        },
        0.92,
        116,
        { allowFuzzyCapture = true }
    )

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

    registerPattern(
        "pnc.question.inventory_what_do_you_have",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "still", optional = true },
            { kind = "concept", id = "HAVE" },
        },
        allItemsQuery(),
        0.96,
        120
    )

    registerPattern(
        "pnc.question.inventory_what_have_you_got",
        {
            { kind = "literal", value = "what" },
            { kind = "concept", id = "HAVE" },
            { kind = "literal", value = "you" },
            { kind = "concept", id = "HAVE" },
        },
        allItemsQuery(),
        0.96,
        121
    )
end

return Internal
