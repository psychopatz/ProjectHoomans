-- Project Hoomans speech acts, concepts, and domain vocabulary.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerConcept = Internal.RegisterConcept
local registerSpeechAct = Internal.RegisterSpeechAct
if type(registerConcept) ~= "function"
    or type(registerSpeechAct) ~= "function"
then
    error("semantic catalog concepts require registration adapters")
end

local CampSite = PNC.Semantics.CampSite
if type(CampSite) ~= "table" or type(CampSite.RoomTypesList) ~= "function" then
    error("semantic catalog concepts require camp-site room definitions")
end

function Internal.RegisterVocabulary()
    registerSpeechAct("REQUEST")
    registerSpeechAct("OFFER")
    registerSpeechAct("ACCEPT")
    registerSpeechAct("REFUSE")
    registerSpeechAct("QUESTION")
    registerSpeechAct("ANSWER")
    registerSpeechAct("INFORM")
    registerSpeechAct("WARN")
    registerSpeechAct("GREET")
    registerSpeechAct("FAREWELL")
    registerSpeechAct("AGREE")
    registerSpeechAct("DISAGREE")
    registerSpeechAct("ACKNOWLEDGE")
    registerSpeechAct("APOLOGIZE")
    registerSpeechAct("THANK")
    registerSpeechAct("COMPLAIN")
    registerSpeechAct("THREATEN")
    registerSpeechAct("PROMISE")
    registerSpeechAct("ASK_FOR_CLARIFICATION")
    registerSpeechAct("CLARIFY")
    registerSpeechAct("GOSSIP")

    registerConcept(
        "FOLLOW",
        { "follow", "follow me", "come with me", "come along" }
    )
    registerConcept("STOP", { "stop", "halt" })
    registerConcept("WAIT", {
        "wait", "stay", "wait here", "stay here", "stay right here",
    })
    registerConcept("CAMP", { "camp", "camping" })
    registerConcept("CAMP_PREP", { "at", "in", "inside", "by", "near" })
    registerConcept("CAMPFIRE", {
        "campfire", "fire pit", "firepit", "fire",
    })
    for _, roomDefinition in ipairs(CampSite.RoomTypesList()) do
        registerConcept("ROOM_" .. tostring(roomDefinition.id),
            roomDefinition.aliases, 2)
    end
    registerConcept("GO", { "go", "head", "travel" })
    registerConcept("HOME", { "home" })
    registerConcept("FETCH", { "bring", "get", "fetch", "grab" })
    registerConcept("GIVE", { "give", "hand", "pass" })
    registerConcept("HAVE", { "have", "got", "carry", "carrying" })
    registerConcept("ANY_ITEM", {
        "anything", "something", "item", "items", "thing", "things",
        "stuff",
    }, 5)
    registerConcept("WANT", { "want", "wants", "need", "needs" })
    registerConcept("GIFT", { "gift", "present" }, 3)
    registerConcept("HEAR", { "hear", "heard" })
    registerConcept("BITTEN", { "bitten", "got bitten", "was bitten" })
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
    registerConcept("HELP", { "help" })
    registerConcept("TAKE", { "take" })
    registerConcept("THANK", { "thanks", "thank you" })
    registerConcept("APOLOGIZE", { "sorry", "i am sorry", "apologies" })
    registerConcept("ACCEPT", {
        "yes", "yeah", "yep", "yup", "sure", "okay", "ok",
        "yes please", "yeah please", "of course", "sure thing",
        "go ahead", "please do", "you can have it",
    })
    registerConcept("REFUSE", {
        "no", "nope", "nah", "no thanks", "not now", "keep it",
        "leave it",
    })
    registerConcept("AGREE", {
        "i agree", "sounds good", "that sounds good", "that works",
        "works for me", "all right", "fine by me",
    })
    -- Acknowledgment confirms that the player heard the NPC. Keep it separate
    -- from ACCEPT and AGREE so it cannot authorize a pending gift.
    registerConcept("ACKNOWLEDGE", {
        "i understand", "i understand what you mean", "i hear you",
        "i see what you mean", "understood",
    }, 3)
    registerConcept("DISAGREE", {
        "i disagree", "i don't agree", "i do not agree", "not really",
        "not this time", "that doesn't work", "that does not work",
        "i'd rather not",
    })
    registerConcept("GREET", {
        "hello", "hello there", "hi", "hi there", "hey", "hey there",
        "good morning", "good afternoon", "good evening",
    })
    registerConcept("TIME", {
        "time", "what time is it", "what day is it", "today", "date",
        "morning", "afternoon", "evening", "night",
    })
    -- Keep calendar-date questions distinct from clock questions. The
    -- higher-priority concept wins when both concepts share an alias such as
    -- "what day is it", allowing the response layer to use the same world
    -- snapshot without adding a sentence-specific parser branch.
    registerConcept("DAY", {
        "what day is it", "what day", "what is the date",
        "what's the date", "what date is it", "today's date",
    }, 5)
    registerConcept("WEATHER", {
        "weather", "what is the weather", "is it raining", "raining",
        "rain", "fog", "foggy", "mist", "temperature",
    })
    registerConcept("IDENTITY", {
        "name", "who are you", "what is your name", "what's your name",
    })

end

return Internal
