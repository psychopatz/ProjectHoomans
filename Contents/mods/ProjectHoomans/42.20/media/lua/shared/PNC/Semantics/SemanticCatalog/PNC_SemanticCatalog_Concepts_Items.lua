-- Item taxonomy and first-person need-state concepts.
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

function Internal.RegisterItemConcepts()
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
    registerConcept("HUNGER", {
        "hungry", "starving", "famished",
    }, 5)
    registerConcept("THIRST", { "thirsty", "parched" }, 5)
    registerConcept("FATIGUE", {
        "tired", "exhausted", "sleepy", "worn out",
    }, 5)
end

return Internal
