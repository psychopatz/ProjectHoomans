-- Equipment and weapon taxonomy concepts.
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

function Internal.RegisterEquipmentConcepts()
    registerConcept("WEAPON", { "weapon", "weapons" }, 3)
    registerConcept("FIREARM", {
        "firearm", "firearms", "gun", "guns",
    }, 4)
    registerConcept("RIFLE", { "rifle", "rifles" }, 5)
    registerConcept("HANDGUN", {
        "handgun", "handguns", "pistol", "pistols",
    }, 5)
    registerConcept("SHOTGUN", { "shotgun", "shotguns" }, 5)
    registerConcept("AMMUNITION", {
        "ammo", "ammunition", "bullet", "bullets", "rounds",
    }, 3)
    registerConcept("TOOL", { "tool", "tools" }, 3)
    registerConcept("CONTAINER", {
        "container", "containers", "bag", "bags",
    }, 3)
    registerConcept("CLOTHING", {
        "clothing", "clothes", "clothing items",
    }, 3)
end

return Internal

