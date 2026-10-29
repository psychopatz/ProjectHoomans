local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)

local default = Catalog.Select(
    "semantic.greeting",
    { npcID = "mara", worldContext = {} },
    "default"
)
T.equal(default.templateID, "semantic.greet.acknowledged",
    "response catalog exposes the stable greeting template id")
T.equal(default.fallback, "Hey there.",
    "response catalog uses the safe default greeting")

local friendly = Catalog.Select(
    "semantic.greeting",
    {
        npcID = "mara",
        dialogueSituation = { social = { style = "friendly" } },
    },
    "friendly"
)
T.equal(friendly.templateID, "semantic.greet.friendly",
    "response pools can branch on projected NPC social style")

local dawn = Catalog.Select(
    "semantic.greeting",
    {
        npcID = "mara",
        worldContext = { timeBand = "dawn" },
    },
    "dawn"
)
T.equal(dawn.templateID, "semantic.greet.morning",
    "response conditions can use the cached world time band")

local registered = Catalog.Register("test.topic_pool", {
    variants = {
        {
            id = "test.topic.default",
            fallback = "I hear you.",
        },
        {
            id = "test.topic.weather",
            fallback = "The weather is turning.",
            when = { topic = "weather" },
            priority = 1,
        },
    },
})
T.equal(registered, true,
    "domain modules can register a bounded response pool")

local weather = Catalog.Select(
    "test.topic_pool",
    { npcID = "mara", currentTopic = "weather" },
    "weather"
)
T.equal(weather.id, "test.topic.weather",
    "the most specific matching response variant wins")

local unrelated = Catalog.Select(
    "test.topic_pool",
    { npcID = "mara", currentTopic = "resources" },
    "resources"
)
T.equal(unrelated.id, "test.topic.default",
    "unmatched conditions fall back to the default variant")

local navigation = Catalog.Select(
    "semantic.conversation.acknowledged",
    { npcID = "mara", subject = "CONVERSATION_TOPIC" },
    "navigation"
)
T.equal(navigation.templateID, "semantic.navigation.subject_change",
    "semantic navigation uses its dedicated subject-change response")
T.equal(navigation.fallback,
    "All right. What did you want to talk about?",
    "semantic navigation keeps a player-facing acknowledgement")

Catalog.ResetSelections()
local whatsUp = Catalog.Select(
    "semantic.question.whats_up",
    {
        npcID = "mara",
        subject = "CONVERSATION_TOPIC",
        worldContext = {},
    },
    "whats_up"
)
T.truthy(whatsUp,
    "what's up resolves through a dedicated semantic response pool")
T.truthy(
    whatsUp.id == "semantic.question.whats_up.default"
        or whatsUp.id == "semantic.question.whats_up.default_alt",
    "what's up uses a bounded conversational variant")
T.falsy(whatsUp.fallback == "Let me think about that.",
    "what's up does not use the generic question fallback")

local rainyWhatsUp = Catalog.Select(
    "semantic.question.whats_up",
    {
        npcID = "mara",
        subject = "CONVERSATION_TOPIC",
        worldContext = { weather = { raining = true } },
    },
    "rainy_whats_up"
)
T.equal(rainyWhatsUp.id, "semantic.question.whats_up.weather",
    "what's up can use current weather as grounded context")

local assaulted = Catalog.Select(
    "semantic.player_assaulted_npc",
    { npcID = "mara", combatReactionStyle = "aggressive" },
    "player_assaulted"
)
T.equal(assaulted.templateID, "semantic.combat.player_assaulted.aggressive",
    "player assault reaction selects the aggression-aware semantic family")
T.equal(assaulted.fallback, "You just made a big mistake.",
    "player assault reaction has an appropriate hostile-transition fallback")

T.falsy(Catalog.Select("missing_pool", {}, "missing"),
    "missing pools fail safely")

T.finish("pnc_semantic_response_catalog_smoke")
