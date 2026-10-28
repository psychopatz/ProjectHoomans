-- Response, social acknowledgement, time, and weather concepts.
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

function Internal.RegisterDialogueConcepts()
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
    -- Keep requests for conversational continuation distinct from ACCEPT and
    -- generic open-ended captures.  The exact continuation patterns require
    -- a complete utterance, so this vocabulary cannot authorize a gameplay
    -- action or steal an item phrase such as "give me more food".
    registerConcept("MORE", {
        "more", "anything else", "what else", "go on", "continue",
        "keep going",
    }, 3)
    registerConcept("DISAGREE", {
        "i disagree", "i don't agree", "i do not agree", "not really",
        "not this time", "that doesn't work", "that does not work",
        "i'd rather not",
    })
    registerConcept("SKEPTICISM", {
        "yeah right", "as if", "sure you did", "right sure",
        "i don't believe that", "i do not believe that",
    }, 3)
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
        "weather", "what is the weather", "what's the weather",
        "is it raining", "raining",
        "rain", "fog", "foggy", "mist", "temperature",
    })
    registerConcept("IDENTITY", {
        "name", "who are you", "what is your name", "what's your name",
    })
end

return Internal
