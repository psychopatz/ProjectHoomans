-- Specialized supplies and equipment taxonomy concepts.
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

function Internal.RegisterSpecializedSuppliesConcepts()
    registerConcept("GARDENING", {
        "gardening", "garden supplies", "gardening supplies",
    }, 3)
    registerConcept("COOKING_SUPPLY", {
        "cooking supplies", "cooking tools", "cooking utensils",
        "kitchen utensils",
    }, 3)
    registerConcept("SMOKING_SUPPLY", {
        "smoking supplies", "cigarette", "cigarettes", "tobacco",
    }, 3)
    registerConcept("MELEE_WEAPON", {
        "melee weapon", "melee weapons",
    }, 4)
    registerConcept("EXPLOSIVE", {
        "explosive", "explosives", "grenade", "grenades",
    }, 4)
    registerConcept("WEAPON_PART", {
        "weapon part", "weapon parts", "gun part", "gun parts",
    }, 3)
    registerConcept("PROTECTIVE_GEAR", {
        "protective gear", "protective equipment", "armor", "armour",
        "helmet", "helmets",
    }, 4)
    registerConcept("ACCESSORY", {
        "accessory", "accessories", "jewelry", "jewellery",
    }, 3)
    registerConcept("GARDENING_TOOL", {
        "garden tool", "garden tools", "gardening tool", "gardening tools",
    }, 3)
    registerConcept("CARPENTRY_TOOL", {
        "carpentry tool", "carpentry tools", "woodworking tool",
        "woodworking tools",
    }, 3)
    registerConcept("MECHANICS_TOOL", {
        "mechanic tool", "mechanic tools", "mechanics tool",
        "mechanics tools",
    }, 3)
    registerConcept("FISHING_TOOL", {
        "fishing gear", "fishing equipment", "fishing tool", "fishing tools",
    }, 3)
    registerConcept("BUILDING_FURNITURE", {
        "furniture", "furniture items",
    }, 3)
end

return Internal

