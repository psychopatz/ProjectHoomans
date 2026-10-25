-- Open inventory question registrations.
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

function Internal.RegisterInventoryOpenQueries()
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

