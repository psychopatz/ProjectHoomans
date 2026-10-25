-- Core food and drink concepts.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog concept module requires Catalog.Internal")
end

local registerConcept = Internal.RegisterConcept
if type(registerConcept) ~= "function"
then
    error("semantic catalog concept module requires registration adapters")
end

function Internal.RegisterBasicFoodConcepts()
    registerConcept("WATER", {
        "water", "drinking water",
    })
    registerConcept("BEVERAGE", {
        "beverage", "beverages", "drinks", "something to drink",
    }, 4)
    registerConcept("FOOD", {
        "food", "foods", "something to eat", "meal", "rations",
        "foodstuff", "foodstuffs", "food stuff", "food stuffs",
    })
    registerConcept("SEAFOOD", {
        "seafood", "sea foods", "seafoods", "seafood stuff",
        "seafood stuffs", "fish", "shellfish",
    }, 4)
end

return Internal

