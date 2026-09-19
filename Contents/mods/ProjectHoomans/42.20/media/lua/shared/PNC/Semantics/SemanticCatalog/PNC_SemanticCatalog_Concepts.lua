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
    registerConcept("WANT", { "want", "wants", "need", "needs" })
    registerConcept("GIFT", { "gift", "present" }, 3)
    registerConcept("HEAR", { "hear", "heard" })
    registerConcept("BITTEN", { "bitten", "got bitten", "was bitten" })
    registerConcept("WATER", {
        "water", "drinking water", "something to drink",
    })
    registerConcept("FOOD", {
        "food", "something to eat", "meal", "rations",
    })
    registerConcept("HUNGER", {
        "hungry", "starving", "famished",
    }, 5)
    registerConcept("SEAFOOD", {
        "seafood", "sea foods", "seafoods", "fish", "shellfish",
    }, 4)
    registerConcept("MEDICINE", {
        "medicine", "meds", "medical supplies",
    })
    registerConcept("HELP", { "help" })
    registerConcept("TAKE", { "take" })
    registerConcept("THANK", { "thanks", "thank you" })
    registerConcept("APOLOGIZE", { "sorry", "i am sorry", "apologies" })
    registerConcept("ACCEPT", { "yes", "yeah", "sure", "okay", "ok" })
    registerConcept("REFUSE", { "no", "nope" })
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
