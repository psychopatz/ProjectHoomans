PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantic.Registry
local Catalog = PNC.Semantics.Catalog or {}
PNC.Semantics.Catalog = Catalog

Catalog.VERSION = 1
Catalog.OWNER = "ProjectHoomans"

local function registerConcept(id, aliases, priority)
    return Registry.RegisterConcept({
        id = id,
        aliases = aliases,
        priority = priority or 0,
        owner = Catalog.OWNER,
    })
end

local function registerPattern(id, match, emit, confidence, priority, options)
    local definition = {
        id = id,
        match = match,
        emit = emit,
        confidence = confidence,
        priority = priority or 0,
        owner = Catalog.OWNER,
    }
    for key, value in pairs(type(options) == "table" and options or {}) do
        definition[key] = value
    end
    return Registry.RegisterPattern(definition)
end

local function registerSpeechAct(id)
    return Registry.RegisterSpeechAct({
        id = id,
        owner = Catalog.OWNER,
    })
end

function Catalog.Register()
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
    registerConcept("CAMPFIRE", {
        "campfire", "fire pit", "firepit",
    })
    registerConcept("GO", { "go", "head", "travel" })
    registerConcept("HOME", { "home" })
    registerConcept("FETCH", { "bring", "get", "fetch", "grab" })
    registerConcept("GIVE", { "give", "hand", "pass" })
    registerConcept("HAVE", { "have", "got", "carry", "carrying" })
    registerConcept("HEAR", { "hear", "heard" })
    registerConcept("BITTEN", { "bitten", "got bitten", "was bitten" })
    registerConcept("WATER", {
        "water", "drinking water", "something to drink",
    })
    registerConcept("FOOD", {
        "food", "something to eat", "meal", "rations",
    })
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

    registerPattern(
        "pnc.command.follow",
        { "@FOLLOW" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "FOLLOW" },
        0.96,
        100
    )
    registerPattern(
        "pnc.command.stop",
        { "@STOP" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STOP" },
        0.96,
        100
    )
    registerPattern(
        "pnc.command.wait",
        { "@WAIT" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STAY" },
        0.96,
        100
    )
    registerPattern(
        "pnc.command.wait_at",
        {
            { kind = "concept", id = "WAIT" },
            { kind = "literal", value = "at" },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "please", "now" },
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "WAIT_AT",
            target = "$capture.target",
        },
        0.94,
        130
    )
    registerPattern(
        "pnc.question.inventory_have",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "still", optional = true },
            { kind = "concept", id = "HAVE" },
            { kind = "literal", value = "any", optional = true },
            { kind = "literal", value = "kind", optional = true },
            { kind = "literal", value = "of", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            {
                kind = "any_phrase",
                capture = "itemQuery",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "yet", "please", "now" },
            },
            { kind = "literal", value = "yet", optional = true },
            { kind = "literal", value = "please", optional = true },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "INVENTORY",
            inventoryQuery = {
                mode = "LIST",
                item = "$capture.itemQuery",
                text = "$capture.itemQuery.text",
                concept = "$capture.itemQuery.concept",
                category = "$capture.itemQuery.category",
            },
        },
        0.92,
        115,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.question.inventory_what_have",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "kind", optional = true },
            { kind = "literal", value = "of", optional = true },
            {
                kind = "any_phrase",
                capture = "itemQuery",
                minTokens = 1,
                maxTokens = 4,
                stopWords = {
                    "do", "you", "still", "have", "please", "now",
                },
            },
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "still", optional = true },
            { kind = "concept", id = "HAVE" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "INVENTORY",
            inventoryQuery = {
                mode = "LIST",
                item = "$capture.itemQuery",
                text = "$capture.itemQuery.text",
                concept = "$capture.itemQuery.concept",
                category = "$capture.itemQuery.category",
            },
        },
        0.92,
        116,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.command.go_home",
        {
            { kind = "concept", id = "GO" },
            { kind = "concept", id = "HOME", capture = "destination" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "GO",
            destination = "$capture.destination",
        },
        0.96,
        110
    )
    registerPattern(
        "pnc.command.go",
        { "@GO" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "GO" },
        0.88,
        90
    )
    registerPattern(
        "pnc.request.fetch",
        {
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "could", optional = true },
            { kind = "literal", value = "would", optional = true },
            { kind = "literal", value = "you", optional = true },
            { kind = "literal", value = "please", optional = true },
            { kind = "concept", id = "FETCH" },
            { kind = "literal", value = "me", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "any", capture = "object" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "FETCH",
            object = {
                category = "$capture.object.category",
                concept = "$capture.object.concept",
                text = "$capture.object.text",
                value = "$capture.object.value",
                unresolved = "$capture.object.unresolved",
                reference = "$capture.object.reference",
                quantity = "SOME",
            },
        },
        0.94,
        100,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.request.give",
        {
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "could", optional = true },
            { kind = "literal", value = "would", optional = true },
            { kind = "literal", value = "you", optional = true },
            { kind = "literal", value = "please", optional = true },
            { kind = "concept", id = "GIVE" },
            { kind = "literal", value = "me", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "any", capture = "object" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "GIVE",
            object = {
                category = "$capture.object.category",
                concept = "$capture.object.concept",
                text = "$capture.object.text",
                value = "$capture.object.value",
                unresolved = "$capture.object.unresolved",
                reference = "$capture.object.reference",
                quantity = "SOME",
            },
        },
        0.94,
        110,
        { allowFuzzyCapture = true }
    )
    registerPattern(
        "pnc.request.fetch_to",
        {
            { kind = "concept", id = "FETCH" },
            { kind = "literal", value = "me", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "any", capture = "object" },
            { kind = "literal", value = "to" },
            { kind = "any", capture = "target" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "FETCH",
            object = "$capture.object",
            target = "$capture.target",
        },
        0.91,
        105
    )
    registerPattern(
        "pnc.request.help",
        {
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "you", optional = true },
            { kind = "concept", id = "HELP" },
            { kind = "literal", value = "me", optional = true },
            { kind = "any", capture = "target", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "HELP",
            target = "$capture.target",
        },
        0.90,
        90
    )
    registerPattern(
        "pnc.command.negated_go",
        {
            { kind = "literal", value = "don't" },
            { kind = "concept", id = "GO" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "GO",
            modifiers = { negated = true },
        },
        0.95,
        120
    )
    registerPattern(
        "pnc.command.negated_take",
        {
            { kind = "literal", value = "don't" },
            { kind = "concept", id = "TAKE" },
            { kind = "any", capture = "object", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "TAKE",
            modifiers = { negated = true },
            object = "$capture.object",
        },
        0.90,
        120
    )
    registerPattern(
        "pnc.command.take",
        {
            { kind = "concept", id = "TAKE" },
            { kind = "any", capture = "object" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "TAKE",
            object = "$capture.object",
        },
        0.90,
        100
    )
    registerPattern(
        "pnc.question.where",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "is" },
            { kind = "any", capture = "target" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "LOCATION",
            target = "$capture.target",
        },
        0.90,
        80
    )
    registerPattern(
        "pnc.question.seen",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "see" },
            { kind = "any", capture = "target" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "SEEN",
            target = "$capture.target",
        },
        0.88,
        80
    )
    registerPattern(
        "pnc.social.gossip_event",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "concept", id = "HEAR" },
            { kind = "literal", value = "that", optional = true },
            { kind = "any", capture = "target" },
            { kind = "concept", id = "BITTEN" },
        },
        {
            intent = "GOSSIP",
            speechAct = "GOSSIP",
            subject = "GOSSIP",
            target = "$capture.target",
            slots = {
                information = {
                    event = "BITTEN",
                    subject = "$capture.target",
                },
            },
        },
        0.88,
        90
    )
    registerPattern(
        "pnc.social.thank",
        { "@THANK" },
        { intent = "THANK", speechAct = "THANK" },
        0.96,
        70
    )
    registerPattern(
        "pnc.social.apologize",
        { "@APOLOGIZE" },
        { intent = "APOLOGIZE", speechAct = "APOLOGIZE" },
        0.96,
        70
    )
    registerPattern(
        "pnc.social.accept",
        { "@ACCEPT" },
        { intent = "ACCEPT", speechAct = "ACCEPT" },
        0.94,
        70
    )
    registerPattern(
        "pnc.social.refuse",
        { "@REFUSE" },
        { intent = "REFUSE", speechAct = "REFUSE" },
        0.94,
        70
    )
    registerPattern(
        "pnc.social.greet",
        { "@GREET" },
        { intent = "GREET", speechAct = "GREET" },
        0.97,
        75
    )
    registerPattern(
        "pnc.question.time",
        { "@TIME" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "TIME",
        },
        0.96,
        85
    )
    registerPattern(
        "pnc.question.day",
        { "@DAY" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "DATE",
        },
        0.96,
        90
    )
    registerPattern(
        "pnc.question.weather",
        { "@WEATHER" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WEATHER",
        },
        0.96,
        85
    )
    registerPattern(
        "pnc.question.identity",
        { "@IDENTITY" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "IDENTITY",
        },
        0.96,
        85
    )
    registerPattern(
        "pnc.question.activity",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "doing" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.96,
        86
    )
    registerPattern(
        "pnc.question.activity_up_to",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "up" },
            { kind = "literal", value = "to" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.94,
        85
    )
    registerPattern(
        "pnc.question.activity_busy",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "busy" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "ACTIVITY",
        },
        0.94,
        85
    )
    registerPattern(
        "pnc.question.wellbeing_okay",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "okay" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.96,
        87
    )
    registerPattern(
        "pnc.question.wellbeing_alright",
        {
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "alright" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.96,
        87
    )
    registerPattern(
        "pnc.question.wellbeing_how",
        {
            { kind = "literal", value = "how" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "you" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "WELLBEING",
        },
        0.92,
        84
    )

    Catalog.registered = true
    Catalog.registryRevision = Registry.GetRevision()
    return true, Catalog.registryRevision
end

Catalog.Register()

-- Keep socially charged language in its own data module.  The base catalog
-- remains the stable vocabulary hub, while this explicit dependency ensures
-- every normal shared semantic load sees the same social patterns.
require "PNC/Semantics/PNC_SemanticSocialCatalog"

return Catalog
