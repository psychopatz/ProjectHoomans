-- Utility, material, and specialty item taxonomy concepts.
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

function Internal.RegisterUtilitiesConcepts()
    registerConcept("RADIO", { "radio", "radios", "walkie talkie" }, 4)
    registerConcept("BATTERY", { "battery", "batteries" }, 4)
    registerConcept("GENERATOR", { "generator", "generators" }, 4)
    registerConcept("FLASHLIGHT", { "flashlight", "flashlights" }, 4)
    registerConcept("SKILL_BOOK", { "skill book", "skill books" }, 4)
    registerConcept("FERTILIZER", { "fertilizer", "fertilizers" }, 3)
    registerConcept("COMPOST", { "compost" }, 3)
    registerConcept("WOOD", { "wood", "lumber" }, 3)
    registerConcept("METAL", { "metal", "metals" }, 3)
    registerConcept("PAPER", { "paper" }, 3)
    registerConcept("BAKING_SUPPLY", {
        "baking supplies", "baking ingredients", "baked goods",
    }, 3)
    registerConcept("CANDY", { "candy", "candies", "sweets" }, 3)
    registerConcept("CHEESE", { "cheese", "cheeses" }, 3)
    registerConcept("EGG", { "egg", "eggs" }, 3)
    registerConcept("HERB", { "herb", "herbs" }, 3)
    registerConcept("MUSHROOM", { "mushroom", "mushrooms" }, 3)
    registerConcept("NUT", { "nut", "nuts" }, 3)
    registerConcept("PET_FOOD", { "pet food", "animal food" }, 3)
    registerConcept("PRESERVED_FOOD", {
        "preserved food", "canned food", "canned goods",
    }, 3)
    registerConcept("SNACK", { "snack", "snacks" }, 3)
    registerConcept("SPICE", { "spice", "spices", "seasoning" }, 3)
end

return Internal

