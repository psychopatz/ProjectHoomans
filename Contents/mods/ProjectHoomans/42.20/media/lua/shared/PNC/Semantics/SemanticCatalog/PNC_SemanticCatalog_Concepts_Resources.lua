-- Resource and general-use item taxonomy concepts.
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

function Internal.RegisterResourcesConcepts()
    registerConcept("RESOURCE", {
        "resource", "resources", "material", "materials",
    }, 3)
    registerConcept("MEDICINE", {
        "medicine", "medicines", "meds", "medical supplies", "first aid",
    }, 3)
    registerConcept("BANDAGE", { "bandage", "bandages" }, 4)
    registerConcept("LITERATURE", {
        "literature", "book", "books", "magazine", "magazines",
    }, 3)
    registerConcept("ELECTRONICS", {
        "electronics", "electronic items",
    }, 3)
    registerConcept("BUILDING", {
        "building", "buildings", "building items", "building supplies",
    }, 3)
end

return Internal

