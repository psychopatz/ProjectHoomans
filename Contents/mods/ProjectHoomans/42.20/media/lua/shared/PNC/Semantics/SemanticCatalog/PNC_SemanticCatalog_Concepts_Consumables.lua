-- Food, drink, fuel, and keepsake taxonomy concepts.
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

function Internal.RegisterConsumablesConcepts()
    registerConcept("FRUIT", { "fruit", "fruits" }, 4)
    registerConcept("VEGETABLE", {
        "vegetable", "vegetables", "veggies",
    }, 4)
    registerConcept("MEAT", { "meat", "meats" }, 4)
    registerConcept("COFFEE", { "coffee", "coffee beans" }, 4)
    registerConcept("TEA", { "tea", "tea leaves" }, 4)
    registerConcept("MILK", { "milk" }, 4)
    registerConcept("SODA", {
        "soda", "sodas", "soft drink", "soft drinks",
    }, 4)
    registerConcept("BEER", { "beer", "beers" }, 4)
    registerConcept("WINE", { "wine", "wines" }, 4)
    registerConcept("JUICE", { "juice", "juices" }, 4)
    registerConcept("SEED", {
        "seed", "seeds", "seed packet", "seed packets",
    }, 4)
    registerConcept("FUEL", {
        "fuel", "fuels", "gasoline", "petrol",
    }, 4)
    registerConcept("LIQUID", { "liquid", "liquids", "fluid", "fluids" }, 3)
    registerConcept("MISCELLANEOUS", {
        "misc", "miscellaneous", "misc items", "miscellaneous items",
    }, 3)
    registerConcept("MEMENTO", {
        "memento", "mementos", "keepsake", "keepsakes", "souvenir",
        "souvenirs",
    }, 3)
end

return Internal

